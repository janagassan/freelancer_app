// controllers/adminController.js
import bcrypt from "bcrypt";
import {
  User,
  Project,
  Contract,
  FreelancerProfile,
  ClientProfile,
  Rating,
  Transaction,
  Wallet,
  Dispute,
  sequelize,
} from "../models/index.js";
import { Op } from "sequelize";
import AdCampaign from "../models/AdCampaign.js";
import AdPaymentService from "../services/adPaymentService.js";
import {
  sendDisputeResolvedEmail,
  sendAccountCreatedEmail,
} from "../utils/mailer.js";

const generateRandomPassword = (length = 12) => {
  const chars =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()-_";
  return Array.from(
    { length },
    () => chars[Math.floor(Math.random() * chars.length)],
  ).join("");
};

export const getDashboardStats = async (req, res) => {
  try {
    console.log("📊 Fetching admin dashboard stats...");
    const adRevenueStats = await AdPaymentService.getAdminStats();

    const [
      totalUsers,
      totalFreelancers,
      totalClients,
      totalProjects,
      totalContracts,
      totalEarnings,
      pendingProjects,
      activeContracts,
      completedContracts,
      pendingDisputes,
    ] = await Promise.all([
      User.count(),
      User.count({ where: { role: "freelancer" } }),
      User.count({ where: { role: "client" } }),
      Project.count(),
      Contract.count(),
      Transaction.sum("amount", {
        where: { type: "platform_fee", status: "completed" },
      }),
      Project.count({ where: { status: "pending_review" } }),
      Contract.count({ where: { status: "active" } }),
      Contract.count({ where: { status: "completed" } }),
      Contract.count({ where: { status: "disputed" } }),
    ]);

    const recentUsers = await User.findAll({
      where: {
        createdAt: {
          [Op.gte]: new Date(new Date() - 7 * 24 * 60 * 60 * 1000),
        },
      },
      attributes: [
        "id",
        "name",
        "email",
        "role",
        "avatar",
        "createdAt",
        "account_status",
      ],
      order: [["createdAt", "DESC"]],
      limit: 10,
    });

    const recentProjects = await Project.findAll({
      include: [
        {
          model: User,
          as: "client",
          attributes: ["id", "name", "avatar"],
        },
      ],
      order: [["createdAt", "DESC"]],
      limit: 10,
    });

    const monthlyStats = await sequelize.query(`
      SELECT 
        DATE_FORMAT(createdAt, '%Y-%m') as month,
        COUNT(*) as users,
        SUM(CASE WHEN role = 'freelancer' THEN 1 ELSE 0 END) as freelancers,
        SUM(CASE WHEN role = 'client' THEN 1 ELSE 0 END) as clients
      FROM Users
      WHERE createdAt >= DATE_SUB(NOW(), INTERVAL 6 MONTH)
      GROUP BY DATE_FORMAT(createdAt, '%Y-%m')
      ORDER BY month ASC
    `);

    res.json({
      success: true,
      stats: {
        totalUsers,
        totalFreelancers,
        totalClients,
        totalProjects,
        totalContracts,
        totalEarnings: totalEarnings || 0,
        pendingProjects,
        activeContracts,
        completedContracts,
        pendingDisputes,
        adRevenue: adRevenueStats.total_ad_revenue || 0,
        activeAdCampaigns: adRevenueStats.active_campaigns || 0,
        totalAdSpend: adRevenueStats.total_campaign_spend || 0,
      },
      recentUsers: recentUsers.map((user) => ({
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        avatar: user.avatar,
        createdAt: user.createdAt,
        accountStatus: user.account_status,
      })),
      recentProjects,
      monthlyStats: monthlyStats[0] || [],
    });

    console.log("✅ Dashboard stats fetched successfully");
  } catch (err) {
    console.error("❌ Error in getDashboardStats:", err);
    res.json({
      success: false,
      stats: {
        totalUsers: 0,
        totalFreelancers: 0,
        totalClients: 0,
        totalProjects: 0,
        totalContracts: 0,
        totalEarnings: 0,
        pendingProjects: 0,
        activeContracts: 0,
        completedContracts: 0,
        pendingDisputes: 0,
      },
      monthlyStats: [],
      recentUsers: [],
      recentProjects: [],
    });
  }
};

