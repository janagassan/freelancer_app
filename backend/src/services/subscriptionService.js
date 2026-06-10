import stripe from "../config/stripe.js";
import {
  User,
  SubscriptionPlan,
  UserSubscription,
  Transaction,
  Wallet,
  InterviewInvitation,
} from "../models/index.js";
import { Op } from "sequelize";
import NotificationService from "./notificationService.js";
import InvoiceService from "./InvoiceService.js";

class SubscriptionService {
  static async getPlans() {
    return await SubscriptionPlan.findAll({
      where: { is_active: true },
      order: [["price", "ASC"]],
    });
  }

  static async getUserSubscription(userId) {
  const subscription = await UserSubscription.findOne({
    where: {
      user_id: userId,
      status: { [Op.in]: ["active", "trialing"] },
    },
    include: [{ model: SubscriptionPlan }],
    order: [["createdAt", "DESC"]], 
  });

  if (subscription) {
    return {
      plan: subscription.SubscriptionPlan,
      isActive: true,
      subscriptionData: subscription,
    };
  }

  const freePlan = await SubscriptionPlan.findOne({
    where: { slug: "free" },
  });
  
  return {
    plan: freePlan,
    isActive: false,
    usage: {},
  };
}

static async refreshUserSubscriptionAfterPayment(userId) {
  try {
    await User.update(
      {
        proposal_count_this_month: 0,
        proposal_reset_date: new Date(),
        active_projects_count: 0,
      },
      { where: { id: userId } },
    );
    
    console.log("✅ User counters reset after subscription payment");
    return true;
  } catch (error) {
    console.error("❌ Error resetting user counters:", error);
    return false;
  }
}

  static async canSubmitProposal(userId) {
    const user = await User.findByPk(userId);
    if (!user) return false;

    const subscription = await this.getUserSubscription(userId);
    const plan = subscription.plan;

    if (plan.proposal_limit === null) {
      return true;
    }

    const now = new Date();
    const resetDate = new Date(user.proposal_reset_date);
    if (
      now.getMonth() !== resetDate.getMonth() ||
      now.getFullYear() !== resetDate.getFullYear()
    ) {
      await user.update({
        proposal_count_this_month: 0,
        proposal_reset_date: new Date(now.getFullYear(), now.getMonth(), 1),
      });
      user.proposal_count_this_month = 0;
    }

    return user.proposal_count_this_month < plan.proposal_limit;
  }

  static async incrementProposalCount(userId) {
    const user = await User.findByPk(userId);
    if (user) {
      await user.increment("proposal_count_this_month");
    }
  }

  static async countClientInterviewsThisMonth(clientId) {
    const now = new Date();
    const start = new Date(now.getFullYear(), now.getMonth(), 1);
    return InterviewInvitation.count({
      where: {
        client_id: clientId,
        createdAt: { [Op.gte]: start },
      },
    });
  }

  static async getClientInterviewUsage(clientId) {
    const used = await this.countClientInterviewsThisMonth(clientId);
    const sub = await this.getUserSubscription(clientId);
    const limit = sub.plan?.interview_limit;
    const unlimited = limit == null;
    return {
      interviews_used: used,
      interviews_limit: unlimited ? null : limit,
      remaining: unlimited ? null : Math.max(0, limit - used),
      can_create: unlimited || used < limit,
    };
  }

  static async canCreateActiveProject(userId) {
    const user = await User.findByPk(userId);
    if (!user) return false;

    const subscription = await this.getUserSubscription(userId);
    const plan = subscription.plan;

    if (plan.active_project_limit === null) return true;
    return user.active_projects_count < plan.active_project_limit;
  }

  static async incrementActiveProjectsCount(userId) {
    await User.increment("active_projects_count", {
      by: 1,
      where: { id: userId },
    });
  }

  static async decrementActiveProjectsCount(userId) {
    await User.decrement("active_projects_count", {
      by: 1,
      where: { id: userId },
    });
  }

  static async createSubscriptionPaymentIntent(planSlug, userId) {
    try {
      const plan = await SubscriptionPlan.findOne({
        where: { slug: planSlug, is_active: true },
      });

      if (!plan) {
        throw new Error("Subscription plan not found");
      }

      const paymentIntent = await stripe.paymentIntents.create({
        amount: Math.round(plan.price * 100),
        currency: "usd",
        metadata: {
          planSlug: plan.slug,
          userId: userId,
          type: "subscription",
          planName: plan.name,
        },
        description: `Subscription for ${plan.name} plan`,
      });

      return paymentIntent;
    } catch (error) {
      console.error("Error creating subscription payment intent:", error);
      throw error;
    }
  }

