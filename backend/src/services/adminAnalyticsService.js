// backend/src/services/adminAnalyticsService.js
import { Op, Sequelize } from "sequelize";
import {
  User,
  Project,
  Contract,
  Transaction,
  Rating,
  Dispute,
  AdCampaign,
} from "../models/index.js";
import AdminInsight from "../models/AdminInsight.js";
import AdminAuditLog from "../models/AdminAuditLog.js";

class AdminAnalyticsService {
  static async getTopPerformers(criteria = "overall", limit = 10) {
    const performers = {};

    switch (criteria) {
      case "freelancers_by_earnings":
        performers.freelancers = await User.findAll({
          where: { role: "freelancer" },
          attributes: [
            "id",
            "name",
            "avatar",
            "email",
            [
              Sequelize.literal(`(
              SELECT COALESCE(SUM(agreed_amount), 0) 
              FROM Contracts 
              WHERE FreelancerId = User.id AND status = 'completed'
            )`),
              "total_earnings",
            ],
            [
              Sequelize.literal(`(
              SELECT COUNT(*) 
              FROM Contracts 
              WHERE FreelancerId = User.id AND status = 'completed'
            )`),
              "completed_projects",
            ],
          ],
          order: [[Sequelize.literal("total_earnings"), "DESC"]],
          limit: limit,
        });
        break;

      case "freelancers_by_rating":
        const { sequelize } = await import("../config/db.js");
        const [freelancersData] = await sequelize.query(
          `SELECT 
      u.id, 
      u.name, 
      u.avatar, 
      u.email,
      ROUND(AVG(r.rating), 2) as avg_rating,
      COUNT(r.id) as total_reviews
    FROM Users u
    INNER JOIN Ratings r ON r.toUserId = u.id
    WHERE u.role = 'freelancer'
    GROUP BY u.id, u.name, u.avatar, u.email
    HAVING COUNT(r.id) > 0
    ORDER BY avg_rating DESC
    LIMIT :limit`,
          {
            replacements: { limit: parseInt(limit) },
            type: Sequelize.QueryTypes.SELECT,
          },
        );

        performers.freelancers = freelancersData;
        break;

      case "clients_by_spending":
        performers.clients = await User.findAll({
          where: { role: "client" },
          attributes: [
            "id",
            "name",
            "avatar",
            "email",
            [
              Sequelize.literal(`(
              SELECT COALESCE(SUM(agreed_amount), 0) 
              FROM Contracts 
              WHERE ClientId = User.id AND status = 'completed'
            )`),
              "total_spent",
            ],
            [
              Sequelize.literal(`(
              SELECT COUNT(*) 
              FROM Contracts 
              WHERE ClientId = User.id
            )`),
              "total_contracts",
            ],
          ],
          order: [[Sequelize.literal("total_spent"), "DESC"]],
          limit: limit,
        });
        break;

      case "fastest_growing":
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

        performers.users = await User.findAll({
          where: {
            createdAt: { [Op.gte]: thirtyDaysAgo },
          },
          attributes: ["id", "name", "role", "avatar", "email", "createdAt"],
          order: [["createdAt", "DESC"]],
          limit: limit,
        });
        break;

      default:
        performers.freelancers = await this._calculateOverallScore(limit);
    }

    return performers;
  }