export const getUserStats = async (req, res) => {
  try {
    const totalUsers = await User.count();
    const activeUsers = await User.count({
      where: { account_status: "active" },
    });
    const freelancersCount = await User.count({
      where: { role: "freelancer" },
    });
    const suspendedCount = await User.count({
      where: { account_status: "suspended" },
    });

    res.json({
      success: true,
      totalUsers,
      activeUsers,
      freelancersCount,
      suspendedCount,
    });
  } catch (err) {
    console.error("❌ Error in getUserStats:", err);
    res.status(500).json({
      success: false,
      totalUsers: 0,
      activeUsers: 0,
      freelancersCount: 0,
      suspendedCount: 0,
    });
  }
};

export const getAllUsers = async (req, res) => {
  try {
    const { role, status, search, page = 1, limit = 20 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    console.log("📥 getAllUsers called with:", {
      role,
      status,
      search,
      page,
      limit,
    });

    const where = {};
    if (role && role !== "all") where.role = role;
    if (status && status !== "all") where.account_status = status;
    if (search) {
      where[Op.or] = [
        { name: { [Op.like]: `%${search}%` } },
        { email: { [Op.like]: `%${search}%` } },
      ];
    }

    const { count, rows } = await User.findAndCountAll({
      where,
      attributes: {
        exclude: ["password", "verification_code", "reset_password_token"],
      },
      include: [
        {
          model: FreelancerProfile,
          required: false,
          attributes: ["rating", "completed_projects_count", "total_earnings"],
        },
        {
          model: ClientProfile,
          required: false,
          attributes: ["company_name", "payment_verified"],
        },
      ],
      order: [["createdAt", "DESC"]],
      limit: parseInt(limit),
      offset,
    });

    console.log("📊 Users found:", count);

    const activeUsers = await User.count({
      where: { account_status: "active" },
    });

    const freelancersCount = await User.count({
      where: { role: "freelancer" },
    });

    const suspendedCount = await User.count({
      where: { account_status: "suspended" },
    });

    console.log("📈 Stats:", {
      totalUsers: count,
      activeUsers,
      freelancersCount,
      suspendedCount,
    });

    const responseData = {
      success: true,
      users: rows,
      totalUsers: count,
      activeUsers: activeUsers,
      freelancersCount: freelancersCount,
      suspendedCount: suspendedCount,
      page: parseInt(page),
      totalPages: Math.ceil(count / parseInt(limit)),
    };

    console.log("📤 Response keys:", Object.keys(responseData));

    res.json(responseData);
  } catch (err) {
    console.error("❌ Error in getAllUsers:", err);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: err.message,
      users: [],
      totalUsers: 0,
      activeUsers: 0,
      freelancersCount: 0,
      suspendedCount: 0,
      totalPages: 0,
    });
  }
};

export const createUser = async (req, res) => {
  try {
    const {
      name,
      email,
      role,
      phone,
      national_id,
      hourly_rate,
      skills,
      client_type,
      company_name,
      commercial_register_number,
      tax_number,
    } = req.body;

    if (!name || !email || !role) {
      return res.status(400).json({
        success: false,
        message: "Name, email, and role are required",
      });
    }

    const validRoles = ["client", "freelancer", "admin"];
    if (!validRoles.includes(role)) {
      return res.status(400).json({
        success: false,
        message: "Invalid role",
      });
    }

    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: "A user with this email already exists",
      });
    }

    const initialPassword = generateRandomPassword(12);
    const hashedPassword = await bcrypt.hash(initialPassword, 10);

    const newUser = await User.create({
      name,
      email,
      password: hashedPassword,
      role,
      is_verified: true,
      account_status: "active",
      agreed_to_terms_at: new Date(),
      terms_accepted_version: "1.0",
      phone: phone || null,
      national_id: national_id || null,
    });

    if (role === "freelancer") {
      let profileData = {
        UserId: newUser.id,
        hourly_rate: hourly_rate ? parseFloat(hourly_rate) : null,
      };

      if (skills) {
        try {
          const skillsArray =
            typeof skills === "string" ? JSON.parse(skills) : skills;
          if (skillsArray.length > 0) {
            profileData.skills = JSON.stringify(skillsArray);
          }
        } catch (e) {
          console.error("Invalid skills format:", e);
        }
      }

      await FreelancerProfile.create(profileData);
    } else if (role === "client") {
      await ClientProfile.create({
        UserId: newUser.id,
        company_name: company_name || null,
        client_type: client_type || "individual",
        commercial_register_number: commercial_register_number || null,
        tax_number: tax_number || null,
      });
    }

    await Wallet.create({ UserId: newUser.id, balance: 0 });

    try {
      await sendAccountCreatedEmail(email, role, initialPassword);
    } catch (emailError) {
      console.error("⚠️ Account created but failed to send email:", emailError);
    }

    res.status(201).json({
      success: true,
      message: "User created successfully",
      user: {
        id: newUser.id,
        name: newUser.name,
        email: newUser.email,
        role: newUser.role,
      },
    });
  } catch (err) {
    console.error("❌ Error in createUser:", err);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: err.message,
    });
  }
};

