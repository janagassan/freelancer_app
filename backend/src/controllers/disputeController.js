// controllers/disputeController.js
import {
  Dispute,
  Contract,
  User,
  Project,
  Wallet,
  Transaction,
} from "../models/index.js";
import { sendDisputeCreatedEmail } from "../utils/mailer.js";
import { Op } from "sequelize";

export const createDispute = async (req, res) => {
  try {
    const { contractId, title, description, evidence_files } = req.body;
    const userId = req.user.id;

    const contract = await Contract.findByPk(contractId, {
      include: [
        { model: User, as: "client", attributes: ["id"] },
        { model: User, as: "freelancer", attributes: ["id"] },
      ],
    });

    if (!contract) {
      return res
        .status(404)
        .json({ success: false, message: "Contract not found" });
    }

    if (contract.ClientId !== userId && contract.FreelancerId !== userId) {
      return res
        .status(403)
        .json({
          success: false,
          message:
            "You are not authorized to create a dispute for this contract",
        });
    }

    const existingDispute = await Dispute.findOne({
      where: { ContractId: contractId },
    });
    if (existingDispute) {
      return res
        .status(400)
        .json({
          success: false,
          message: "A dispute already exists for this contract",
        });
    }

    const initiatedBy = contract.ClientId === userId ? "client" : "freelancer";

    const dispute = await Dispute.create({
      ContractId: contractId,
      ClientId: contract.ClientId,
      FreelancerId: contract.FreelancerId,
      InitiatedBy: initiatedBy,
      title,
      description,
      evidence_files: evidence_files || [],
    });

    try {
      await sendDisputeCreatedEmail(
        process.env.ADMIN_EMAIL || "admin@ipal.com",
        dispute,
      );
    } catch (emailError) {
      console.error("⚠️ Dispute created but failed to send email:", emailError);
    }

    console.log(
      `✅ Dispute created for contract ${contractId} by ${initiatedBy}`,
    );

    res.status(201).json({
      success: true,
      message: "Dispute created successfully",
      dispute,
    });
  } catch (err) {
    console.error("❌ Error in createDispute:", err);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: err.message });
  }
};

export const getUserDisputes = async (req, res) => {
  try {
    const userId = req.user.id;
    const { status, page = 1, limit = 20 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    console.log('🔍 getUserDisputes - userId:', userId);

    const where = {
      [Op.or]: [{ ClientId: userId }, { FreelancerId: userId }],
    };

    if (status && status !== "all") where.status = status;

    const { rows: disputes, count } = await Dispute.findAndCountAll({
      where,
      include: [
        {
          model: Contract,
          include: [
            { model: Project, attributes: ["title"] },
            { model: User, as: "client", attributes: ["name", "email"] },
            { model: User, as: "freelancer", attributes: ["name", "email"] },
          ],
        },
      ],
      order: [["createdAt", "DESC"]],
      limit: parseInt(limit),
      offset,
    });

    console.log('🔍 Disputes found:', disputes.length);
    console.log('🔍 Total count:', count);

    res.json({
      success: true,
      disputes: disputes, 
      total: count,       
      page: parseInt(page),
      totalPages: Math.ceil(count / parseInt(limit)),
    });
  } catch (err) {
    console.error("❌ Error in getUserDisputes:", err);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: err.message });
  }
};


export const getUserDisputeDetails = async (req, res) => {
  try {
    const { disputeId } = req.params;
    const userId = req.user.id;

    const dispute = await Dispute.findOne({
      where: {
        id: disputeId,
        [Op.or]: [{ ClientId: userId }, { FreelancerId: userId }],
      },
      include: [
        {
          model: Contract,
          include: [
            { model: Project, attributes: ["title", "description"] },
            { model: User, as: "client", attributes: ["name", "email"] },
            { model: User, as: "freelancer", attributes: ["name", "email"] },
          ],
        },
      ],
    });

    if (!dispute) {
      return res
        .status(404)
        .json({
          success: false,
          message: "Dispute not found or access denied",
        });
    }

    res.json({
      success: true,
      dispute,
    });
  } catch (err) {
    console.error("❌ Error in getUserDisputeDetails:", err);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: err.message });
  }
};