  static async confirmSubscriptionPayment(planSlug, paymentIntentId, userId) {
    try {
      console.log("🎯 confirmSubscriptionPayment called with:", {
        planSlug,
        paymentIntentId,
        userId,
      });

      const paymentIntent =
        await stripe.paymentIntents.retrieve(paymentIntentId);
      console.log("💳 Retrieved payment intent:", {
        status: paymentIntent.status,
        amount: paymentIntent.amount,
      });

      if (paymentIntent.status !== "succeeded") {
        throw new Error("Payment not successful");
      }

      const plan = await SubscriptionPlan.findOne({
        where: { slug: planSlug, is_active: true },
      });

      if (!plan) {
        throw new Error("Subscription plan not found");
      }
      console.log("📋 Found plan:", {
        id: plan.id,
        name: plan.name,
        price: plan.price,
      });

      const existingSubscription = await UserSubscription.findOne({
        where: { user_id: userId },
      });
      console.log(
        "🔍 Existing subscription:",
        existingSubscription
          ? { id: existingSubscription.id, status: existingSubscription.status }
          : "None",
      );

      if (existingSubscription) {
        if (
          existingSubscription.stripe_subscription_id &&
          existingSubscription.stripe_subscription_id.startsWith("manual_")
        ) {
          console.log("Skipping Stripe cancellation for manual subscription");
        } else if (existingSubscription.stripe_subscription_id) {
          try {
            await stripe.subscriptions.cancel(
              existingSubscription.stripe_subscription_id,
            );
          } catch (e) {
            console.log("Could not cancel old subscription:", e);
          }
        }
        await existingSubscription.destroy();
        console.log("🗑️ Old subscription destroyed");
      }

      const subscription = await UserSubscription.create({
        user_id: userId,
        plan_id: plan.id,
        status: "active",
        stripe_subscription_id: paymentIntentId,
        current_period_start: new Date(),
        current_period_end: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        trial_end:
          plan.price > 0
            ? new Date(Date.now() + 14 * 24 * 60 * 60 * 1000)
            : null,
      });
      console.log("✅ New subscription created:", {
        id: subscription.id,
        status: subscription.status,
      });

      await Transaction.create({
        user_id: userId,
        amount: plan.price,
        type: "subscription",
        status: "completed",
        description: `Subscription payment for ${plan.name} plan`,
        stripe_payment_intent_id: paymentIntentId,
        completed_at: new Date(),
      });
      console.log("💰 Transaction created");

      await NotificationService.createNotification({
        userId: userId,
        type: "subscription_activated",
        title: "Subscription Activated! ",
        body: `Your ${plan.name} subscription has been activated successfully.`,
        data: { screen: "subscription/my" },
      });
      console.log("📢 Notification sent");

      return subscription;
    } catch (error) {
      console.error("Error confirming subscription payment:", error);
      throw error;
    }
  }

  static async createSubscriptionCheckoutSession(
    planSlug,
    userId,
    frontendUrl,
  ) {
    try {
      const plan = await SubscriptionPlan.findOne({
        where: { slug: planSlug, is_active: true },
      });

      if (!plan) {
        throw new Error("Subscription plan not found");
      }

      console.log(
        "💰 Creating Stripe checkout session for subscription:",
        plan.name,
      );
      console.log("🔗 Frontend URL for redirects:", frontendUrl);

      const successUrl = `${frontendUrl}/#/subscription/success?session_id={CHECKOUT_SESSION_ID}`;
      const cancelUrl = `${frontendUrl}/#/subscription/cancel`;

      const session = await stripe.checkout.sessions.create({
        payment_method_types: ["card"],
        mode: "subscription",
        line_items: [
          {
            price_data: {
              currency: "usd",
              product_data: {
                name: `${plan.name} Plan`,
                description:
                  plan.description || `Subscribe to ${plan.name} plan`,
              },
              unit_amount: Math.round(plan.price * 100),
              recurring: {
                interval: plan.billing_period === "monthly" ? "month" : "year",
              },
            },
            quantity: 1,
          },
        ],
        success_url: successUrl,
        cancel_url: cancelUrl,
        metadata: {
          planSlug: plan.slug,
          userId: userId.toString(),
          type: "subscription",
        },
        subscription_data: {
          trial_period_days: 14,
          metadata: {
            planSlug: plan.slug,
            userId: userId.toString(),
          },
        },
      });

      console.log("✅ Stripe checkout session created:", session.id);
      console.log("✅ Session mode:", session.mode);
      console.log("✅ Checkout URL:", session.url);

      return {
        success: true,
        checkoutUrl: session.url,
        sessionId: session.id,
      };
    } catch (error) {
      console.error("❌ Error creating subscription checkout session:", error);
      throw error;
    }
  }