export const resendAccountEmail = async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await User.findByPk(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    const newPassword = generateRandomPassword(12);
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    await user.update({ password: hashedPassword });

    try {
      await sendAccountCreatedEmail(user.email, user.role, newPassword);
      res.json({
        success: true,
        message: "Account email resent successfully",
      });
    } catch (emailError) {
      console.error("Failed to resend email:", emailError);
      res.status(500).json({
        success: false,
        message: "Failed to send email",
      });
    }
  } catch (err) {
    console.error("❌ Error in resendAccountEmail:", err);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: err.message,
    });
  }
};

export const getUserDetails = async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await User.findByPk(userId, {
      attributes: { exclude: ["password", "verification_code"] },
      include: [
        {
          model: FreelancerProfile,
          required: false,
        },
        {
          model: ClientProfile,
          required: false,
        },
      ],
    });

    if (!user) {
      return res
        .status(404)
        .json({ success: false, message: "User not found" });
    }

    const projects = await Project.count({ where: { UserId: userId } });
    const contracts = await Contract.count({
      where: {
        [Op.or]: [{ FreelancerId: userId }, { ClientId: userId }],
      },
    });
    const ratings = await Rating.findAll({
      where: { toUserId: userId },
      attributes: ["rating"],
    });

    const avgRating =
      ratings.length > 0
        ? ratings.reduce((sum, r) => sum + r.rating, 0) / ratings.length
        : 0;

    res.json({
      success: true,
      user,
      stats: {
        projects,
        contracts,
        avgRating,
        totalRatings: ratings.length,
      },
    });
  } catch (err) {
    console.error("❌ Error in getUserDetails:", err);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: err.message });
  }
};

export const updateUserStatus = async (req, res) => {
  try {
    const { userId } = req.params;
    const { status, reason } = req.body;

    const user = await User.findByPk(userId);
    if (!user) {
      return res
        .status(404)
        .json({ success: false, message: "User not found" });
    }

    await user.update({ account_status: status });

    console.log(`✅ User ${userId} status updated to ${status}`);

    res.json({
      success: true,
      message: `User status updated to ${status}`,
    });
  } catch (err) {
    console.error("❌ Error in updateUserStatus:", err);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: err.message });
  }
};

export const verifyUser = async (req, res) => {
  try {
    const { userId } = req.params;
    const { verified } = req.body;

    const user = await User.findByPk(userId);
    if (!user) {
      return res
        .status(404)
        .json({ success: false, message: "User not found" });
    }

    await user.update({ is_verified: verified });

    if (user.role === "freelancer") {
      await FreelancerProfile.update(
        { is_verified: verified },
        { where: { UserId: userId } },
      );
    } else if (user.role === "client") {
      await ClientProfile.update(
        { id_verified: verified },
        { where: { UserId: userId } },
      );
    }

    console.log(`✅ User ${userId} verification set to ${verified}`);

    res.json({
      success: true,
      message: verified ? "User verified" : "User verification removed",
    });
  } catch (err) {
    console.error("❌ Error in verifyUser:", err);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: err.message });
  }
};

