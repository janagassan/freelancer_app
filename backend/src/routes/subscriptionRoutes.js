// backend/src/routes/subscriptionRoutes.js
import express from "express";
import { protect } from "../middleware/authMiddleware.js";
import CouponService from "../services/CouponService.js";
import {
  getPlans,
  getUserSubscription,
  createCheckoutSession,
  cancelSubscription,
  createSubscriptionPaymentIntent,
  confirmSubscriptionPayment,
  createSubscriptionCheckoutSession,
  manualConfirmSubscriptionPayment,
  confirmCheckoutSession,
} from "../controllers/subscriptionController.js";

const router = express.Router();

router.get("/plans", protect, getPlans);
router.get("/me", protect, getUserSubscription);
router.post("/checkout", protect, createCheckoutSession);
router.post("/cancel", protect, cancelSubscription);

router.post("/payment-intent", protect, createSubscriptionPaymentIntent);
router.post("/confirm-payment", protect, confirmSubscriptionPayment);
router.post("/checkout-session", protect, createSubscriptionCheckoutSession);
router.post("/manual-confirm", protect, manualConfirmSubscriptionPayment);
router.post("/confirm-checkout", protect, confirmCheckoutSession);

router.post("/validate-coupon", protect, async (req, res) => {
  try {
    const { code, planSlug, scope } = req.body;
    const context = scope === "contract" ? "contract" : "subscription";
    const result = await CouponService.validateCoupon(code, planSlug, context);
    res.json(result);
  } catch (error) {
    console.error("Error validating coupon:", error);
    res.status(500).json({ valid: false, message: "Server error" });
  }
});

router.get('/monthly-usage', protect, async (req, res) => {
  try {
    const userId = req.user.id;
    
    const monthlyUsage = await db.query(`
      SELECT 
        DATE_FORMAT(created_at, '%b') as month,
        COUNT(CASE WHEN type = 'proposal' THEN 1 END) as proposals,
        COUNT(CASE WHEN type = 'project' THEN 1 END) as projects
      FROM user_activities
      WHERE user_id = ? 
        AND created_at >= DATE_SUB(NOW(), INTERVAL 6 MONTH)
      GROUP BY DATE_FORMAT(created_at, '%Y-%m')
      ORDER BY created_at ASC
    `, [userId]);
    
    res.json({
      success: true,
      data: monthlyUsage
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});
export default router;
