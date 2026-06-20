import Stripe from "stripe";
import {
  Contract,
  Wallet,
  Transaction,
  User,
  Project,
} from "../models/index.js";
import NotificationService from "./notificationService.js";
import CouponService from "./CouponService.js";

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

class PaymentService {
  static _parseMilestones(raw) {
    if (!raw) return [];
    if (Array.isArray(raw)) return raw;
    if (typeof raw === "string") {
      try {
        const parsed = JSON.parse(raw);
        return Array.isArray(parsed) ? parsed : [];
      } catch {
        return [];
      }
    }
    return [];
  }
  static async createEscrowPaymentIntent(contractId, userId) {
    try {
      const contract = await Contract.findByPk(contractId, {
        include: [{ model: Project }],
      });

      if (!contract) {
        throw new Error("Contract not found");
      }

      if (contract.ClientId !== userId) {
        throw new Error("Only client can fund escrow");
      }

      const paymentIntent = await stripe.paymentIntents.create({
        amount: Math.round(contract.agreed_amount * 100),
        currency: "usd",
        metadata: {
          contractId: contract.id,
          type: "escrow",
          projectTitle: contract.Project?.title,
        },
        description: `Escrow for contract #${contract.id}`,
      });

      await contract.update({
        escrow_id: paymentIntent.id,
        escrow_status: "pending",
      });

      return {
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
        amount: contract.agreed_amount,
      };
    } catch (error) {
      console.error("Error creating escrow payment:", error);
      throw error;
    }
  }

  static async createCheckoutSession(contractId, userId, frontendUrl) {
    try {
      const contract = await Contract.findByPk(contractId, {
        include: [{ model: Project }],
      });

      if (!contract) {
        throw new Error("Contract not found");
      }

      if (contract.ClientId !== userId) {
        throw new Error("Only client can fund escrow");
      }

      console.log(
        "💰 Creating Stripe checkout session for amount:",
        contract.agreed_amount,
      );
      console.log("🔍 Frontend URL for redirects:", frontendUrl);

      const session = await stripe.checkout.sessions.create({
        payment_method_types: ["card"],
        line_items: [
          {
            price_data: {
              currency: "usd",
              product_data: {
                name: contract.Project?.title || "Project Payment",
                description: `Contract #${contract.id} - ${contract.Project?.description?.substring(0, 100)}`,
              },
              unit_amount: Math.round(contract.agreed_amount * 100),
            },
            quantity: 1,
          },
        ],
        mode: "payment",
        success_url: `${frontendUrl}/payment-success?session_id={CHECKOUT_SESSION_ID}&contract_id=${contract.id}`,
        cancel_url: `${frontendUrl}/payment-cancel?contract_id=${contract.id}`,
        metadata: {
          contractId: contract.id,
          type: "escrow",
        },
      });

      console.log("✅ Stripe checkout session created:", session.id);
      console.log("✅ Checkout URL:", session.url);

      await contract.update({
        escrow_id: session.id,
        escrow_status: "pending",
      });

      return {
        success: true,
        checkoutUrl: session.url,
        sessionId: session.id,
      };
    } catch (error) {
      console.error("Error creating checkout session:", error);
      throw error;
    }
  }