export const getAllProjects = async (req, res) => {
  try {
    const {
      status,
      category,
      search,
      page = 1,
      limit = 20,
      startDate,
      endDate,
      budgetRange,
    } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    const where = {};
    if (status && status !== "all") where.status = status;
    if (category && category !== "all") where.category = category;
    if (search) {
      where[Op.or] = [
        { title: { [Op.like]: `%${search}%` } },
        { description: { [Op.like]: `%${search}%` } },
      ];
    }

    if (startDate || endDate) {
      where.createdAt = {};
      if (startDate) {
        where.createdAt[Op.gte] = new Date(startDate);
      }
      if (endDate) {
        where.createdAt[Op.lte] = new Date(endDate);
      }
    }

    if (budgetRange && budgetRange !== "all") {
      if (budgetRange === "5000+") {
        where.budget = { [Op.gte]: 5000 };
      } else {
        const [min, max] = budgetRange.split("-").map(Number);
        where.budget = { [Op.between]: [min, max] };
      }
    }

    const { count, rows } = await Project.findAndCountAll({
      where,
      include: [
        {
          model: User,
          as: "client",
          attributes: ["id", "name", "avatar", "email"],
        },
      ],
      order: [["createdAt", "DESC"]],
      limit: parseInt(limit),
      offset,
    });

    res.json({
      success: true,
      projects: rows,
      total: count,
      page: parseInt(page),
      totalPages: Math.ceil(count / parseInt(limit)),
    });
  } catch (err) {
    console.error("❌ Error in getAllProjects:", err);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: err.message });
  }
};

export const deleteProject = async (req, res) => {
  try {
    const { projectId } = req.params;

    const project = await Project.findByPk(projectId);
    if (!project) {
      return res
        .status(404)
        .json({ success: false, message: "Project not found" });
    }

    await project.destroy();

    console.log(`✅ Project ${projectId} deleted by admin`);

    res.json({
      success: true,
      message: "Project deleted successfully",
    });
  } catch (err) {
    console.error("❌ Error in deleteProject:", err);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: err.message });
  }
};

export const getAllContracts = async (req, res) => {
  try {
    const {
      status,
      search,
      page = 1,
      limit = 20,
      startDate,
      endDate,
    } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    const where = {};
    if (status && status !== "all") where.status = status;
    if (search) {
      where[Op.or] = [
        { "$Project.title$": { [Op.like]: `%${search}%` } },
        { "$Client.name$": { [Op.like]: `%${search}%` } },
        { "$Freelancer.name$": { [Op.like]: `%${search}%` } },
      ];
    }

    if (startDate || endDate) {
      where.createdAt = {};
      if (startDate) {
        where.createdAt[Op.gte] = new Date(startDate);
      }
      if (endDate) {
        where.createdAt[Op.lte] = new Date(endDate);
      }
    }

    const { count, rows } = await Contract.findAndCountAll({
      where,
      include: [
        {
          model: Project,
          attributes: ["id", "title", "budget"],
        },
        {
          model: User,
          as: "client",
          attributes: ["id", "name", "avatar"],
        },
        {
          model: User,
          as: "freelancer",
          attributes: ["id", "name", "avatar"],
        },
      ],
      order: [["createdAt", "DESC"]],
      limit: parseInt(limit),
      offset,
    });

    res.json({
      success: true,
      contracts: rows,
      total: count,
      page: parseInt(page),
      totalPages: Math.ceil(count / parseInt(limit)),
    });
  } catch (err) {
    console.error("❌ Error in getAllContracts:", err);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: err.message });
  }
};

export const resolveDispute = async (req, res) => {
  try {
    const { contractId } = req.params;
    const { resolution, refundTo, amount } = req.body;

    const contract = await Contract.findByPk(contractId);
    if (!contract) {
      return res
        .status(404)
        .json({ success: false, message: "Contract not found" });
    }

    await contract.update({
      status: "resolved",
      dispute_resolution: resolution,
      dispute_resolved_at: new Date(),
    });

    console.log(`✅ Dispute resolved for contract ${contractId}`);

    res.json({
      success: true,
      message: "Dispute resolved successfully",
    });
  } catch (err) {
    console.error("❌ Error in resolveDispute:", err);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: err.message });
  }
};

export const getAllDisputes = async (req, res) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    const where = {};
    if (status && status !== "all") where.status = status;

    const { rows: disputes, count } = await Dispute.findAndCountAll({
      where,
      include: [
        {
          model: Contract,
          include: [
            { model: Project, attributes: ["title"] },
            { model: User, as: "client", attributes: ["name", "email"] },
            { model: User, as: "freelancer", attributes: ["name", "email"] },
          ],
        },
        { model: User, as: "client", attributes: ["name", "email"] },
        { model: User, as: "freelancer", attributes: ["name", "email"] },
      ],
      order: [["createdAt", "DESC"]],
      limit: parseInt(limit),
      offset,
    });

    res.json({
      success: true,
      disputes: disputes,
      total: count,
      page: parseInt(page),
      totalPages: Math.ceil(count / parseInt(limit)),
    });
  } catch (err) {
    console.error("❌ Error in getAllDisputes:", err);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: err.message });
  }
};

