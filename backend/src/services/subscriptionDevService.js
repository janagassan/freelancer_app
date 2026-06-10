// backend/src/services/subscriptionDevService.js

import { User, SubscriptionPlan, UserSubscription } from "../models/index.js";
import NotificationService from "./notificationService.js";

class SubscriptionDevService {
  static async manualActivateSubscription(userId, planSlug) {
  try {
    console.log("🔄 [DEV] Manual activation for user:", userId, "plan:", planSlug);

    const plan = await SubscriptionPlan.findOne({
      where: { slug: planSlug },
    });
    if (!plan) {
      throw new Error("Plan not found");
    }

    let subscription = await UserSubscription.findOne({
      where: { user_id: userId }
    });

    if (subscription) {
      await subscription.update({
        plan_id: plan.id,
        status: "active",
        current_period_start: new Date(),
        current_period_end: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        trial_start: new Date(),
        trial_end: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
        cancel_at_period_end: false,
        updatedAt: new Date()
      });
    } else {
      subscription = await UserSubscription.create({
        user_id: userId,
        plan_id: plan.id,
        status: "active",
        current_period_start: new Date(),
        current_period_end: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        trial_start: new Date(),
        trial_end: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
      });
    }

    await User.update(
      {
        proposal_count_this_month: 0,
        proposal_reset_date: new Date(),
      },
      { where: { id: userId } }
    );

    console.log("✅ [DEV] Manual activation successful for user:", userId);

    await NotificationService.createNotification({
      userId: userId,
      type: "subscription_activated",
      title: "Subscription Activated!",
      body: `Your ${plan.name} plan is now active. Enjoy the benefits!`,
      data: { screen: "subscription" },
    });

    return { success: true, subscription, plan };
  } catch (error) {
    console.error("❌ [DEV] Error in manual activation:", error);
    throw error;
  }
}
}

export default SubscriptionDevService;