  static async _calculateOverallScore(limit) {
    const freelancers = await User.findAll({
      where: { role: "freelancer" },
      attributes: ["id", "name", "avatar", "email"],
      limit: 100,
    });

    const scored = [];

    for (const freelancer of freelancers) {
      const [earnings, completedProjects, avgRating, onTimeDelivery] =
        await Promise.all([
          Contract.sum("agreed_amount", {
            where: { FreelancerId: freelancer.id, status: "completed" },
          }),
          Contract.count({
            where: { FreelancerId: freelancer.id, status: "completed" },
          }),
          Rating.findOne({
            where: { toUserId: freelancer.id, role: "client" },
            attributes: [[Sequelize.fn("AVG", Sequelize.col("rating")), "avg"]],
            raw: true,
          }),
          Contract.count({
            where: {
              FreelancerId: freelancer.id,
              status: "completed",
              [Op.and]: Sequelize.where(
                Sequelize.col("end_date"),
                "<=",
                Sequelize.col("updatedAt"),
              ),
            },
          }),
        ]);

      const earningsScore = Math.min((earnings || 0) / 10000, 100);
      const completionScore = Math.min(completedProjects * 5, 50);
      const ratingScore = (avgRating?.avg || 0) * 20;
      const deliveryScore = Math.min(onTimeDelivery * 10, 30);

      const totalScore =
        earningsScore * 0.3 +
        completionScore * 0.2 +
        ratingScore * 0.3 +
        deliveryScore * 0.2;

      scored.push({
        ...freelancer.toJSON(),
        score: Math.round(totalScore),
        metrics: {
          earnings: earnings || 0,
          completedProjects,
          rating: avgRating?.avg || 0,
          onTimeDelivery,
        },
      });
    }

    return scored.sort((a, b) => b.score - a.score).slice(0, limit);
  }

  static async getPredictiveAnalytics() {
    const predictions = {};

    const monthlyGrowth = await this._calculateMonthlyGrowth();
    predictions.expected_new_users = Math.round(monthlyGrowth.average * 1.1);

    const revenueTrend = await this._calculateRevenueTrend();
    predictions.expected_revenue =
      Math.round(revenueTrend.projected * 100) / 100;
    predictions.revenue_confidence = revenueTrend.confidence;

    const disputeTrend = await this._calculateDisputeTrend();
    predictions.expected_disputes = Math.round(disputeTrend.projected);
    predictions.dispute_risk = disputeTrend.risk_level;

    predictions.growth_forecast = {
      users: monthlyGrowth.growth_rate,
      revenue: revenueTrend.growth_rate,
    };

    await this._generateSmartAlerts(predictions);

    return predictions;
  }

  static async _calculateMonthlyGrowth() {
    const sixMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);

    const monthlyData = await User.findAll({
      attributes: [
        [
          Sequelize.fn("DATE_FORMAT", Sequelize.col("createdAt"), "%Y-%m"),
          "month",
        ],
        [Sequelize.fn("COUNT", Sequelize.col("id")), "count"],
      ],
      where: { createdAt: { [Op.gte]: sixMonthsAgo } },
      group: [Sequelize.fn("DATE_FORMAT", Sequelize.col("createdAt"), "%Y-%m")],
      order: [[Sequelize.literal("month"), "ASC"]],
      raw: true,
    });

    const counts = monthlyData.map((d) => parseInt(d.count));
    const average = counts.reduce((a, b) => a + b, 0) / counts.length;

    let growthRate = 0;
    if (counts.length >= 2) {
      growthRate = ((counts[counts.length - 1] - counts[0]) / counts[0]) * 100;
    }