export const getDisputeDetails = async (req, res) => {
  try {
    const { disputeId } = req.params;

    const dispute = await Dispute.findByPk(disputeId, {
      include: [
        {
          model: Contract,
          include: [
            { model: Project, attributes: ["title", "description"] },
            { model: User, as: "client", attributes: ["name", "email"] },
            { model: User, as: "freelancer", attributes: ["name", "email"] },
          ],
        },
        { model: User, as: "client", attributes: ["name", "email"] },
        { model: User, as: "freelancer", attributes: ["name", "email"] },
      ],
    });

    if (!dispute) {
      return res
        .status(404)
        .json({ success: false, message: "Dispute not found" });
    }

    res.json({
      success: true,
      dispute,
    });
  } catch (err) {
    console.error("❌ Error in getDisputeDetails:", err);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: err.message });
  }
};

export const resolveDisputeAdmin = async (req, res) => {
  try {
    const { disputeId } = req.params;
    const { resolution, refund_amount, admin_notes } = req.body;

    const dispute = await Dispute.findByPk(disputeId, {
      include: [
        { model: Contract },
        { model: User, as: "client" },
        { model: User, as: "freelancer" },
      ],
    });

    if (!dispute) {
      return res
        .status(404)
        .json({ success: false, message: "Dispute not found" });
    }

    if (dispute.status !== "open") {
      return res
        .status(400)
        .json({ success: false, message: "Dispute is already resolved" });
    }

    await dispute.update({
      status: "resolved",
      resolution,
      refund_amount: refund_amount || null,
      admin_notes,
      decision_date: new Date(),
    });

    if (resolution === "full_refund" || resolution === "partial_refund") {
      const refundAmount =
        resolution === "full_refund"
          ? dispute.Contract.agreed_amount
          : refund_amount;

      const clientWallet = await Wallet.findOne({
        where: { UserId: dispute.ClientId },
      });
      if (clientWallet) {
        await clientWallet.increment("balance", { by: refundAmount });
      }

      const freelancerWallet = await Wallet.findOne({
        where: { UserId: dispute.FreelancerId },
      });
      if (freelancerWallet) {
        await freelancerWallet.decrement("balance", { by: refundAmount });
      }

      await Transaction.create({
        wallet_id: clientWallet.id,
        amount: refundAmount,
        type: "credit",
        description: `Dispute refund for contract #${dispute.ContractId}`,
      });

      await Transaction.create({
        wallet_id: freelancerWallet.id,
        amount: refundAmount,
        type: "debit",
        description: `Dispute refund deduction for contract #${dispute.ContractId}`,
      });
    }

    console.log(`✅ Dispute ${disputeId} resolved with ${resolution}`);

    try {
      const resolutionText =
        resolution === "full_refund"
          ? "Full refund to client"
          : resolution === "partial_refund"
            ? `Partial refund of \$${refund_amount} to client`
            : "No refund";

      await sendDisputeResolvedEmail(
        dispute.client.email,
        dispute,
        resolutionText,
      );
      await sendDisputeResolvedEmail(
        dispute.freelancer.email,
        dispute,
        resolutionText,
      );
    } catch (emailError) {
      console.error(
        "⚠️ Dispute resolved but failed to send emails:",
        emailError,
      );
    }

    res.json({
      success: true,
      message: "Dispute resolved successfully",
    });
  } catch (err) {
    console.error("❌ Error in resolveDisputeAdmin:", err);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: err.message });
  }
};

export const rejectDispute = async (req, res) => {
  try {
    const { disputeId } = req.params;
    const { admin_notes } = req.body;

    const dispute = await Dispute.findByPk(disputeId);

    if (!dispute) {
      return res
        .status(404)
        .json({ success: false, message: "Dispute not found" });
    }

    if (dispute.status !== "open") {
      return res
        .status(400)
        .json({ success: false, message: "Dispute is already resolved" });
    }

    await dispute.update({
      status: "rejected",
      admin_notes,
      decision_date: new Date(),
    });

    console.log(`✅ Dispute ${disputeId} rejected`);

    res.json({
      success: true,
      message: "Dispute rejected successfully",
    });
  } catch (err) {
    console.error("❌ Error in rejectDispute:", err);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: err.message });
  }
};
