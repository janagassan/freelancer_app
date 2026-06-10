// routes/disputeRoutes.js
import express from "express";
import { protect } from "../middleware/authMiddleware.js";
import {
  createDispute,
  getUserDisputes,
  getUserDisputeDetails,
} from "../controllers/disputeController.js";

const router = express.Router();

router.use(protect);
router.get("/my", getUserDisputes); 

router.post("/", createDispute);
router.get("/", getUserDisputes);
router.get("/:disputeId", getUserDisputeDetails);

export default router;