  static async manualConfirmSubscriptionPayment(planSlug, userId) {
    try {
      const plan = await SubscriptionPlan.findOne({
        where: { slug: planSlug, is_active: true },
      });

      if (!plan) {
        throw new Error("Subscription plan not found");
      }

      const existingSubscription = await UserSubscription.findOne({
        where: { user_id: userId },
      });

      if (existingSubscription) {
        if (
          existingSubscription.stripe_subscription_id &&
          existingSubscription.stripe_subscription_id.startsWith("manual_")
        ) {
          console.log("Skipping Stripe cancellation for manual subscription");
        } else if (existingSubscription.stripe_subscription_id) {
          try {
            await stripe.subscriptions.cancel(
              existingSubscription.stripe_subscription_id,
            );
          } catch (e) {
            console.log("Could not cancel old subscription:", e);
          }
        }
        await existingSubscription.destroy();
        console.log("🗑️ Old subscription destroyed");
      }

      const subscription = await UserSubscription.create({
        user_id: userId,
        plan_id: plan.id,
        status: "active",
        stripe_subscription_id: `manual_${Date.now()}`,
        current_period_start: new Date(),
        current_period_end: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        trial_end:
          plan.price > 0
            ? new Date(Date.now() + 14 * 24 * 60 * 60 * 1000)
            : null,
      });

      await Transaction.create({
        user_id: userId,
        amount: plan.price,
        type: "subscription",
        status: "completed",
        description: `Manual subscription payment for ${plan.name} plan`,
        completed_at: new Date(),
      });

      await NotificationService.createNotification({
        userId: userId,
        type: "subscription_activated",
        title: "Subscription Activated! ",
        body: `Your ${plan.name} subscription has been activated successfully.`,
        data: { screen: "subscription/my" },
      });

      return subscription;
    } catch (error) {
      console.error("Error in manual subscription confirmation:", error);
      throw error;
    }
  }

  static async handleSubscriptionWebhook(event) {
    switch (event.type) {
      case "checkout.session.completed":
        const session = event.data.object;
        if (session.metadata.type === "subscription") {
          await this.handleSubscriptionCheckoutSuccess(session);
        }
        break;
      case "customer.subscription.updated":
        await this.handleSubscriptionUpdate(event.data.object);
        break;
      case "customer.subscription.deleted":
        await this.handleSubscriptionCancellation(event.data.object);
        break;
      case "invoice.payment_succeeded":
        await this.handleInvoicePaymentSucceeded(event.data.object);
        break;
      default:
        console.log(`Unhandled subscription event type ${event.type}`);
    }
  }

  static async calculateMonthlyRevenue(startDate = null, endDate = null) {
    try {
      const whereClause = { status: "active" };
      if (startDate && endDate) {
        whereClause.createdAt = { [Op.between]: [startDate, endDate] };
      }

      const subscriptions = await UserSubscription.findAll({
        where: whereClause,
        include: [{ model: SubscriptionPlan, as: "SubscriptionPlan" }],
      });

      let monthlyRevenue = 0;
      for (const sub of subscriptions) {
        const plan = sub.SubscriptionPlan;
        if (plan.billing_period === "monthly") {
          monthlyRevenue += parseFloat(plan.price);
        } else if (plan.billing_period === "yearly") {
          monthlyRevenue += parseFloat(plan.price) / 12;
        }
      }
      return monthlyRevenue;
    } catch (error) {
      console.error("Error calculating monthly revenue:", error);
      return 0;
    }
  }

