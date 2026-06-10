import AdCampaign from "../models/AdCampaign.js";
import AdImpression from "../models/AdImpression.js";
import { sequelize } from "../config/db.js";
import { Op, literal } from "sequelize";

class AdService {
  static async getActiveAds(
    placement,
    userId = null,
    userRole = null,
    userCountry = null,
  ) {
    let query = `
    SELECT * FROM adcampaigns 
    WHERE status = 'active'
    AND spent_amount < total_budget
  `;

    if (placement) {
      query += ` AND placement = '${placement}'`;
    }

    query += ` ORDER BY impressions ASC`;

    const result = await sequelize.query(query, {
      type: sequelize.QueryTypes.SELECT,
    });

    const eligibleAds = result.filter((ad) =>
      this.isUserEligible(ad, userId, userRole, userCountry),
    );

    console.log(
      "🔍 Ads found:",
      result.length,
      "Eligible:",
      eligibleAds.length,
    );

    return eligibleAds;
  }

  static isUserEligible(ad, userId, userRole, userCountry) {
    if (ad.target_countries) {
      const countries = JSON.parse(ad.target_countries);
      if (countries.length > 0 && !countries.includes(userCountry))
        return false;
    }

    if (ad.user_roles) {
      const roles = JSON.parse(ad.user_roles);
      if (roles.length > 0 && !roles.includes(userRole)) return false;
    }

    return true;
  }

  static async recordImpression(campaignId, userId, country, userRole) {
    const campaign = await AdCampaign.findByPk(campaignId);
    if (!campaign) return;

    let revenue = 0;
    if (campaign.pricing_model === "cpm") {
      revenue = campaign.cost_per_impression;
    }

    await AdImpression.create({
      campaign_id: campaignId,
      user_id: userId,
      user_country: country,
      user_role: userRole,
      type: "impression",
      revenue: revenue,
    });

    await campaign.increment("impressions");

    if (revenue > 0) {
      await campaign.increment("spent_amount", { by: revenue });
      await this.recordAdRevenue(campaignId, revenue, "impression");
    }
  }

  static async recordClick(campaignId, userId, country, userRole) {
    const campaign = await AdCampaign.findByPk(campaignId);
    if (!campaign) return null;

    let revenue = 0;
    if (campaign.pricing_model === "cpc") {
      revenue = campaign.cost_per_click;
    } else if (campaign.pricing_model === "cpm") {
      revenue = campaign.cost_per_impression * 10;
    }

    await AdImpression.create({
      campaign_id: campaignId,
      user_id: userId,
      user_country: country,
      user_role: userRole,
      type: "click",
      revenue: revenue,
    });

    await campaign.increment("clicks");

    if (revenue > 0) {
      await campaign.increment("spent_amount", { by: revenue });
      await this.recordAdRevenue(campaignId, revenue, "click");
    }

    return campaign.target_url;
  }

  static async recordAdRevenue(campaignId, amount, type) {
    try {
      const { Transaction } = await import("../models/index.js");
      const campaign = await AdCampaign.findByPk(campaignId);
      if (!campaign) return;

      const platformCommission = parseFloat(amount) * 0.2;

      await Transaction.create({
        user_id: 0,
        user_role: "system",
        amount: platformCommission,
        type: "ad_revenue",
        status: "completed",
        transaction_date: new Date(),
        description: `Ad revenue from campaign #${campaignId} (${type})`,
        reference_id: campaignId,
        reference_type: "ad_campaign",
        metadata: JSON.stringify({
          campaign_name: campaign.name,
          advertiser_id: campaign.advertiser_id,
          total_amount: amount,
          commission_rate: 0.2,
        }),
      });
    } catch (error) {
      console.error("Error recording ad revenue:", error);
    }
  }

  static async getAdStats(advertiserId = null) {
    const where = {};
    if (advertiserId) where.advertiser_id = advertiserId;

    const campaigns = await AdCampaign.findAll({ where });

    let totalImpressions = 0,
      totalClicks = 0,
      totalSpent = 0,
      totalConversions = 0;

    for (const c of campaigns) {
      totalImpressions += c.impressions;
      totalClicks += c.clicks;
      totalSpent += parseFloat(c.spent_amount);
      totalConversions += c.conversions;
    }

    const ctr =
      totalImpressions > 0 ? (totalClicks / totalImpressions) * 100 : 0;
    const avgCpc = totalClicks > 0 ? totalSpent / totalClicks : 0;

    return {
      total_campaigns: campaigns.length,
      active_campaigns: campaigns.filter((c) => c.status === "active").length,
      total_impressions: totalImpressions,
      total_clicks: totalClicks,
      total_spent: totalSpent,
      total_conversions: totalConversions,
      ctr: ctr.toFixed(2),
      avg_cpc: avgCpc.toFixed(3),
      platform_revenue: totalSpent * 0.2,
    };
  }
}

export default AdService;
