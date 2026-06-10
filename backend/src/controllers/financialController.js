// ===== backend/src/controllers/financialController.js =====
import {
  FinancialTransaction,
  Transaction,
  Wallet,
  Contract,
  User,
  Project
} from "../models/index.js";
import { Op, Sequelize } from "sequelize";
import { sequelize } from "../config/db.js";

export const getFinancialStats = async (req, res) => {
  try {
    const userId = req.user.id;
    const userRole = req.user.role;
    const { period = "monthly", startDate, endDate } = req.query;

    let dateFilter = {};
    if (startDate && endDate) {
      dateFilter = {
        transaction_date: {
          [Op.between]: [new Date(startDate), new Date(endDate)],
        },
      };
    }

    const earnings = await Transaction.sum("amount", {
      where: {
        user_id: userId,
        user_role: userRole,
        type: userRole === "freelancer" ? "payment" : "payment_sent",
        status: "completed",
        ...dateFilter,
      },
    });

    const fees = await Transaction.sum("amount", {
      where: {
        user_id: userId,
        type: "fee",
        status: "completed",
        ...dateFilter,
      },
    });

    const withdrawals = await Transaction.sum("amount", {
      where: {
        user_id: userId,
        type: "withdraw",
        status: "completed",
        ...dateFilter,
      },
    });

    let periodStats = [];

    if (period === "monthly") {
      const monthlyStats = await Transaction.findAll({
        attributes: [
          [
            Sequelize.fn(
              "DATE_FORMAT",
              Sequelize.col("transaction_date"),
              "%Y-%m",
            ),
            "period",
          ],
          [Sequelize.fn("SUM", Sequelize.col("amount")), "total"],
        ],
        where: {
          user_id: userId,
          status: "completed",
          type: userRole === "freelancer" ? "payment" : "payment_sent",
          ...dateFilter,
        },
        group: [
          Sequelize.fn(
            "DATE_FORMAT",
            Sequelize.col("transaction_date"),
            "%Y-%m",
          ),
        ],
        order: [
          [
            Sequelize.fn(
              "DATE_FORMAT",
              Sequelize.col("transaction_date"),
              "%Y-%m",
            ),
            "ASC",
          ],
        ],
        raw: true,
      });
      periodStats = monthlyStats;
    } else if (period === "weekly") {
      const weeklyStats = await Transaction.findAll({
        attributes: [
          [
            Sequelize.fn(
              "DATE_FORMAT",
              Sequelize.col("transaction_date"),
              "%Y-%u",
            ),
            "period",
          ],
          [Sequelize.fn("SUM", Sequelize.col("amount")), "total"],
        ],
        where: {
          user_id: userId,
          status: "completed",
          type: userRole === "freelancer" ? "payment" : "payment_sent",
          ...dateFilter,
        },
        group: [
          Sequelize.fn(
            "DATE_FORMAT",
            Sequelize.col("transaction_date"),
            "%Y-%u",
          ),
        ],
        raw: true,
      });
      periodStats = weeklyStats;
    }

    const recentTransactions = await Transaction.findAll({
      where: {
        user_id: userId,
        status: "completed",
      },
      order: [["transaction_date", "DESC"]],
      limit: 10,
    });

    res.json({
      success: true,
      stats: {
        totalEarnings: earnings || 0,
        totalFees: fees || 0,
        totalWithdrawals: withdrawals || 0,
        netEarnings: (earnings || 0) - (fees || 0) - (withdrawals|| 0),
      },
      periodStats: periodStats,  
      recentTransactions: recentTransactions,
    });
  } catch (error) {
    console.error("Error getting financial stats:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const generateFinancialReport = async (req, res) => {
  try {
    const userId = req.user.id;
    const { startDate, endDate, format = "pdf" } = req.query;

    const transactions = await Transaction.findAll({
      where: {
        user_id: userId,
        transaction_date: {
          [Op.between]: [new Date(startDate), new Date(endDate)],
        },
        status: "completed",
      },
      order: [["transaction_date", "ASC"]],
    });

    const summary = {
      totalIncome: transactions
        .filter((t) => t.type === "payment" || t.type === "deposit")
        .reduce((sum, t) => sum + parseFloat(t.amount), 0),
      totalExpenses: transactions
        .filter((t) => t.type === "payment_sent" || t.type === "withdrawal")
        .reduce((sum, t) => sum + parseFloat(t.amount), 0),
      totalFees: transactions
        .filter((t) => t.type === "fee")
        .reduce((sum, t) => sum + parseFloat(t.amount), 0),
    };
    summary.netIncome =
      summary.totalIncome - summary.totalExpenses - summary.totalFees;

    // TODO: إنشاء PDF حقيقي باستخدام مكتبة مثل pdfkit
    const reportData = {
      userId,
      period: { startDate, endDate },
      summary,
      transactions,
      generatedAt: new Date(),
    };

    res.json({
      success: true,
      report: reportData,
      downloadUrl: `/reports/financial_${userId}_${Date.now()}.pdf`,
    });
  } catch (error) {
    console.error("Error generating financial report:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const requestWithdrawalV2 = async (req, res) => {
  try {
    const { amount, method, accountDetails } = req.body;
    const userId = req.user.id;

    const wallet = await Wallet.findOne({ where: { UserId: userId } });
    if (!wallet || wallet.balance < amount) {
      return res
        .status(400)
        .json({ success: false, message: "Insufficient balance" });
    }

    const transaction = await Transaction.create({
      user_id: userId,
      user_role: req.user.role,
      amount: -amount,
      type: "withdraw",
      status: "pending",
      description: `Withdrawal request via ${method}`,
      metadata: {
        method,
        accountDetails: accountDetails ? JSON.parse(accountDetails) : null,
        requested_at: new Date(),
      },
    });

    await wallet.update({
      pending_balance: (wallet.pending_balance || 0) + amount,
      balance: wallet.balance - amount,
    });

    // TODO: معالجة السحب حسب الطريقة (PayPal, Stripe, Bank Transfer)

    res.json({
      success: true,
      message: "Withdrawal request submitted successfully",
      transaction,
    });
  } catch (error) {
    console.error("Error requesting withdrawal:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const getAdvancedFinancialAnalytics = async (req, res) => {
  try {
    const userId = req.user.id;
    const userRole = req.user.role;

    console.log('📊 Analytics - UserId:', userId, 'Role:', userRole);

    const topProjects = await Contract.findAll({
      where: userRole === "freelancer"
        ? { FreelancerId: userId, status: "completed" }
        : { ClientId: userId, status: "completed" },
      attributes: ["id", "agreed_amount", "createdAt"],
      include: [{ model: Project, attributes: ["title", "category"] }],
      order: [["agreed_amount", "DESC"]],
      limit: 5,
    });

    console.log('📊 Top projects found:', topProjects.length);
    if (topProjects.length > 0) {
      console.log('📊 First project:', topProjects[0].toJSON());
    }

    const categoryDistribution = await sequelize.query(
      `
      SELECT 
        p.category,
        SUM(c.agreed_amount) as total
      FROM Contracts c
      JOIN Projects p ON c.ProjectId = p.id
      WHERE c.${userRole === "freelancer" ? "FreelancerId" : "ClientId"} = ${userId}
        AND c.status = 'completed'
      GROUP BY p.category
      ORDER BY total DESC
    `,
      { type: sequelize.QueryTypes.SELECT },
    );

    const monthlyAverage = await Transaction.findAll({
      attributes: [
        [
          Sequelize.fn(
            "DATE_FORMAT",
            Sequelize.col("transaction_date"),
            "%Y-%m",
          ),
          "month",
        ],
        [Sequelize.fn("AVG", Sequelize.col("amount")), "average"],
      ],
      where: {
        user_id: userId,
        status: "completed",
        type: userRole === "freelancer" ? "payment" : "payment_sent",
      },
      group: [
        Sequelize.fn("DATE_FORMAT", Sequelize.col("transaction_date"), "%Y-%m"),
      ],
      raw: true,
    });

    res.json({
      success: true,
      analytics: {
        topProjects,
        categoryDistribution,
        monthlyAverage,
        projectedEarnings: await calculateProjectedEarnings(userId, userRole),
      },
    });
  } catch (error) {
    console.error("Error getting advanced analytics:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

async function calculateProjectedEarnings(userId, userRole) {
  const threeMonthsAgo = new Date();
  threeMonthsAgo.setMonth(threeMonthsAgo.getMonth() - 3);

  const transactions = await Transaction.findAll({
    where: {
      user_id: userId,
      transaction_date: { [Op.gte]: threeMonthsAgo },
      status: "completed",
      type: userRole === "freelancer" ? "payment" : "payment",
    },
    attributes: ["amount"],
  });

  if (transactions.length === 0) return 0;

  const average =
    transactions.reduce((sum, t) => sum + parseFloat(t.amount), 0) /
    transactions.length;
  return average * 3;
}