  static async calculateYearlyRevenue() {
    try {
      const subscriptions = await UserSubscription.findAll({
        where: { status: "active" },
        include: [{ model: SubscriptionPlan, as: "SubscriptionPlan" }],
      });

      let yearlyRevenue = 0;
      for (const sub of subscriptions) {
        const plan = sub.SubscriptionPlan;
        if (plan.billing_period === "monthly") {
          yearlyRevenue += parseFloat(plan.price) * 12;
        } else {
          yearlyRevenue += parseFloat(plan.price);
        }
      }
      return yearlyRevenue;
    } catch (error) {
      console.error("Error calculating yearly revenue:", error);
      return 0;
    }
  }

  static async changePlan(userId, newPlanSlug) {
    const currentSub = await UserSubscription.findOne({
      where: { user_id: userId, status: "active" },
    });

    const newPlan = await SubscriptionPlan.findOne({
      where: { slug: newPlanSlug },
    });
    if (!newPlan) throw new Error("Plan not found");

    if (currentSub) {
      if (newPlan.price > currentSub.SubscriptionPlan.price) {
        const diff = newPlan.price - currentSub.SubscriptionPlan.price;
        await this.createSubscriptionPaymentIntent(newPlanSlug, userId);
      }

      if (currentSub.stripe_subscription_id) {
        await stripe.subscriptions.update(currentSub.stripe_subscription_id, {
          items: [
            {
              id: currentSub.stripe_subscription_item_id,
              price: newPlan.stripe_price_id,
            },
          ],
          proration_behavior: "create_prorations",
        });
      }

      await currentSub.update({ plan_id: newPlan.id });
    }

    return { success: true, newPlan };
  }

  static async handleSubscriptionCheckoutSuccess(session) {
    try {
      console.log(
        "🎯 handleSubscriptionCheckoutSuccess called with session:",
        session.id,
      );
      console.log("🔍 Session metadata:", session.metadata);

      const { planSlug, userId } = session.metadata;
      console.log("📋 Extracted planSlug:", planSlug);
      console.log("👤 Extracted userId:", userId);

      const plan = await SubscriptionPlan.findOne({
        where: { slug: planSlug },
      });

      if (!plan) {
        throw new Error("Plan not found for subscription");
      }
      console.log("📋 Found plan:", {
        id: plan.id,
        name: plan.name,
        price: plan.price,
      });

      const existingSubscription = await UserSubscription.findOne({
        where: { user_id: userId },
      });
      console.log(
        "🔍 Existing subscription:",
        existingSubscription
          ? { id: existingSubscription.id, status: existingSubscription.status }
          : "None",
      );

      if (existingSubscription) {
        await existingSubscription.destroy();
        console.log("🗑️ Old subscription destroyed");
      }

      const newSubscription = await UserSubscription.create({
        user_id: userId,
        plan_id: plan.id,
        status: "active",
        stripe_subscription_id: session.id,
        current_period_start: new Date(),
        current_period_end: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      });
      console.log("✅ New subscription created:", {
        id: newSubscription.id,
        status: newSubscription.status,
      });

      await Transaction.create({
        user_id: userId,
        amount: plan.price,
        type: "subscription",
        status: "completed",
        description: `Subscription payment for ${plan.name} plan`,
        stripe_payment_intent_id: session.payment_intent,
        completed_at: new Date(),
      });
      console.log("💰 Transaction created");

      await NotificationService.createNotification({
        userId: userId,
        type: "subscription_activated",
        title: "Subscription Activated! ",
        body: `Your ${plan.name} subscription has been activated successfully.`,
        data: { screen: "subscription/my" },
      });
      console.log("📢 Notification sent");

      console.log("✅ Subscription created successfully");
    } catch (error) {
      console.error("❌ Error handling subscription checkout success:", error);
    }
  }

  static async handleSubscriptionUpdate(subscription) {
    console.log(" Subscription updated:", subscription.id);
  }

  static async handleSubscriptionCancellation(subscription) {
    console.log(" Subscription cancelled:", subscription.id);
  }

  static async handleInvoicePaymentSucceeded(invoice) {
    console.log(" Invoice payment succeeded:", invoice.id);
  }

