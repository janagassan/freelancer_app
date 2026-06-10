// backend/src/routes/stripeWebhookRoutes.js

import express from "express";
import stripe from "../config/stripe.js";
import PaymentService from "../services/paymentService.js";
import SubscriptionService from "../services/subscriptionService.js";
import { User, SubscriptionPlan, UserSubscription } from "../models/index.js";
import NotificationService from "../services/notificationService.js";

const router = express.Router();

router.post(
  "/webhook",
  express.raw({ type: "application/json" }),
  async (req, res) => {
    const sig = req.headers["stripe-signature"];
    let event;

    console.log("🔔 Webhook received");
    console.log("🔔 Signature:", sig ? "Present" : "Missing");

    try {
      event = stripe.webhooks.constructEvent(
        req.body,
        sig,
        process.env.STRIPE_WEBHOOK_SECRET,
      );
      console.log("✅ Webhook verified, event type:", event.type);
    } catch (err) {
      console.log(`⚠️ Webhook signature verification failed.`, err.message);
      return res.status(400).send(`Webhook Error: ${err.message}`);
    }

    try {
      switch (event.type) {
        case "checkout.session.completed":
          await handleCheckoutSessionCompleted(event.data.object);
          break;

        case "customer.subscription.created":
          console.log("🆕 Subscription created");
          await handleSubscriptionCreated(event.data.object);
          break;

        case "customer.subscription.updated":
          console.log("🔄 Subscription updated");
          await handleSubscriptionUpdated(event.data.object);
          break;

        case "customer.subscription.deleted":
          console.log("🗑️ Subscription deleted");
          await handleSubscriptionDeleted(event.data.object);
          break;

        case "invoice.payment_succeeded":
          console.log("💵 Invoice payment succeeded");
          await handleInvoicePaymentSucceeded(event.data.object);
          break;

        case "invoice.payment_failed":
          console.log("❌ Invoice payment failed");
          await handleInvoicePaymentFailed(event.data.object);
          break;

        case "payment_intent.succeeded":
          await handlePaymentIntentSucceeded(event.data.object);
          break;

        default:
          console.log(`📝 Unhandled event type: ${event.type}`);
      }
    } catch (err) {
      console.error("❌ Error processing webhook:", err);
    }

    res.json({ received: true });
  },
);