  static async handleCheckoutSuccess(sessionId) {
    try {
      console.log("🔄 Processing checkout session:", sessionId);

      const session = await stripe.checkout.sessions.retrieve(sessionId);
      console.log("✅ Session retrieved:", session.id);
      console.log("✅ Session metadata:", session.metadata);

      const contract = await Contract.findOne({
        where: { escrow_id: sessionId },
      });

      if (!contract) {
        console.log("❌ Contract not found for session:", sessionId);
        throw new Error("Contract not found");
      }

      console.log("✅ Contract found:", contract.id);
      console.log(
        "💰 Updating contract escrow_status from",
        contract.escrow_status,
        "to funded",
      );

      const paid =
        (session.amount_total != null
          ? session.amount_total
          : Math.round(parseFloat(contract.agreed_amount) * 100)) / 100;

      await contract.update({
        escrow_status: "funded",
        payment_status: "escrow",
        funded_escrow_amount: paid,
      });

      if (contract.coupon_code) {
        await CouponService.recordContractCouponUse(contract.coupon_code);
      }

      console.log("✅ Contract updated");

      let clientWallet = await Wallet.findOne({
        where: { UserId: contract.ClientId },
      });
      if (!clientWallet) {
        clientWallet = await Wallet.create({
          UserId: contract.ClientId,
          balance: 0,
        });
      }

      const newPendingBalance = (clientWallet.pending_balance || 0) + paid;
      await clientWallet.update({
        pending_balance: newPendingBalance,
      });
      console.log(
        "✅ Client wallet updated, pending_balance:",
        newPendingBalance,
      );

      const transaction = await Transaction.create({
        wallet_id: clientWallet.id,
        amount: paid,
        type: "deposit",
        status: "completed",
        description: `Escrow deposit for contract #${contract.id}`,
        reference_id: contract.id,
        reference_type: "contract",
        stripe_payment_intent_id: sessionId,
        completed_at: new Date(),
      });
      console.log("✅ Transaction created:", transaction.id);

      await NotificationService.createNotification({
        userId: contract.ClientId,
        type: "payment_received",
        title: "Payment Confirmed ✅",
        body: `$${paid.toFixed(2)} has been deposited into escrow for contract #${contract.id}.`,
        data: { contractId: contract.id, screen: "contract_progress" },
      });

      await NotificationService.createNotification({
        userId: contract.FreelancerId,
        type: "payment_received",
        title: "Payment Secured 💰",
        body: `The client has funded $${paid.toFixed(2)} into escrow. You can now start working!`,
        data: { contractId: contract.id, screen: "contract_progress" },
      });

      console.log("✅ Notifications sent");

      return { success: true, contract };
    } catch (error) {
      console.error("❌ Error handling checkout success:", error);
      throw error;
    }
  }

  static async handlePaymentSuccess(paymentIntentId) {
    try {
      const paymentIntent =
        await stripe.paymentIntents.retrieve(paymentIntentId);

      const contract = await Contract.findOne({
        where: { escrow_id: paymentIntentId },
      });

      if (!contract) {
        throw new Error("Contract not found");
      }

      const pi = await stripe.paymentIntents.retrieve(paymentIntentId);
      const paid =
        (pi.amount_received != null ? pi.amount_received : pi.amount) / 100;

      await contract.update({
        escrow_status: "funded",
        payment_status: "escrow",
        funded_escrow_amount: paid,
      });

      if (contract.coupon_code) {
        await CouponService.recordContractCouponUse(contract.coupon_code);
      }

      let clientWallet = await Wallet.findOne({
        where: { UserId: contract.ClientId },
      });
      if (!clientWallet) {
        clientWallet = await Wallet.create({
          UserId: contract.ClientId,
          balance: 0,
        });
      }
      await clientWallet.update({
        pending_balance: clientWallet.pending_balance + paid,
      });

      await Transaction.create({
        wallet_id: clientWallet.id,
        amount: paid,
        type: "deposit",
        status: "completed",
        description: `Escrow deposit for contract #${contract.id}`,
        reference_id: contract.id,
        reference_type: "contract",
        stripe_payment_intent_id: paymentIntentId,
        completed_at: new Date(),
      });

      await NotificationService.createNotification({
        userId: contract.ClientId,
        type: "payment_received",
        title: "Payment Confirmed",
        body: `$${paid.toFixed(2)} has been deposited into escrow for contract #${contract.id}`,
        data: { contractId: contract.id, screen: "contract_progress" },
      });

      await NotificationService.createNotification({
        userId: contract.FreelancerId,
        type: "payment_received",
        title: "Payment Secured",
        body: `The client has funded $${paid.toFixed(2)} into escrow. You can now start working.`,
        data: { contractId: contract.id, screen: "contract_progress" },
      });

      return { success: true, contract };
    } catch (error) {
      console.error("Error handling payment success:", error);
      throw error;
    }
  }

