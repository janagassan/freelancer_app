import Stripe from "stripe";
import AdCampaign from "../models/AdCampaign.js";
import AdTransaction from "../models/AdTransaction.js";
import User from "../models/User.js";
import Wallet from "../models/Wallet.js";
import { sequelize } from "../config/db.js";

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

class AdPaymentService {
  static async createCheckoutSession(
    campaignId,
    userId,
    successUrl,
    cancelUrl,
  ) {
    try {
      const campaign = await AdCampaign.findByPk(campaignId);
      if (!campaign) throw new Error("Campaign not found");

      const user = await User.findByPk(userId);
      if (!user) throw new Error("User not found");

      const amount = parseFloat(campaign.total_budget);

      const session = await stripe.checkout.sessions.create({
        payment_method_types: ["card"],
        line_items: [
          {
            price_data: {
              currency: "usd",
              product_data: {
                name: `Ad Campaign: ${campaign.name}`,
                description: `Campaign from ${new Date(campaign.start_date).toLocaleDateString()} to ${new Date(campaign.end_date).toLocaleDateString()}`,
                images: campaign.image_url ? [campaign.image_url] : [],
              },
              unit_amount: Math.round(amount * 100),
            },
            quantity: 1,
          },
        ],
        mode: "payment",
        success_url: successUrl,
        cancel_url: cancelUrl,
        customer_email: user.email,
        metadata: {
          campaign_id: campaign.id,
          user_id: user.id,
          type: "ad_campaign",
        },
      });

      await AdTransaction.create({
        campaign_id: campaign.id,
        advertiser_id: userId,
        amount: amount,
        payment_status: "pending",
        payment_method: "stripe",
        transaction_id: session.id,
        metadata: JSON.stringify({ session_id: session.id }),
      });

      return { url: session.url, sessionId: session.id };
    } catch (error) {
      console.error("Error creating checkout session:", error);
      throw error;
    }
  }

  static async handleWebhook(event) {
    try {
      const session = event.data.object;

      if (event.type === "checkout.session.completed") {
        const campaignId = parseInt(session.metadata.campaign_id);
        const userId = parseInt(session.metadata.user_id);

        await AdTransaction.update(
          {
            payment_status: "paid",
            payment_intent_id: session.payment_intent,
            paid_at: new Date(),
          },
          { where: { transaction_id: session.id } },
        );

        await AdCampaign.update(
          {
            status: "active",
            payment_status: "paid",
            payment_transaction_id: session.payment_intent,
          },
          { where: { id: campaignId } },
        );

        const campaign = await AdCampaign.findByPk(campaignId);
        await this.recordAdRevenue(
          campaignId,
          campaign.total_budget,
          "campaign_payment",
        );

        console.log(`✅ Campaign ${campaignId} activated after payment`);
      } else if (event.type === "checkout.session.expired") {
        await AdTransaction.update(
          { payment_status: "failed" },
          { where: { transaction_id: session.id } },
        );

        await AdCampaign.update(
          { status: "draft" },
          { where: { id: parseInt(session.metadata.campaign_id) } },
        );
      }

      return { received: true };
    } catch (error) {
      console.error("Webhook error:", error);
      throw error;
    }
  }

  static async payFromWallet(campaignId, userId) {
    const transaction = await sequelize.transaction();

    try {
      const campaign = await AdCampaign.findByPk(campaignId);
      if (!campaign) throw new Error("Campaign not found");

      const wallet = await Wallet.findOne({ where: { UserId: userId } });
      if (!wallet || wallet.balance < campaign.total_budget) {
        throw new Error("Insufficient wallet balance");
      }

      await wallet.update(
        { balance: wallet.balance - parseFloat(campaign.total_budget) },
        { transaction },
      );

      const adTransaction = await AdTransaction.create(
        {
          campaign_id: campaign.id,
          advertiser_id: userId,
          amount: campaign.total_budget,
          payment_status: "paid",
          payment_method: "wallet",
          paid_at: new Date(),
          transaction_id: `wallet_${Date.now()}`,
        },
        { transaction },
      );

      await campaign.update(
        {
          status: "active",
          payment_status: "paid",
          payment_transaction_id: adTransaction.id,
        },
        { transaction },
      );

      await this.recordAdRevenue(
        campaignId,
        campaign.total_budget,
        "wallet_payment",
      );

      await transaction.commit();

      return { success: true, message: "Campaign activated using wallet" };
    } catch (error) {
      await transaction.rollback();
      console.error("Wallet payment error:", error);
      throw error;
    }
  }