    return { average, growth_rate: growthRate, data: monthlyData };
  }

  static async _calculateRevenueTrend() {
    const sixMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);

    const monthlyRevenue = await Transaction.findAll({
      attributes: [
        [
          Sequelize.fn(
            "DATE_FORMAT",
            Sequelize.col("transaction_date"),
            "%Y-%m",
          ),
          "month",
        ],
        [Sequelize.fn("SUM", Sequelize.col("amount")), "total"],
      ],
      where: {
        transaction_date: { [Op.gte]: sixMonthsAgo },
        status: "completed",
        type: { [Op.in]: ["platform_fee", "ad_revenue"] },
      },
      group: [
        Sequelize.fn("DATE_FORMAT", Sequelize.col("transaction_date"), "%Y-%m"),
      ],
      order: [[Sequelize.literal("month"), "ASC"]],
      raw: true,
    });

    const revenues = monthlyRevenue.map((d) => parseFloat(d.total));

    let projected = revenues[revenues.length - 1] || 0;
    let confidence = 50;

    if (revenues.length >= 3) {
      const trend =
        revenues[revenues.length - 1] - revenues[revenues.length - 2];
      projected = revenues[revenues.length - 1] + trend;
      confidence = 65;

      if (revenues.length >= 6) {
        const avgTrend =
          (revenues[revenues.length - 1] - revenues[0]) / (revenues.length - 1);
        projected = revenues[revenues.length - 1] + avgTrend;
        confidence = 75;
      }
    }

    const growthRate =
      revenues.length >= 2
        ? ((revenues[revenues.length - 1] - revenues[0]) / revenues[0]) * 100
        : 0;

    return {
      projected,
      growth_rate: growthRate,
      confidence,
      data: monthlyRevenue,
    };
  }

  static async _calculateDisputeTrend() {
    const threeMonthsAgo = new Date();
    threeMonthsAgo.setMonth(threeMonthsAgo.getMonth() - 3);

    const disputes = await Dispute.findAll({
      attributes: [
        [
          Sequelize.fn("DATE_FORMAT", Sequelize.col("createdAt"), "%Y-%m"),
          "month",
        ],
        [Sequelize.fn("COUNT", Sequelize.col("id")), "count"],
      ],
      where: { createdAt: { [Op.gte]: threeMonthsAgo } },
      group: [Sequelize.fn("DATE_FORMAT", Sequelize.col("createdAt"), "%Y-%m")],
      raw: true,
    });

    const counts = disputes.map((d) => parseInt(d.count));
    let projected = counts[counts.length - 1] || 0;
    let risk_level = "low";

    if (counts.length >= 2) {
      const trend = counts[counts.length - 1] - counts[counts.length - 2];
      projected = counts[counts.length - 1] + trend;

      if (trend > 0 && projected > counts[counts.length - 1] * 1.2) {
        risk_level = "high";
      } else if (trend > 0) {
        risk_level = "medium";
      }
    }

    return { projected, risk_level };
  }

  static async _generateSmartAlerts(predictions) {
    if (predictions.dispute_risk === "high") {
      await this.createInsight({
        type: "alert",
        title: "⚠️ ارتفاع خطر النزاعات",
        description: `من المتوقع ارتفاع النزاعات إلى ${predictions.expected_disputes} نزاع خلال الشهر القادم. يوصى بمراجعة سياسات حل النزاعات.`,
        severity: "warning",
        category: "disputes",
        action_url: "/admin/disputes",
        action_text: "مراجعة النزاعات",
      });
    }

    if (predictions.growth_forecast.revenue < -10) {
      await this.createInsight({
        type: "alert",
        title: "📉 انخفاض متوقع في الإيرادات",
        description: `من المتوقع انخفاض الإيرادات بنسبة ${Math.abs(predictions.growth_forecast.revenue).toFixed(1)}% الشهر القادم.`,
        severity: "warning",
        category: "revenue",
        action_url: "/admin/ads",
        action_text: "مراجعة الإعلانات",
      });
    }

    if (predictions.growth_forecast.users > 15) {
      await this.createInsight({
        type: "insight",
        title: "📈 نمو ممتاز متوقع",
        description: `من المتوقع نمو المستخدمين بنسبة ${predictions.growth_forecast.users.toFixed(1)}% الشهر القادم!`,
        severity: "success",
        category: "users",
      });
    }
  }

  static async createInsight(data) {
    const existing = await AdminInsight.findOne({
      where: {
        type: data.type,
        category: data.category,
        is_resolved: false,
        created_at: { [Op.gte]: new Date(Date.now() - 24 * 60 * 60 * 1000) },
      },
    });

    if (!existing) {
      return await AdminInsight.create(data);
    }
    return existing;
  }

  static async getActiveInsights() {
    return await AdminInsight.findAll({
      where: {
        is_resolved: false,
        [Op.or]: [
          { expires_at: null },
          { expires_at: { [Op.gt]: new Date() } },
        ],
      },
      order: [
        [
          Sequelize.literal(
            `FIELD(severity, 'critical', 'warning', 'info', 'success')`,
          ),
          "ASC",
        ],
        ["created_at", "DESC"],
      ],
    });
  }

  static async resolveInsight(insightId, adminId) {
    const insight = await AdminInsight.findByPk(insightId);
    if (insight) {
      await insight.update({
        is_resolved: true,
        resolved_at: new Date(),
        resolved_by: adminId,
      });
    }
    return insight;
  }

  static async logAdminAction({
    adminId,
    adminName,
    action,
    targetType,
    targetId,
    targetName,
    changes,
    ipAddress,
    userAgent,
    severity = "low",
  }) {
    return await AdminAuditLog.create({
      admin_id: adminId,
      admin_name: adminName,
      action,
      target_type: targetType,
      target_id: targetId,
      target_name: targetName,
      changes: JSON.stringify(changes || {}),
      ip_address: ipAddress,
      user_agent: userAgent,
      severity,
    });
  }

  static async getAuditLogs(filters = {}) {
    const {
      adminId,
      action,
      targetType,
      severity,
      startDate,
      endDate,
      limit = 50,
    } = filters;

    const where = {};
    if (adminId) where.admin_id = adminId;
    if (action) where.action = action;
    if (targetType) where.target_type = targetType;
    if (severity) where.severity = severity;
    if (startDate && endDate) {
      where.created_at = {
        [Op.between]: [new Date(startDate), new Date(endDate)],
      };
    }

    return await AdminAuditLog.findAll({
      where,
      order: [["created_at", "DESC"]],
      limit: parseInt(limit),
    });
  }

  static async getAdvancedStats() {
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const totalContracts = await Contract.count();
    const completedContracts = await Contract.count({
      where: { status: "completed" },
    });
    const completionRate =
      totalContracts > 0 ? (completedContracts / totalContracts) * 100 : 0;

    const totalValue = await Contract.sum("agreed_amount", {
      where: { status: "completed" },
    });
    const avgContractValue =
      completedContracts > 0 ? totalValue / completedContracts : 0;

    const activeUsersLast30Days = await User.count({
      where: {
        last_login: {
          [Op.gte]: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
        },
      },
    });
    const totalUsers = await User.count();
    const engagementRate =
      totalUsers > 0 ? (activeUsersLast30Days / totalUsers) * 100 : 0;

    const mauTrend = await User.findAll({
      attributes: [
        [
          Sequelize.fn("DATE_FORMAT", Sequelize.col("last_login"), "%Y-%m"),
          "month",
        ],
        [Sequelize.fn("COUNT", Sequelize.col("id")), "active_users"],
      ],
      where: {
        last_login: {
          [Op.gte]: new Date(Date.now() - 180 * 24 * 60 * 60 * 1000),
        },
      },
      group: [
        Sequelize.fn("DATE_FORMAT", Sequelize.col("last_login"), "%Y-%m"),
      ],
      order: [[Sequelize.literal("month"), "ASC"]],
      raw: true,
    });

    const resolvedDisputes = await Dispute.findAll({
      where: { status: "resolved" },
    });
    let avgResolutionHours = 0;
    if (resolvedDisputes.length > 0) {
      const totalHours = resolvedDisputes.reduce((sum, d) => {
        const hours =
          (new Date(d.decision_date) - new Date(d.createdAt)) /
          (1000 * 60 * 60);
        return sum + hours;
      }, 0);
      avgResolutionHours = totalHours / resolvedDisputes.length;
    }

    const activeAds = await AdCampaign.count({ where: { status: "active" } });
    const totalAdSpend = await AdCampaign.sum("spent_amount");
    const totalAdClicks = await AdCampaign.sum("clicks");
    const totalAdImpressions = await AdCampaign.sum("impressions");
    const adCTR =
      totalAdImpressions > 0 ? (totalAdClicks / totalAdImpressions) * 100 : 0;

    return {
      engagement: {
        active_users_last_30_days: activeUsersLast30Days,
        engagement_rate: Math.round(engagementRate * 10) / 10,
        monthly_active_users_trend: mauTrend,
      },
      contracts: {
        completion_rate: Math.round(completionRate * 10) / 10,
        average_contract_value: Math.round(avgContractValue * 100) / 100,
        total_contracts: totalContracts,
        completed_contracts: completedContracts,
      },
      disputes: {
        total: resolvedDisputes.length,
        avg_resolution_hours: Math.round(avgResolutionHours),
      },
      ads: {
        active_campaigns: activeAds,
        total_spend: totalAdSpend,
        total_clicks: totalAdClicks,
        total_impressions: totalAdImpressions,
        ctr: Math.round(adCTR * 100) / 100,
      },
    };
  }

  static async getUserSatisfactionAnalysis() {
    const ninetyDaysAgo = new Date();
    ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90);

    const ratings = await Rating.findAll({
      where: { createdAt: { [Op.gte]: ninetyDaysAgo } },
      attributes: ["rating", "role", "createdAt"],
    });

    const freelancerRatings = ratings.filter((r) => r.role === "client");
    const clientRatings = ratings.filter((r) => r.role === "freelancer");

    const calculateStats = (ratingsArray) => {
      if (ratingsArray.length === 0) return null;
      const avg =
        ratingsArray.reduce((sum, r) => sum + r.rating, 0) /
        ratingsArray.length;
      const distribution = {
        1: ratingsArray.filter((r) => r.rating === 1).length,
        2: ratingsArray.filter((r) => r.rating === 2).length,
        3: ratingsArray.filter((r) => r.rating === 3).length,
        4: ratingsArray.filter((r) => r.rating === 4).length,
        5: ratingsArray.filter((r) => r.rating === 5).length,
      };
      const satisfactionRate =
        ((distribution[4] + distribution[5]) / ratingsArray.length) * 100;

      return {
        avg,
        distribution,
        satisfaction_rate: satisfactionRate,
        total: ratingsArray.length,
      };
    };

    const weeklyTrend = [];
    for (let i = 12; i >= 0; i--) {
      const weekStart = new Date();
      weekStart.setDate(weekStart.getDate() - i * 7);
      const weekEnd = new Date(weekStart);
      weekEnd.setDate(weekEnd.getDate() + 7);

      const weekRatings = ratings.filter(
        (r) => r.createdAt >= weekStart && r.createdAt < weekEnd,
      );
      const avg =
        weekRatings.length > 0
          ? weekRatings.reduce((sum, r) => sum + r.rating, 0) /
            weekRatings.length
          : 0;

      weeklyTrend.push({
        week: `Week ${12 - i}`,
        average_rating: Math.round(avg * 10) / 10,
        count: weekRatings.length,
      });
    }

    return {
      overall: {
        average_rating:
          ratings.length > 0
            ? Math.round(
                (ratings.reduce((sum, r) => sum + r.rating, 0) /
                  ratings.length) *
                  10,
              ) / 10
            : 0,
        total_reviews: ratings.length,
      },
      freelancer_feedback: calculateStats(freelancerRatings),
      client_feedback: calculateStats(clientRatings),
      weekly_trend: weeklyTrend,
      recommendations: this._generateSatisfactionRecommendations(
        calculateStats(freelancerRatings),
        calculateStats(clientRatings),
      ),
    };
  }

  static _generateSatisfactionRecommendations(freelancerStats, clientStats) {
    const recommendations = [];

    if (freelancerStats && freelancerStats.satisfaction_rate < 70) {
      recommendations.push({
        area: "freelancers",
        issue: "رضا الفريلانسر منخفض",
        suggestion: "مراجعة سياسات العمولة وتحسين دعم الفريلانسر",
        priority: "high",
      });
    }

    if (clientStats && clientStats.satisfaction_rate < 75) {
      recommendations.push({
        area: "clients",
        issue: "رضا العملاء منخفض",
        suggestion: "تحسين جودة المشاريع والتواصل مع الفريلانسر",
        priority: "high",
      });
    }

    if (
      freelancerStats &&
      freelancerStats.distribution[1] > freelancerStats.total * 0.1
    ) {
      recommendations.push({
        area: "freelancers",
        issue: "نسبة مرتفعة من التقييمات السيئة",
        suggestion: "مراجعة الفريلانسر ذوي التقييم المنخفض وتقديم تدريب لهم",
        priority: "medium",
      });
    }

    return recommendations;
  }
}

export default AdminAnalyticsService;
