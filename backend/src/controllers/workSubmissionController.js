// ===== backend/src/controllers/workSubmissionController.js =====
import {
  WorkSubmission,
  Contract,
  Project,
  User,
  Notification,
  FreelancerProfile,
} from "../models/index.js";
import { Op } from "sequelize";
import NotificationService from "../services/notificationService.js";

import multer from "multer";
import path from "path";
import fs from "fs";

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const dir = "uploads/work-submissions";
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    const ext = path.extname(file.originalname);
    cb(null, `work-${req.user.id}-${uniqueSuffix}${ext}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowedTypes = /pdf|doc|docx|zip|rar|jpg|jpeg|png|gif|mp4|mov|avi/;
    const extname = allowedTypes.test(
      path.extname(file.originalname).toLowerCase(),
    );
    const mimetype = allowedTypes.test(file.mimetype);
    if (mimetype && extname) {
      return cb(null, true);
    }
    cb(new Error("Only images, documents, and videos are allowed"));
  },
}).single("file");

export const uploadWorkFile = async (req, res) => {
  try {
    upload(req, res, async (err) => {
      if (err) {
        return res.status(400).json({ success: false, message: err.message });
      }

      if (!req.file) {
        return res
          .status(400)
          .json({ success: false, message: "No file uploaded" });
      }

      const fileUrl = `/uploads/work-submissions/${req.file.filename}`;

      res.json({
        success: true,
        url: fileUrl,
        filename: req.file.filename,
        size: req.file.size,
      });
    });
  } catch (err) {
    console.error("Error uploading file:", err);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: err.message });
  }
};

const parseJSONArray = (value) => {
  if (!value) return [];
  if (Array.isArray(value)) return value;
  if (typeof value === "string") {
    try {
      const parsed = JSON.parse(value);
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return [];
    }
  }
  return [];
};

const updateFreelancerCompletionStats = async ({
  contract,
  completionDate,
}) => {
  const freelancerId = contract?.FreelancerId;
  if (!freelancerId) return;

  let profile = await FreelancerProfile.findOne({
    where: { UserId: freelancerId },
  });

  if (!profile) {
    profile = await FreelancerProfile.create({ UserId: freelancerId });
  }

  const existingExperience = parseJSONArray(profile.work_experience);
  const alreadyRecorded = existingExperience.some(
    (item) =>
      item?.source === "system_contract_completion" &&
      Number(item?.contract_id) === Number(contract.id),
  );

  const completedProjectsCount =
    Number(profile.completed_projects_count || 0) + 1;
  const nextExperience = alreadyRecorded
    ? existingExperience
    : [
        {
          title: `Delivered project: ${contract.Project?.title || `Project #${contract.ProjectId}`}`,
          company: "Freelance",
          start_date: contract.start_date || null,
          end_date: completionDate,
          description: "Completed and delivered successfully to client.",
          source: "system_contract_completion",
          contract_id: contract.id,
          project_id: contract.ProjectId,
        },
        ...existingExperience,
      ];

  await profile.update({
    completed_projects_count: completedProjectsCount,
    experience_years: Math.max(Number(profile.experience_years || 0), 1),
    work_experience: JSON.stringify(nextExperience),
  });
};

export const submitWork = async (req, res) => {
  try {
    const { contractId, milestoneIndex, title, description, files, links } =
      req.body;
    const freelancerId = req.user.id;

    const contract = await Contract.findOne({
      where: { id: contractId, FreelancerId: freelancerId },
      include: [{ model: Project }],
    });

    if (!contract) {
      return res
        .status(404)
        .json({ success: false, message: "Contract not found" });
    }

    if (contract.status !== "active") {
      return res
        .status(400)
        .json({ success: false, message: "Contract is not active" });
    }

    if (contract.escrow_status !== "funded") {
      return res.status(400).json({
        success: false,
        message:
          "Escrow is not funded yet. The client must deposit escrow first.",
      });
    }

    if (milestoneIndex !== null && milestoneIndex !== undefined) {
      let milestones = contract.milestones;
      if (typeof milestones === "string") {
        milestones = JSON.parse(milestones);
      }

      if (milestones[milestoneIndex]) {
        milestones[milestoneIndex].status = "completed";
        milestones[milestoneIndex].completed_at = new Date();
        milestones[milestoneIndex].progress = 100;

        await contract.update({
          milestones: JSON.stringify(milestones),
        });
      }
    }

    const submission = await WorkSubmission.create({
      contract_id: contractId,
      milestone_index: milestoneIndex || null,
      freelancer_id: freelancerId,
      client_id: contract.ClientId,
      title,
      description,
      files: files || [],
      links: links || [],
      status: "pending",
      submitted_at: new Date(),
    });

    await NotificationService.createNotification({
      userId: contract.ClientId,
      type: "work_submitted",
      title: "New Work Submitted",
      body: `${req.user.name} has submitted work for "${contract.Project?.title}"`,
      data: {
        submissionId: submission.id,
        contractId: contract.id,
        screen: "contract_progress",
      },
    });

    res.json({
      success: true,
      message: "Work submitted successfully",
      submission,
    });
  } catch (error) {
    console.error("Error submitting work:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const approveWork = async (req, res) => {
  try {
    const { submissionId } = req.params;
    const clientId = req.user.id;

    const submission = await WorkSubmission.findOne({
      where: { id: submissionId, client_id: clientId },
      include: [
        { model: Contract, as: "Contract", include: [{ model: Project }] },
      ],
    });

    if (!submission) {
      return res
        .status(404)
        .json({ success: false, message: "Submission not found" });
    }

    await submission.update({
      status: "approved",
      approved_at: new Date(),
    });

    const contract = submission.Contract;

    if (
      submission.milestone_index !== null &&
      submission.milestone_index !== undefined
    ) {
      let milestones = contract.milestones;
      if (typeof milestones === "string") {
        milestones = JSON.parse(milestones);
      }

      if (milestones[submission.milestone_index]) {
        milestones[submission.milestone_index].status = "completed";
        milestones[submission.milestone_index].completed_at = new Date();
        await contract.update({ milestones: JSON.stringify(milestones) });
      }
    }

    const milestones = parseJSONArray(contract.milestones);
    const allMilestonesDone =
      milestones.length > 0 &&
      milestones.every((m) => ["completed", "approved"].includes(m?.status));
    const shouldCompleteContract = milestones.length === 0 || allMilestonesDone;

    if (shouldCompleteContract && contract.status !== "completed") {
      const completionDate = new Date();

      await contract.update({
        status: "completed",
        end_date: completionDate,
      });

      if (contract.Project && contract.Project.status !== "completed") {
        await contract.Project.update({ status: "completed" });
      }

      await updateFreelancerCompletionStats({ contract, completionDate });
    }

    await NotificationService.createNotification({
      userId: submission.freelancer_id,
      type: "work_approved",
      title: "Work Approved!",
      body: "Your work has been approved by the client.",
      data: {
        submissionId: submission.id,
        contractId: submission.contract_id,
        screen: "contract_progress",
      },
    });

    res.json({
      success: true,
      message: "Work approved successfully",
      submission,
    });
  } catch (error) {
    console.error("Error approving work:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const requestRevision = async (req, res) => {
  try {
    const { submissionId } = req.params;
    const { revisionMessage } = req.body;
    const clientId = req.user.id;

    const submission = await WorkSubmission.findOne({
      where: { id: submissionId, client_id: clientId },
    });

    if (!submission) {
      return res
        .status(404)
        .json({ success: false, message: "Submission not found" });
    }

    await submission.update({
      status: "revision_requested",
      revision_request_message: revisionMessage,
    });

    await NotificationService.createNotification({
      userId: submission.freelancer_id,
      type: "revision_requested",
      title: "Revision Requested",
      body: revisionMessage || "The client has requested changes to your work.",
      data: {
        submissionId: submission.id,
        contractId: submission.contract_id,
        screen: "contract_progress",
      },
    });

    res.json({
      success: true,
      message: "Revision requested",
      submission,
    });
  } catch (error) {
    console.error("Error requesting revision:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};



export const getContractSubmissions = async (req, res) => {
  try {
    const { contractId } = req.params;
    const userId = req.user.id;

    const submissions = await WorkSubmission.findAll({
      where: {
        contract_id: contractId,
        [Op.or]: [{ freelancer_id: userId }, { client_id: userId }],
      },
      order: [["submitted_at", "DESC"]],
    });

    res.json({
      success: true,
      submissions,
    });
  } catch (error) {
    console.error("Error getting submissions:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};
