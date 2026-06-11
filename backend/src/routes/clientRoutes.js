// routes/clientRoutes.js
import express from "express";
import { protect, authorizeRoles } from "../middleware/authMiddleware.js";
import {
  getDashboardStats,
  getMyProjects,
  getProjectById,
  createProject,
  updateProject,
  deleteProject,
  getProjectProposals,
  updateProposalStatus,
  getProjectContract,
  getMyContracts,
  completeProject,
  startNegotiation,
  updateNegotiation,
  acceptProposalWithNegotiation,
  confirmPayment,
  releaseMilestone,
  requestWithdrawal,
  getWallet,
  createCheckoutSession,
  handlePaymentSuccess,
  createDirectPayment,
  manualConfirmPayment,
  getClientDashboardOverview,
  getClientProfile,
  createContractFromProposalDirect,
  createWallet,
  sendOfferToFreelancer,
  getOpenProjectsForHiring,
  getContractByProjectId

} from "../controllers/clientController.js";

const router = express.Router();

router.use(protect);
router.use(authorizeRoles("client"));

router.get("/dashboard/stats", getDashboardStats);
router.get(
  "/projects/open",
  protect,
  authorizeRoles("client"),
  getOpenProjectsForHiring,
);

router.get("/projects", getMyProjects);
router.post("/projects", createProject);
router.get("/projects/:id", getProjectById);
router.put("/projects/:id", updateProject);
router.delete("/projects/:id", deleteProject);
router.put("/projects/:projectId/complete", completeProject);

router.get("/projects/:projectId/proposals", getProjectProposals);
router.put("/proposals/:id", updateProposalStatus);

router.post("/proposals/:proposalId/negotiate", startNegotiation);
router.put("/proposals/:proposalId/negotiate", updateNegotiation);
router.post("/proposals/:proposalId/accept", acceptProposalWithNegotiation);

router.get("/projects/:projectId/contract", getProjectContract);
router.get("/contracts", getMyContracts);

router.post("/contracts/:contractId/confirm-payment", confirmPayment);
router.post(
  "/contracts/:contractId/milestones/:milestoneIndex/release",
  releaseMilestone,
);

router.get("/wallet", getWallet);
router.post("/wallet/withdraw", requestWithdrawal);
router.post("/wallet/create", createWallet);
router.get('/contract/by-project/:projectId', protect, authorizeRoles("client"), getContractByProjectId);

router.post("/contracts/:contractId/create-checkout", createCheckoutSession);
router.get("/payment/success", handlePaymentSuccess);
router.get("/payment/cancel", (req, res) => {
  res.redirect(
    `${process.env.FRONTEND_URL}/contract/${req.query.contract_id}?payment=cancelled`,
  );
});
router.post(
  "/contracts/:contractId/create-direct-payment",
  createDirectPayment,
);

router.post(
  "/contracts/:contractId/manual-confirm",
  protect,
  authorizeRoles("client"),
  manualConfirmPayment,
);
router.get("/dashboard/overview", getClientDashboardOverview);
router.get("/profile", getClientProfile);
router.post(
  "/contracts/create-from-proposal",
  protect,
  authorizeRoles("client"),
  createContractFromProposalDirect,
);

router.post(
  "/offers/send",
  protect,
  authorizeRoles("client"),
  sendOfferToFreelancer,
);

export default router;
