// routes/contractRoutes.js
import express from "express";
import { protect } from "../middleware/authMiddleware.js";
import { Contract, Project, User } from "../models/index.js";
import ESignatureService from "../services/esignatureService.js";
import NotificationService from "../services/notificationService.js";
import {
  getContractProgress,
  applyContractCoupon,
  removeContractCoupon,
  requestMilestoneRevision,
} from "../controllers/contractWorkspaceController.js";

const router = express.Router();
 router.post('/contracts/:contractId/milestones/:milestoneIndex/request-revision', protect, requestMilestoneRevision);
router.get("/project/:projectId", protect, async (req, res) => {
  try {
    console.log(
      `📥 Fetching contract for project ${req.params.projectId} for user ${req.user.id}`,
    );

    const contract = await Contract.findOne({
      where: { ProjectId: req.params.projectId },
      include: [
        {
          model: Project,
          include: [
            {
              model: User,
              as: "client",
              attributes: ["id", "name", "avatar"],
            },
          ],
        },
        {
          model: User,
          as: "freelancer",
          attributes: ["id", "name", "avatar"],
        },
        {
          model: User,
          as: "client",
          attributes: ["id", "name", "avatar"],
        },
      ],
    });

    if (!contract) {
      return res.json({ success: false, message: "No contract found for this project" });
    }

    if (
      contract.ClientId !== req.user.id &&
      contract.FreelancerId !== req.user.id
    ) {
      return res.status(403).json({ success: false, message: "Unauthorized" });
    }

    res.json({ success: true, contract });
  } catch (error) {
    console.error("❌ Error in getContractByProjectId:", error);
    res.status(500).json({ success: false, message: "Server error", error: error.message });
  }
});

router.get("/:contractId/progress", protect, getContractProgress);
router.post("/:contractId/coupon", protect, applyContractCoupon);
router.delete("/:contractId/coupon", protect, removeContractCoupon);