  static async createCheckoutSession(userId, planSlug, successUrl, cancelUrl) {
    const user = await User.findByPk(userId);
    const plan = await SubscriptionPlan.findOne({ where: { slug: planSlug } });

    if (!plan) {
      throw new Error("Invalid subscription plan");
    }

    const session = await stripe.checkout.sessions.create({
      payment_method_types: ["card"],
      line_items: [
        {
          price_data: {
            currency: "usd",
            product_data: {
              name: `${plan.name} Plan - Freelancer Platform`,
              description: plan.description,
            },
            unit_amount: Math.round(plan.price * 100),
            recurring: {
              interval: plan.billing_period === "monthly" ? "month" : "year",
            },
          },
          quantity: 1,
        },
      ],
      mode: "subscription",
      success_url: successUrl,
      cancel_url: cancelUrl,
      customer_email: user.email,
      metadata: {
        userId: userId,
        planId: plan.id,
        planSlug: plan.slug,
      },
      subscription_data: {
        trial_period_days: 14,
      },
    });

    return { sessionId: session.id, checkoutUrl: session.url };
  }

  static async handleSubscriptionWebhook(event) {
    const subscription = event.data.object;

    switch (event.type) {
      case "checkout.session.completed":
        if (subscription.mode === "subscription") {
          await this.activateSubscription(subscription);
        }
        break;

      case "customer.subscription.updated":
        await this.updateSubscriptionStatus(subscription);
        break;

      case "customer.subscription.deleted":
        await this.cancelSubscription(subscription);
        break;

      case "invoice.payment_succeeded":
        await this.recordSubscriptionPayment(subscription, event.data.object);
        break;

      default:
        console.log(`Unhandled subscription event type: ${event.type}`);
    }
  }

  static async handleSubscriptionCheckoutSuccess(session) {
  try {
    console.log("🎯 handleSubscriptionCheckoutSuccess called with session:", session.id);
    console.log("🔍 Session metadata:", session.metadata);

    const { planSlug, userId } = session.metadata;
    
    if (!planSlug || !userId) {
      console.error("❌ Missing planSlug or userId in metadata");
      return;
    }

    const plan = await SubscriptionPlan.findOne({
      where: { slug: planSlug, is_active: true },
    });

    if (!plan) {
      console.error("❌ Plan not found:", planSlug);
      return;
    }

    console.log("📋 Found plan:", plan.name);

    await UserSubscription.update(
      { status: "canceled" },
      { where: { user_id: parseInt(userId), status: "active" } },
    );

    const subscription = await UserSubscription.create({
      user_id: parseInt(userId),
      plan_id: plan.id,
      status: "active",
      stripe_subscription_id: session.subscription || session.id,
      stripe_customer_id: session.customer,
      current_period_start: new Date(),
      current_period_end: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      trial_end: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
    });

    console.log("✅ Subscription created:", subscription.id);

    await User.update(
      {
        proposal_count_this_month: 0,
        proposal_reset_date: new Date(),
      },
      { where: { id: parseInt(userId) } },
    );

    console.log("✅ User counters reset");

    await NotificationService.createNotification({
      userId: parseInt(userId),
      type: "subscription_activated",
      title: "Subscription Activated! 🎉",
      body: `Your ${plan.name} subscription has been activated successfully.`,
      data: { screen: "subscription/my" },
    });

    console.log("✅ Notification sent");
  } catch (error) {
    console.error("❌ Error in handleSubscriptionCheckoutSuccess:", error);
  }
}