  static async recordManualPayment(campaignId, adminId, amount, reference) {
    try {
      const campaign = await AdCampaign.findByPk(campaignId);
      if (!campaign) throw new Error("Campaign not found");

      const adTransaction = await AdTransaction.create({
        campaign_id: campaign.id,
        advertiser_id: campaign.advertiser_id,
        amount: amount,
        payment_status: "paid",
        payment_method: "bank_transfer",
        transaction_id: reference,
        paid_at: new Date(),
        metadata: JSON.stringify({ recorded_by_admin: adminId }),
      });

      await campaign.update({
        payment_status: "paid",
        payment_transaction_id: adTransaction.id,
      });

      if (campaign.status === "draft" || campaign.status === "paused") {
        await campaign.update({ status: "active" });
      }

      await this.recordAdRevenue(campaignId, amount, "manual_payment");

      return { success: true, message: "Manual payment recorded" };
    } catch (error) {
      console.error("Manual payment error:", error);
      throw error;
    }
  }

  static async recordAdRevenue(campaignId, amount, type) {
    try {
      const campaign = await AdCampaign.findByPk(campaignId);
      if (!campaign) return;

      const platformCommission = parseFloat(amount) * 0.2;
      const advertiserNet = parseFloat(amount) * 0.8;

      const { Transaction } = await import("../models/index.js");

      await Transaction.create({
        user_id: 0,
        user_role: "system",
        amount: platformCommission,
        type: "ad_revenue",
        status: "completed",
        transaction_date: new Date(),
        description: `Platform commission from ad campaign #${campaignId} (${type})`,
        reference_id: campaignId,
        reference_type: "ad_campaign",
        metadata: JSON.stringify({
          campaign_name: campaign.name,
          advertiser_id: campaign.advertiser_id,
          total_amount: amount,
          commission_rate: 0.2,
        }),
      });

      const adminStats = await this.getAdminStats();

      console.log(
        `💰 Ad revenue recorded: $${platformCommission} (20% of $${amount}) from campaign #${campaignId}`,
      );

      return { platformCommission, advertiserNet };
    } catch (error) {
      console.error("Error recording ad revenue:", error);
    }
  }

  static async getAdminStats() {
    try {
      const { Transaction } = await import("../models/index.js");

      const totalAdRevenue =
        (await Transaction.sum("amount", {
          where: { type: "ad_revenue", status: "completed" },
        })) || 0;

      const monthlyAdRevenue = await Transaction.findAll({
        attributes: [
          [
            sequelize.fn(
              "DATE_FORMAT",
              sequelize.col("transaction_date"),
              "%Y-%m",
            ),
            "month",
          ],
          [sequelize.fn("SUM", sequelize.col("amount")), "total"],
        ],
        where: { type: "ad_revenue", status: "completed" },
        group: [
          sequelize.fn(
            "DATE_FORMAT",
            sequelize.col("transaction_date"),
            "%Y-%m",
          ),
        ],
        order: [[sequelize.literal("month"), "DESC"]],
        limit: 12,
        raw: true,
      });

      const activeCampaigns = await AdCampaign.count({
        where: { status: "active" },
      });

      const totalCampaignSpend =
        (await AdTransaction.sum("amount", {
          where: { payment_status: "paid" },
        })) || 0;

      return {
        total_ad_revenue: totalAdRevenue,
        monthly_ad_revenue: monthlyAdRevenue,
        active_campaigns: activeCampaigns,
        total_campaign_spend: totalCampaignSpend,
        platform_commission_rate: 0.2,
        platform_commission_earned: totalAdRevenue,
      };
    } catch (error) {
      console.error("Error getting admin stats:", error);
      return {
        total_ad_revenue: 0,
        active_campaigns: 0,
        total_campaign_spend: 0,
        platform_commission_earned: 0,
      };
    }
  }

  static async checkPaymentStatus(campaignId) {
    try {
      const campaign = await AdCampaign.findByPk(campaignId);
      if (!campaign) return { success: false, message: "Campaign not found" };

      const transaction = await AdTransaction.findOne({
        where: { campaign_id: campaignId, payment_status: "paid" },
      });

      const isPaid = !!transaction;
      const isActive = campaign.status === "active";

      return {
        success: true,
        isPaid,
        isActive,
        paymentStatus: campaign.payment_status,
        campaignStatus: campaign.status,
        transaction: transaction
          ? {
              amount: transaction.amount,
              paidAt: transaction.paid_at,
              method: transaction.payment_method,
            }
          : null,
      };
    } catch (error) {
      console.error("Error checking payment status:", error);
      return { success: false, message: error.message };
    }
  }
}

export default AdPaymentService;