router.get("/:contractId", protect, async (req, res) => {
  try {
    console.log(
      `📥 Fetching contract ${req.params.contractId} for user ${req.user.id}`,
    );

    const contract = await Contract.findByPk(req.params.contractId, {
      include: [
        {
          model: Project,
          include: [
            {
              model: User,
              as: "client",
              attributes: ["id", "name", "avatar"],
            },
          ],
        },
        {
          model: User,
          as: "freelancer",
          attributes: ["id", "name", "avatar"],
        },
        {
          model: User,
          as: "client",
          attributes: ["id", "name", "avatar"],
        },
      ],
    });

    if (!contract) {
      return res.status(404).json({ message: "Contract not found" });
    }

    if (
      contract.ClientId !== req.user.id &&
      contract.FreelancerId !== req.user.id
    ) {
      return res.status(403).json({ message: "Unauthorized" });
    }

    res.json(contract);
  } catch (error) {
    console.error("❌ Error in getContract:", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

router.post("/:contractId/sign", protect, async (req, res) => {
  try {
    console.log(
      `📝 Signing contract ${req.params.contractId} for user ${req.user.id}`,
    );

    const contract = await Contract.findByPk(req.params.contractId);

    if (!contract) {
      return res.status(404).json({ message: "Contract not found" });
    }

    let updatedContract;

    if (contract.ClientId === req.user.id) {
      await contract.update({
        client_signed_at: new Date(),
        status: contract.freelancer_signed_at ? "active" : "pending_freelancer",
      });
    } else if (contract.FreelancerId === req.user.id) {
      await contract.update({
        freelancer_signed_at: new Date(),
        status: contract.client_signed_at ? "active" : "pending_client",
      });
    } else {
      return res.status(403).json({ message: "Unauthorized" });
    }

    if (contract.client_signed_at && contract.freelancer_signed_at) {
      await contract.update({
        signed_at: new Date(),
        status: "active",
      });

      await Project.update(
        { status: "in_progress" },
        { where: { id: contract.ProjectId } },
      );
    }

    res.json({
      message: "Contract signed successfully",
      contract,
    });
  } catch (error) {
    console.error("❌ Error signing contract:", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

router.post("/:contractId/request-code", protect, async (req, res) => {
  try {
    console.log(
      `📱 Requesting verification code for contract ${req.params.contractId}`,
    );

    const contract = await Contract.findByPk(req.params.contractId);

    if (!contract) {
      return res.status(404).json({ message: "Contract not found" });
    }

    if (
      contract.ClientId !== req.user.id &&
      contract.FreelancerId !== req.user.id
    ) {
      return res.status(403).json({ message: "Unauthorized" });
    }

    const user = await User.findByPk(req.user.id);

    const result = await ESignatureService.sendVerificationCodes(
      user,
      contract,
    );

    res.json({
      success: true,
      message: "تم إرسال رمز التحقق إلى بريدك الإلكتروني",
      ...result,
    });
  } catch (error) {
    console.error("❌ Error requesting code:", error);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
});

router.post("/:contractId/verify-and-sign", protect, async (req, res) => {
  try {
    const { code } = req.body;

    console.log(`🔐 Verifying code for contract ${req.params.contractId}`);

    const result = await ESignatureService.verifyAndSign(
      req.params.contractId,
      req.user.id,
      code,
    );

    if (!result.success) {
      return res.status(400).json(result);
    }

    if (result.contract) {
      const contract = result.contract;

      const otherPartyId =
        contract.ClientId === req.user.id
          ? contract.FreelancerId
          : contract.ClientId;

      const user = await User.findByPk(req.user.id);

      await NotificationService.createNotification({
        userId: otherPartyId,
        type: "contract_signed",
        title: "Contract Signed",
        body: `${user.name} has signed the contract`,
        data: {
          contractId: contract.id,
          screen: "contract",
        },
      });

      if (contract.client_signed_at && contract.freelancer_signed_at) {
        await NotificationService.createNotification({
          userId: contract.ClientId,
          type: "contract_created",
          title: "Contract Active",
          body: "The contract is now active. You can start working!",
          data: {
            contractId: contract.id,
            screen: "contract",
          },
        });

        await NotificationService.createNotification({
          userId: contract.FreelancerId,
          type: "contract_created",
          title: "Contract Active",
          body: "The contract is now active. Start working on the project!",
          data: {
            contractId: contract.id,
            screen: "contract",
          },
        });
      }
    }

    res.json(result);
  } catch (error) {
    console.error("❌ Error verifying code:", error);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
});

import PDFGenerator from "../utils/pdfGenerator.js";

router.post("/:contractId/generate-pdf", protect, async (req, res) => {
  try {
    const { contractId } = req.params;
    const { sowData } = req.body;

    const contract = await Contract.findByPk(contractId, {
      include: [
        { model: Project },
        { model: User, as: "client" },
        { model: User, as: "freelancer" },
      ],
    });

    if (!contract) {
      return res
        .status(404)
        .json({ success: false, message: "Contract not found" });
    }

    const pdfData = {
      sowNumber: sowData["sowNumber"] || `SOW-${contract.id}`,
      clientName: contract.client?.name,
      clientEmail: contract.client?.email,
      freelancerName: contract.freelancer?.name,
      freelancerEmail: contract.freelancer?.email,
      projectTitle: contract.Project?.title,
      projectDescription: contract.Project?.description,
      projectCategory: contract.Project?.category,
      agreedAmount: contract.agreed_amount,
      skills: contract.Project?.skills
        ? JSON.parse(contract.Project.skills)
        : [],
      milestones: contract.milestones ? JSON.parse(contract.milestones) : [],
      additionalTerms: sowData["additionalTerms"],
      marketInsights: sowData["marketInsights"],
      difficultyLevel: sowData["difficultyLevel"],
    };

    const pdfUrl = await PDFGenerator.generateSOWPDF(pdfData);

    await contract.update({ contract_pdf_url: pdfUrl });

    res.json({
      success: true,
      pdfUrl: pdfUrl,
    });
  } catch (error) {
    console.error("Error generating PDF:", error);
    res.status(500).json({ success: false, message: error.message });
  }
});

router.put("/:contractId/update-sow", protect, async (req, res) => {
  try {
    const { contractId } = req.params;
    const { sowHtml, sowAnalysis } = req.body;

    const contract = await Contract.findByPk(contractId);

    if (!contract) {
      return res
        .status(404)
        .json({ success: false, message: "Contract not found" });
    }

    await contract.update({
      contract_document: sowHtml,
      ai_analysis: JSON.stringify(sowAnalysis),
      terms: "AI-generated SOW document",
    });

    console.log("✅ Contract updated with SOW:", contractId);

    res.json({
      success: true,
      message: "SOW saved to contract",
    });
  } catch (error) {
    console.error("Error updating contract with SOW:", error);
    res.status(500).json({ success: false, message: error.message });
  }
});

export default router;