  static async activateSubscription(stripeCheckoutSession) {
    console.log(
      "🎯 Activating subscription for session:",
      stripeCheckoutSession.id,
    );

    const stripeSubscriptionId = stripeCheckoutSession.subscription;
    const stripeSubscription =
      await stripe.subscriptions.retrieve(stripeSubscriptionId);

    const userId = stripeCheckoutSession.metadata.userId;
    const planId = parseInt(stripeCheckoutSession.metadata.planId);
    const customerId = stripeCheckoutSession.customer;

    await UserSubscription.update(
      { status: "canceled" },
      { where: { user_id: userId, status: "active" } },
    );

    const userSubscription = await UserSubscription.create({
      user_id: userId,
      plan_id: planId,
      stripe_subscription_id: stripeSubscription.id,
      stripe_customer_id: customerId,
      status: stripeSubscription.status,
      current_period_start: new Date(
        stripeSubscription.current_period_start * 1000,
      ),
      current_period_end: new Date(
        stripeSubscription.current_period_end * 1000,
      ),
      trial_start: stripeSubscription.trial_start
        ? new Date(stripeSubscription.trial_start * 1000)
        : null,
      trial_end: stripeSubscription.trial_end
        ? new Date(stripeSubscription.trial_end * 1000)
        : null,
    });

    console.log("✅ UserSubscription created:", userSubscription.id);

    try {
      const paymentIntentId = stripeCheckoutSession.payment_intent;
      const invoice = await InvoiceService.createInvoice(
        userSubscription.id,
        paymentIntentId,
      );
      console.log("✅ Invoice created:", invoice.invoice_number);
    } catch (invoiceError) {
      console.error("❌ Error creating invoice:", invoiceError);
    }

    await User.update(
      {
        proposal_count_this_month: 0,
        proposal_reset_date: new Date(new Date().setDate(1)),
      },
      { where: { id: userId } },
    );

    await NotificationService.createNotification({
      userId: userId,
      type: "subscription_activated",
      title: "Subscription Activated!",
      body: `Your subscription is now active.`,
      data: { screen: "subscription" },
    });

    return userSubscription;
  }
  static async handleInvoicePaymentSucceeded(invoice) {
    try {
      const subscription = await UserSubscription.findOne({
        where: { stripe_subscription_id: invoice.subscription },
        include: [{ model: SubscriptionPlan, as: "SubscriptionPlan" }],
      });

      if (!subscription) {
        console.log("⚠️ No subscription found for invoice:", invoice.id);
        return;
      }

      const dbInvoice = await Invoice.findOne({
        where: { stripe_payment_intent_id: invoice.payment_intent },
      });

      if (dbInvoice) {
        await dbInvoice.update({
          status: "paid",
          paid_at: new Date(),
        });
        console.log("✅ Invoice marked as paid:", dbInvoice.invoice_number);
      } else {
        const newInvoice = await InvoiceService.createInvoice(
          subscription.id,
          invoice.payment_intent,
        );
        console.log("✅ New invoice created:", newInvoice.invoice_number);
      }

      await NotificationService.createNotification({
        userId: subscription.user_id,
        type: "payment_succeeded",
        title: "Payment Successful 💰",
        body: `Your payment of $${invoice.amount_paid / 100} has been processed.`,
        data: { screen: "subscription/invoices" },
      });
    } catch (error) {
      console.error("❌ Error handling invoice payment:", error);
    }
  }

  static async updateSubscriptionStatus(stripeSubscription) {
    await UserSubscription.update(
      {
        status: stripeSubscription.status,
        current_period_start: new Date(
          stripeSubscription.current_period_start * 1000,
        ),
        current_period_end: new Date(
          stripeSubscription.current_period_end * 1000,
        ),
        cancel_at_period_end: stripeSubscription.cancel_at_period_end,
      },
      { where: { stripe_subscription_id: stripeSubscription.id } },
    );
  }

  static async cancelSubscription(stripeSubscription) {
    const userSubscription = await UserSubscription.findOne({
      where: { stripe_subscription_id: stripeSubscription.id },
    });

    if (userSubscription) {
      await userSubscription.update({ status: "canceled" });

      await NotificationService.createNotification({
        userId: userSubscription.user_id,
        type: "subscription_canceled",
        title: "Subscription Canceled",
        body: "Your subscription has been canceled. You will be downgraded to the Free plan at the end of your billing period.",
        data: { screen: "subscription" },
      });
    }
  }

  static async recordSubscriptionPayment(stripeSubscription, invoice) {
    const userSubscription = await UserSubscription.findOne({
      where: { stripe_subscription_id: stripeSubscription.id },
      include: [{ model: User, include: [{ model: Wallet }] }],
    });

    if (!userSubscription) return;

    await Transaction.create({
      wallet_id: userSubscription.User.Wallet?.id,
      amount: invoice.amount_paid / 100,
      type: "subscription",
      status: "completed",
      description: `Subscription payment for ${userSubscription.SubscriptionPlan.name} plan`,
      reference_id: userSubscription.id,
      reference_type: "subscription",
      stripe_payment_intent_id: invoice.payment_intent,
      stripe_subscription_id: stripeSubscription.id,
      completed_at: new Date(),
    });
  }
}

export default SubscriptionService;