  static async releaseMilestonePayment(contractId, milestoneIndex, clientId) {
    try {
      const contract = await Contract.findByPk(contractId);

      if (!contract) {
        throw new Error("Contract not found");
      }

      if (contract.ClientId !== clientId) {
        throw new Error("Only client can release milestone payments");
      }

      const milestones = this._parseMilestones(contract.milestones);
      const milestone = milestones[milestoneIndex];

      if (!milestone) {
        throw new Error("Milestone not found");
      }

      if (milestone.status === "approved") {
        throw new Error("Milestone already approved");
      }

      if (milestone.status !== "completed") {
        throw new Error("Milestone not completed yet");
      }

      const pool =
        contract.funded_escrow_amount != null
          ? parseFloat(contract.funded_escrow_amount)
          : parseFloat(contract.agreed_amount);
      const alreadyReleased = parseFloat(contract.released_amount || 0);
      const milestoneAmt = parseFloat(milestone.amount || 0);
      //if (alreadyReleased + milestoneAmt > pool + 0.01) {
       // throw new Error(
         // "Release would exceed the contract amount. Adjust milestones or funding.",
        //);
      //}

      milestone.status = "approved";
      milestone.approved_at = new Date();
      milestones[milestoneIndex] = milestone;

      await contract.update({
        milestones: JSON.stringify(milestones),
        released_amount:
          parseFloat(contract.released_amount || 0) + milestoneAmt,
      });

      let freelancerWallet = await Wallet.findOne({
        where: { UserId: contract.FreelancerId },
      });
      if (!freelancerWallet) {
        freelancerWallet = await Wallet.create({
          UserId: contract.FreelancerId,
          balance: 0,
        });
      }

      await freelancerWallet.update({
        balance: parseFloat(freelancerWallet.balance || 0) + milestoneAmt,
        total_earned:
          parseFloat(freelancerWallet.total_earned || 0) + milestoneAmt,
      });

      let clientWallet = await Wallet.findOne({
        where: { UserId: contract.ClientId },
      });
      if (!clientWallet) {
        clientWallet = await Wallet.create({
          UserId: contract.ClientId,
          balance: 0,
          pending_balance: 0,
          total_earned: 0,
          total_withdrawn: 0,
        });
      }

      const currentPending = parseFloat(clientWallet.pending_balance || 0);
      await clientWallet.update({
        pending_balance: Math.max(0, currentPending - milestoneAmt),
      });

      await Transaction.create({
        wallet_id: freelancerWallet.id,
        amount: milestoneAmt,
        type: "payment",
        status: "completed",
        description: `Payment for milestone "${milestone.title}" - Contract #${contract.id}`,
        reference_id: contract.id,
        reference_type: "contract",
        completed_at: new Date(),
      });

      await NotificationService.createNotification({
        userId: contract.FreelancerId,
        type: "payment_received",
        title: "Milestone Payment Released! 💰",
        body: `$${milestoneAmt} has been added to your wallet for "${milestone.title}"`,
        data: { contractId: contract.id, screen: "contract" },
      });

      const allApproved = milestones.every((m) => m.status === "approved");
      if (allApproved) {
        await contract.update({
          escrow_status: "released",
          payment_status: "paid",
          status: "completed",
        });

        await NotificationService.createNotification({
          userId: contract.FreelancerId,
          type: "project_completed",
          title: "Project Completed! 🎉",
          body: `All milestones have been approved. Project is complete.`,
          data: { contractId: contract.id, screen: "contract" },
        });
      }

      return { success: true, contract, milestone };
    } catch (error) {
      console.error("Error releasing milestone payment:", error);
      throw error;
    }
  }

  static async requestWithdrawal(userId, amount) {
    try {
      const wallet = await Wallet.findOne({ where: { UserId: userId } });

      if (!wallet) {
        throw new Error("Wallet not found");
      }

      if (wallet.balance < amount) {
        throw new Error("Insufficient balance");
      }

      if (!wallet.stripe_account_id) {
        const accountLink = await stripe.accountLinks.create({
          account: await this.createStripeConnectAccount(userId),
          refresh_url: `${process.env.FRONTEND_URL}/wallet`,
          return_url: `${process.env.FRONTEND_URL}/wallet/complete`,
          type: "account_onboarding",
        });

        return {
          requiresOnboarding: true,
          accountLinkUrl: accountLink.url,
        };
      }

      const payout = await stripe.payouts.create({
        amount: Math.round(amount * 100),
        currency: "usd",
        destination: wallet.stripe_account_id,
      });

      await wallet.update({
        balance: wallet.balance - amount,
        total_withdrawn: wallet.total_withdrawn + amount,
      });

      await Transaction.create({
        wallet_id: wallet.id,
        amount: -amount,
        type: "withdraw",
        status: "pending",
        description: `Withdrawal request for $${amount}`,
        stripe_payment_intent_id: payout.id,
      });

      await NotificationService.createNotification({
        userId: userId,
        type: "withdrawal",
        title: "Withdrawal Requested",
        body: `Your withdrawal request for $${amount} is being processed.`,
        data: { screen: "wallet" },
      });

      return { success: true, payout };
    } catch (error) {
      console.error("Error requesting withdrawal:", error);
      throw error;
    }
  }

  static async createStripeConnectAccount(userId) {
    const user = await User.findByPk(userId);

    const account = await stripe.accounts.create({
      type: "express",
      country: "US",
      email: user.email,
      metadata: { userId: userId },
    });

    await Wallet.update(
      { stripe_account_id: account.id },
      { where: { UserId: userId } },
    );

    return account.id;
  }
}

export default PaymentService;