async function handleCheckoutSessionCompleted(session) {
  console.log("💰 Checkout session completed:", session.id);
  console.log("🔍 Session mode:", session.mode);
  console.log("🔍 Session metadata:", session.metadata);
  console.log("🔍 Session subscription:", session.subscription);
  console.log("🔍 Session payment_status:", session.payment_status);

  if (session.payment_status !== "paid") {
    console.log("⚠️ Payment not completed, skipping");
    return;
  }

  if (session.mode === "subscription" || session.metadata?.type === "subscription") {
    console.log("🎯 Processing subscription checkout");
    
    const { planSlug, userId } = session.metadata;
    
    if (!planSlug || !userId) {
      console.log("❌ Missing planSlug or userId in metadata");
      return;
    }

    const plan = await SubscriptionPlan.findOne({
      where: { slug: planSlug, is_active: true },
    });

    if (!plan) {
      console.log("❌ Plan not found:", planSlug);
      return;
    }

    console.log("📋 Found plan:", plan.name);

    await UserSubscription.update(
      { status: "canceled" },
      { where: { user_id: userId, status: "active" } },
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
  } 
  else if (session.mode === "payment") {
    console.log("💰 Processing one-time payment checkout");
    await PaymentService.handleCheckoutSuccess(session.id);
  }
}

async function handleSubscriptionCreated(subscription) {
  console.log("🆕 Subscription created:", subscription.id);
  console.log("🔍 Subscription status:", subscription.status);
  console.log("🔍 Customer:", subscription.customer);
  console.log("🔍 Metadata:", subscription.metadata);
}

async function handleSubscriptionUpdated(subscription) {
  console.log("🔄 Subscription updated:", subscription.id);
  console.log("🔍 New status:", subscription.status);
  console.log("🔍 Cancel at period end:", subscription.cancel_at_period_end);

  await UserSubscription.update(
    {
      status: subscription.status,
      current_period_start: new Date(subscription.current_period_start * 1000),
      current_period_end: new Date(subscription.current_period_end * 1000),
      cancel_at_period_end: subscription.cancel_at_period_end,
    },
    { where: { stripe_subscription_id: subscription.id } },
  );

  console.log("✅ Subscription status updated in database");
}

async function handleSubscriptionDeleted(subscription) {
  console.log("🗑️ Subscription deleted:", subscription.id);

  await UserSubscription.update(
    { status: "canceled" },
    { where: { stripe_subscription_id: subscription.id } },
  );

  const userSub = await UserSubscription.findOne({
    where: { stripe_subscription_id: subscription.id },
  });

  if (userSub) {
    await NotificationService.createNotification({
      userId: userSub.user_id,
      type: "subscription_canceled",
      title: "Subscription Canceled",
      body: "Your subscription has been canceled.",
      data: { screen: "subscription/my" },
    });
  }

  console.log("✅ Subscription marked as canceled");
}

async function handleInvoicePaymentSucceeded(invoice) {
  console.log("💵 Invoice payment succeeded:", invoice.id);
  console.log("🔍 Subscription:", invoice.subscription);
  console.log("🔍 Amount paid:", invoice.amount_paid / 100);

  if (invoice.subscription) {
    const subscription = await stripe.subscriptions.retrieve(invoice.subscription);
    
    await UserSubscription.update(
      {
        status: subscription.status,
        current_period_start: new Date(subscription.current_period_start * 1000),
        current_period_end: new Date(subscription.current_period_end * 1000),
      },
      { where: { stripe_subscription_id: invoice.subscription } },
    );

    console.log("✅ Subscription period updated");
  }
}

async function handleInvoicePaymentFailed(invoice) {
  console.log("❌ Invoice payment failed:", invoice.id);
  console.log("🔍 Subscription:", invoice.subscription);

  const userSub = await UserSubscription.findOne({
    where: { stripe_subscription_id: invoice.subscription },
  });

  if (userSub) {
    await NotificationService.createNotification({
      userId: userSub.user_id,
      type: "payment_failed",
      title: "Payment Failed ❌",
      body: `Your payment of $${invoice.amount_due / 100} failed. Please update your payment method.`,
      data: { screen: "subscription/my" },
    });
  }

  console.log("✅ Payment failure notification sent");
}

async function handlePaymentIntentSucceeded(paymentIntent) {
  console.log("💰 PaymentIntent succeeded:", paymentIntent.id);
  console.log("🔍 PaymentIntent metadata:", paymentIntent.metadata);

  if (paymentIntent.metadata && paymentIntent.metadata.type === "subscription") {
    console.log("🎯 Processing subscription payment intent");
    const userId = parseInt(paymentIntent.metadata.userId);
    const planSlug = paymentIntent.metadata.planSlug;

    console.log("👤 UserId:", userId);
    console.log("📋 PlanSlug:", planSlug);

    const plan = await SubscriptionPlan.findOne({
      where: { slug: planSlug, is_active: true },
    });

    if (!plan) {
      console.log("❌ Plan not found:", planSlug);
      return;
    }

    await UserSubscription.update(
      { status: "canceled" },
      { where: { user_id: userId, status: "active" } },
    );

    const subscription = await UserSubscription.create({
      user_id: userId,
      plan_id: plan.id,
      status: "active",
      stripe_subscription_id: paymentIntent.id,
      current_period_start: new Date(),
      current_period_end: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      trial_end: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
    });

    console.log("✅ Subscription created via PaymentIntent:", subscription.id);

    await User.update(
      {
        proposal_count_this_month: 0,
        proposal_reset_date: new Date(),
      },
      { where: { id: userId } },
    );

    console.log("✅ User counters reset");
  } else {
    console.log("💰 Processing contract payment intent");
    await PaymentService.handlePaymentSuccess(paymentIntent.id);
  }
}

export default router;