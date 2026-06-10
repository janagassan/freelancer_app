import SubscriptionService from "../services/subscriptionService.js";
import { UserSubscription } from "../models/index.js";
import { SubscriptionPlan } from "../models/index.js";
import stripe from "../config/stripe.js";
import PaymentService from "../services/paymentService.js";
import NotificationService from "../services/notificationService.js";

export const getPlans = async (req, res) => {
  try {
    const plans = await SubscriptionService.getPlans();
    res.json({ success: true, plans });
  } catch (error) {
    console.error("Error fetching plans:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const getUserSubscription = async (req, res) => {
  try {
    const subscription = await SubscriptionService.getUserSubscription(
      req.user.id,
    );
    res.json({ success: true, subscription });
  } catch (error) {
    console.error("Error fetching subscription:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const createCheckoutSession = async (req, res) => {
  try {
    const { planSlug } = req.body;
    const frontendUrl = process.env.FRONTEND_URL || "http://localhost:5000";

    const { sessionId, checkoutUrl } =
      await SubscriptionService.createCheckoutSession(
        req.user.id,
        planSlug,
        `${frontendUrl}/subscription/success?session_id={CHECKOUT_SESSION_ID}`,
        `${frontendUrl}/subscription/cancel`,
      );

    res.json({ success: true, checkoutUrl, sessionId });
  } catch (error) {
    console.error("Error creating checkout session:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const createSubscriptionPaymentIntent = async (req, res) => {
  try {
    const { planSlug } = req.body;

    const paymentIntent =
      await SubscriptionService.createSubscriptionPaymentIntent(
        planSlug,
        req.user.id,
      );

    res.json({
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
      amount: paymentIntent.amount / 100,
    });
  } catch (error) {
    console.error("Error creating subscription payment intent:", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

export const confirmSubscriptionPayment = async (req, res) => {
  try {
    const { planSlug, paymentIntentId } = req.body;

    const subscription = await SubscriptionService.confirmSubscriptionPayment(
      planSlug,
      paymentIntentId,
      req.user.id,
    );

    res.json({
      message: "Subscription payment confirmed successfully!",
      subscription,
    });
  } catch (error) {
    console.error("Error confirming subscription payment:", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

export const createSubscriptionCheckoutSession = async (req, res) => {
  try {
    const { planSlug } = req.body;
    const frontendUrl = process.env.FRONTEND_URL || "http://localhost:58940";

    const result = await SubscriptionService.createSubscriptionCheckoutSession(
      planSlug,
      req.user.id,
      frontendUrl,
    );

    res.json(result);
  } catch (error) {
    console.error("Error creating subscription checkout session:", error);
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

export const confirmCheckoutSession = async (req, res) => {
  try {
    console.log("🔐 ===== CONFIRM CHECKOUT SESSION =====");
    const { session_id } = req.body;
    const userId = req.user.id;

    if (!session_id) {
      return res.status(400).json({ success: false, message: "Session ID is required" });
    }

    const session = await stripe.checkout.sessions.retrieve(session_id);
    
    console.log("🔍 Session payment_status:", session.payment_status);
    
    if (session.payment_status !== "paid") {
      return res.json({ success: false, message: "Payment not completed" });
    }

    const { planSlug } = session.metadata;
    
    const plan = await SubscriptionPlan.findOne({
      where: { slug: planSlug, is_active: true },
    });

    if (!plan) {
      return res.status(404).json({ success: false, message: "Plan not found" });
    }

    await UserSubscription.update(
      { status: "canceled" },
      { where: { user_id: userId, status: "active" } },
    );

    const subscription = await UserSubscription.create({
      user_id: userId,
      plan_id: plan.id,
      status: "active",
      stripe_subscription_id: session.subscription || session.id,
      stripe_customer_id: session.customer,
      current_period_start: new Date(),
      current_period_end: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      trial_end: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
    });

    await User.update(
      {
        proposal_count_this_month: 0,
        proposal_reset_date: new Date(),
      },
      { where: { id: userId } },
    );

    console.log("✅ Subscription activated:", subscription.id);

    res.json({
      success: true,
      message: "Subscription activated successfully",
      subscription: {
        id: subscription.id,
        plan: {
          id: plan.id,
          name: plan.name,
          slug: plan.slug,
          price: plan.price,
        },
      },
    });
  } catch (error) {
    console.error("❌ Error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};



export const manualConfirmSubscriptionPayment = async (req, res) => {
  try {
    const { planSlug } = req.body;

    const subscription =
      await SubscriptionService.manualConfirmSubscriptionPayment(
        planSlug,
        req.user.id,
      );

    res.json({
      success: true,
      message: "Subscription payment confirmed manually!",
      subscription,
    });
  } catch (error) {
    console.error("Error in manualConfirmSubscriptionPayment:", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

export const cancelSubscription = async (req, res) => {
  try {
    const userId = req.user.id;

    const subscription = await UserSubscription.findOne({
      where: {
        user_id: userId,
        status: ["active", "trialing"],
      },
      include: [
        {
          model: SubscriptionPlan,
        },
      ],
    });

    if (!subscription) {
      return res
        .status(404)
        .json({ success: false, message: "No active subscription found" });
    }

    if (
      subscription.stripe_subscription_id &&
      subscription.stripe_subscription_id.startsWith("sub_")
    ) {
      try {
        await stripe.subscriptions.update(subscription.stripe_subscription_id, {
          cancel_at_period_end: true,
        });
        console.log("✅ Stripe subscription marked for cancellation");
      } catch (stripeError) {
        console.log(
          "⚠️ Could not cancel Stripe subscription:",
          stripeError.message,
        );
      }
    } else {
      console.log("📝 Manual subscription, no Stripe cancellation needed");
    }

    await subscription.update({
      cancel_at_period_end: true,
      status: "canceled",
    });

    await NotificationService.createNotification({
      userId: userId,
      type: "subscription_canceled",
      title: "Subscription Canceled",
      body: "Your subscription has been canceled. You will be downgraded to the Free plan at the end of your billing period.",
      data: { screen: "subscription/my" },
    }).catch((e) => console.log("⚠️ Notification error:", e.message));

    res.json({
      success: true,
      message:
        "Subscription will be canceled at the end of the billing period.",
    });
  } catch (error) {
    console.error("Error canceling subscription:", error);
    res
      .status(500)
      .json({ success: false, message: "Server error: " + error.message });
  }
};
