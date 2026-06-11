// controllers/clientController.js
import stripe from "../config/stripe.js";
import { sequelize } from "../config/db.js";
import { Op, fn, col } from "sequelize";
import {
  Project,
  Proposal,
  User,
  FreelancerProfile,
  Contract,
  Wallet,
  Transaction,
  Notification,
  Offer,
} from "../models/index.js";
import ContractService from "../services/contractService.js";
import NotificationService from "../services/notificationService.js";
import PaymentService from "../services/paymentService.js";
import SubscriptionService from "../services/subscriptionService.js";
import CommissionService from "../services/commissionService.js";
import AIService from "../services/aiService.js";

export const getDashboardStats = async (req, res) => {
  try {
    const userId = req.user.id;

    const totalProjects = await Project.count({ where: { UserId: userId } });
    const openProjects = await Project.count({
      where: { UserId: userId, status: "open" },
    });
    const inProgressProjects = await Project.count({
      where: { UserId: userId, status: "in_progress" },
    });
    const completedProjects = await Project.count({
      where: { UserId: userId, status: "completed" },
    });

    const myProjects = await Project.findAll({
      where: { UserId: userId },
      attributes: ["id"],
    });

    const projectIds = myProjects.map((p) => p.id);

    const totalProposals = await Proposal.count({
      where: { ProjectId: { [Op.in]: projectIds } },
    });

    const pendingProposals = await Proposal.count({
      where: {
        ProjectId: { [Op.in]: projectIds },
        status: "pending",
      },
    });

    const completedContracts = await Contract.findAll({
      where: { status: "completed" },
      include: [
        {
          model: Project,
          where: { UserId: userId },
        },
      ],
    });

    const totalSpent = completedContracts.reduce(
      (sum, contract) => sum + (contract.agreed_amount || 0),
      0,
    );

    res.json({
      stats: {
        totalProjects,
        openProjects,
        inProgressProjects,
        completedProjects,
        totalProposals,
        pendingProposals,
        totalSpent,
      },
    });
  } catch (err) {
    console.error("Error in getDashboardStats:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getMyProjects = async (req, res) => {
  try {
    console.log("📥 Fetching projects for client:", req.user.id);

    const projects = await Project.findAll({
      where: { UserId: req.user.id },
      include: [
        {
          model: User,
          as: "client",
          attributes: ["id", "name", "avatar"],
        },
      ],
      order: [["createdAt", "DESC"]],
    });

    console.log(`✅ Found ${projects.length} projects`);

    const projectsWithCounts = await Promise.all(
      projects.map(async (project) => {
        const proposalsCount = await Proposal.count({
          where: { ProjectId: project.id },
        });

        return {
          ...project.toJSON(),
          proposalsCount,
        };
      }),
    );

    res.json(projectsWithCounts);
  } catch (err) {
    console.error("❌ Error in getMyProjects:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getProjectById = async (req, res) => {
  try {
    const { id } = req.params;

    const project = await Project.findOne({
      where: {
        id: id,
        UserId: req.user.id,
      },
      include: [
        {
          model: User,
          as: "client",
          attributes: ["id", "name", "avatar"],
        },
      ],
    });

    if (!project) {
      return res.status(404).json({ message: "Project not found" });
    }

    const proposals = await Proposal.findAll({
      where: { ProjectId: id },
      include: [
        {
          model: User,
          as: "freelancer",
          attributes: ["id", "name", "avatar"],
        },
        {
          model: FreelancerProfile,
          as: "profile",
          attributes: ["title", "rating", "experience_years", "skills"],
        },
      ],
      order: [["createdAt", "DESC"]],
    });

    const contract = await Contract.findOne({
      where: { ProjectId: id },
    });

    res.json({
      project,
      proposals,
      contract,
    });
  } catch (err) {
    console.error("Error in getProjectById:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const createProject = async (req, res) => {
  try {
    const { title, description, budget, duration, category, skills } = req.body;

    if (!title || !description || !budget || !duration) {
      return res.status(400).json({
        message:
          "Please provide all required fields: title, description, budget, duration",
      });
    }

    const project = await Project.create({
      title,
      description,
      budget: parseFloat(budget),
      duration: parseInt(duration),
      category: category || "other",
      skills: skills ? JSON.stringify(skills) : "[]",
      status: "open",
      UserId: req.user.id,
    });

    await SubscriptionService.incrementActiveProjectsCount(req.user.id);
    
    res.status(201).json({
      message: "✅ Project created successfully",
      project,
    });
  } catch (err) {
    console.error("Error in createProject:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const updateProject = async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;

    const project = await Project.findOne({
      where: {
        id: id,
        UserId: req.user.id,
      },
    });

    if (!project) {
      return res.status(404).json({ message: "Project not found" });
    }

    if (project.status !== "open") {
      return res.status(400).json({
        message:
          "Cannot update project that is already in progress or completed",
      });
    }

    await project.update(updates);

    res.json({
      message: "✅ Project updated successfully",
      project,
    });
  } catch (err) {
    console.error("Error in updateProject:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const deleteProject = async (req, res) => {
  try {
    const { id } = req.params;

    const project = await Project.findOne({
      where: {
        id: id,
        UserId: req.user.id,
      },
    });

    if (!project) {
      return res.status(404).json({ message: "Project not found" });
    }

    if (project.status !== "open") {
      return res.status(400).json({
        message:
          "Cannot delete project that is already in progress or completed",
      });
    }

    await Proposal.destroy({ where: { ProjectId: id } });

    await project.destroy();

    res.json({ message: "✅ Project deleted successfully" });
  } catch (err) {
    console.error("Error in deleteProject:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getProjectProposals = async (req, res) => {
  try {
    const { projectId } = req.params;

    const project = await Project.findOne({
      where: {
        id: projectId,
        UserId: req.user.id,
      },
    });

    if (!project) {
      return res.status(404).json({ message: "Project not found" });
    }
    const proposals = await Proposal.findAll({
      where: { ProjectId: projectId },
      include: [
        {
          model: User,
          as: "freelancer",
          attributes: ["id", "name", "avatar", "email"],
        },
        {
          model: FreelancerProfile,
          as: "profile",
          required: false,
          attributes: [
            "id",
            "title",
            "rating",
            "experience_years",
            "skills",
            "location",
            "cv_url",
          ],
        },
      ],
      order: [["createdAt", "DESC"]],
    });

    console.log(
      `✅ Found ${proposals.length} proposals for project ${projectId}`,
    );

    const enhancedProposals = proposals.map((proposal) => {
      const proposalData = proposal.toJSON();
      return {
        ...proposalData,
        freelancerProfile: proposalData.profile,
        profile: undefined,
      };
    });

    res.json(enhancedProposals);
  } catch (err) {
    console.error("❌ Error in getProjectProposals:", err);
    res.status(500).json({
      message: "Server error",
      error: err.message,
    });
  }
};

export const updateProposalStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!["accepted", "rejected"].includes(status)) {
      return res
        .status(400)
        .json({ message: "Invalid status. Use 'accepted' or 'rejected'" });
    }

    const proposal = await Proposal.findByPk(id, {
      include: [
        {
          model: Project,
          include: [{ model: User, as: "client", attributes: ["id", "name"] }],
        },
        {
          model: User,
          as: "freelancer",
          attributes: ["id", "name"],
        },
      ],
    });

    if (!proposal) {
      return res
        .status(404)
        .json({ message: "Proposal not found or you don't have permission" });
    }

    if (proposal.Project.UserId !== req.user.id) {
      return res.status(403).json({ message: "Unauthorized" });
    }

    if (proposal.status !== "pending") {
      return res.status(400).json({
        message: `This proposal is already ${proposal.status}`,
      });
    }

    if (status === "accepted") {
      await Proposal.update(
        { status: "rejected" },
        {
          where: {
            ProjectId: proposal.ProjectId,
            id: { [Op.ne]: id },
            status: { [Op.in]: ["pending", "negotiating", "interviewing"] },
          },
        },
      );

      await proposal.update({ status: "contracted" });

      const proposedMilestones = Array.isArray(proposal.milestones)
        ? proposal.milestones
        : [];

      const contract = await ContractService.createContractDraft(
        proposal.ProjectId,
        proposal.UserId,
        req.user.id,
        proposal.price,
        proposedMilestones,
      );

      if (!contract || !contract.id) {
        console.error("❌ Failed to create contract");
        return res.status(500).json({
          message: "Failed to create contract",
          proposal,
        });
      }

      console.log("✅ Contract draft created:", contract.id);

      await NotificationService.createNotification({
        userId: proposal.UserId,
        type: "proposal_accepted",
        title: "Your Proposal Was Accepted! 🎉",
        body: `Your proposal for "${proposal.Project.title}" has been accepted. Please review and sign the contract.`,
        data: {
          projectId: proposal.ProjectId,
          contractId: contract.id,
          proposalId: proposal.id,
          screen: "contract",
        },
      });

      return res.json({
        success: true,
        message: "✅ Proposal accepted. Please review and sign the contract.",
        proposal: { ...proposal.toJSON(), status: "contracted" },
        contract: {
          id: contract.id,
          agreed_amount: contract.agreed_amount,
          status: contract.status,
          projectId: contract.ProjectId,
          freelancerId: contract.FreelancerId,
          clientId: contract.ClientId,
        },
        requiresSignature: true,
      });
    }

    if (status === "rejected") {
      await proposal.update({ status: "rejected" });
      
      await NotificationService.createNotification({
        userId: proposal.UserId,
        type: "proposal_rejected",
        title: "Proposal Update",
        body: `Your proposal for "${proposal.Project.title}" was not selected this time.`,
        data: {
          projectId: proposal.ProjectId,
          proposalId: proposal.id,
          screen: "my_proposals",
        },
      });

      return res.json({
        success: true,
        message: "✅ Proposal rejected",
        proposal,
      });
    }

  } catch (err) {
    console.error("❌ Error in updateProposalStatus:", err);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: err.message,
    });
  }
};

export const getProjectContract = async (req, res) => {
  try {
    const { projectId } = req.params;

    const contract = await Contract.findOne({
      where: { ProjectId: projectId },
      include: [
        {
          model: Project,
          where: { UserId: req.user.id },
        },
        {
          model: User,
          attributes: ["id", "name", "avatar"],
        },
      ],
    });

    if (!contract) {
      return res.status(404).json({ message: "Contract not found" });
    }

    res.json(contract);
  } catch (err) {
    console.error("Error in getProjectContract:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getMyContracts = async (req, res) => {
  try {
    const contracts = await Contract.findAll({
      include: [
        {
          model: Project,
          where: { UserId: req.user.id },
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
      order: [["createdAt", "DESC"]],
    });

    res.json(contracts);
  } catch (err) {
    console.error("❌ Error in getMyContracts:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const completeProject = async (req, res) => {
  try {
    const { projectId } = req.params;

    const project = await Project.findOne({
      where: {
        id: projectId,
        UserId: req.user.id,
        status: "in_progress",
      },
    });

    if (!project) {
      return res
        .status(404)
        .json({ message: "Project not found or not in progress" });
    }

    await project.update({ status: "completed" });
    await SubscriptionService.decrementActiveProjectsCount(req.user.id);

    const contract = await Contract.findOne({
      where: { ProjectId: projectId },
    });

    if (contract) {
      await contract.update({
        status: "completed",
        end_date: new Date(),
      });
    }
    res.json({
      message: "✅ Project completed successfully",
      project,
      contractId: contract?.id,
    });
  } catch (err) {
    console.error("Error in completeProject:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const createContractFromProposal = async (req, res) => {
  try {
    const { proposalId } = req.body;

    const proposal = await Proposal.findByPk(proposalId, {
      include: [Project],
    });

    if (!proposal) {
      return res.status(404).json({ message: "Proposal not found" });
    }

    const project = await Project.findOne({
      where: { id: proposal.ProjectId, UserId: req.user.id },
    });

    if (!project) {
      return res.status(403).json({ message: "Unauthorized" });
    }

    const contract = await ContractService.createContractDraft(
      proposal.ProjectId,
      proposal.UserId,
      req.user.id,
      proposal.price,
    );

    res.status(201).json({
      message: "Contract created successfully",
      contract,
    });
  } catch (err) {
    console.error("Error creating contract:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const startNegotiation = async (req, res) => {
  try {
    const { proposalId } = req.params;

    const proposal = await Proposal.findByPk(proposalId, {
      include: [
        { model: Project },
        { model: User, as: "freelancer", attributes: ["id", "name"] },
      ],
    });

    if (!proposal) {
      return res.status(404).json({ message: "Proposal not found" });
    }

    if (proposal.Project.UserId !== req.user.id) {
      return res.status(403).json({ message: "Unauthorized" });
    }

    if (proposal.status !== "pending") {
      return res.status(400).json({ message: "Proposal already processed" });
    }

    await proposal.update({ status: "negotiating" });

    res.json({
      message: "Negotiation started",
      proposal: {
        id: proposal.id,
        price: proposal.price,
        delivery_time: proposal.delivery_time,
        milestones: proposal.milestones,
        freelancer: proposal.freelancer,
      },
    });
  } catch (err) {
    console.error("Error in startNegotiation:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const updateNegotiation = async (req, res) => {
  try {
    const { proposalId } = req.params;
    const { price, delivery_time, milestones } = req.body;

    const proposal = await Proposal.findByPk(proposalId, {
      include: [{ model: Project }],
    });

    if (!proposal) {
      return res.status(404).json({ message: "Proposal not found" });
    }

    if (
      proposal.Project.UserId !== req.user.id &&
      proposal.UserId !== req.user.id
    ) {
      return res.status(403).json({ message: "Unauthorized" });
    }

    const updateData = {};
    if (price) updateData.price = parseFloat(price);
    if (delivery_time) updateData.delivery_time = parseInt(delivery_time);
    if (milestones) updateData.milestones = milestones;

    const negotiatedData = {
      ...proposal.negotiated_data,
      [req.user.id]: updateData,
      last_updated_by: req.user.id,
      last_updated_at: new Date(),
    };

    await proposal.update({
      negotiated_data: negotiatedData,
      ...updateData,
    });

    res.json({
      message: "Negotiation updated",
      proposal,
    });
  } catch (err) {
    console.error("Error in updateNegotiation:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const acceptProposalWithNegotiation = async (req, res) => {
  try {
    const { proposalId } = req.params;
    const { agreedPrice, agreedMilestones } = req.body;

    const proposal = await Proposal.findByPk(proposalId, {
      include: [
        { model: Project, include: [{ model: User, as: "client" }] },
        { model: User, as: "freelancer", attributes: ["id", "name", "email"] },
      ],
    });

    if (!proposal)
      return res.status(404).json({ message: "Proposal not found" });
    if (proposal.Project.UserId !== req.user.id) {
      return res.status(403).json({ message: "Unauthorized" });
    }

    const finalPrice = agreedPrice ?? proposal.price;
    const finalMilestones = Array.isArray(agreedMilestones)
      ? agreedMilestones
      : Array.isArray(proposal.milestones)
        ? proposal.milestones
        : [];

    await Proposal.update(
      { status: "rejected" },
      { where: { ProjectId: proposal.ProjectId, id: { [Op.ne]: proposalId } } },
    );
    await proposal.update({ status: "accepted" });

    await Proposal.update(
      { status: "rejected" },
      {
        where: {
          ProjectId: proposal.ProjectId,
          id: { [Op.ne]: proposalId },
          status: { [Op.in]: ["pending", "negotiating", "interviewing"] },
        },
      },
    );
    await proposal.update({ status: "accepted", price: finalPrice });

    const contract = await ContractService.createContractDraft(
      proposal.ProjectId,
      proposal.UserId,
      req.user.id,
      finalPrice,
      finalMilestones,
    );

    try {
      const p = proposal.Project;
      const skills = p?.skills
        ? Array.isArray(p.skills)
          ? p.skills
          : JSON.parse(p.skills)
        : [];
      const sowResult = await AIService.generateProfessionalSOW(
        {
          title: p?.title,
          description: p?.description,
          category: p?.category,
          skills,
          budget: finalPrice,
          duration: p?.duration,
          clientName: req.user.name,
          clientEmail: req.user.email,
        },
        FreelancerProfile,
        finalMilestones,
        "",
      );
      if (sowResult?.html) {
        await contract.update({
          contract_document: sowResult.html,
          ai_analysis: sowResult.analysis,
          terms: "AI-generated SOW document",
        });
      }
    } catch (e) {
      console.warn("SOW generation skipped:", e?.message || e);
    }

    res.json({
      message: "✅ Proposal accepted. Contract draft created.",
      contract,
      requiresSignature: true,
    });
  } catch (err) {
    console.error("Error in acceptProposalWithNegotiation:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const confirmPayment = async (req, res) => {
  try {
    const { contractId, paymentIntentId } = req.body;

    const contract = await Contract.findByPk(contractId);

    if (!contract) {
      return res.status(404).json({ message: "Contract not found" });
    }

    if (contract.ClientId !== req.user.id) {
      return res.status(403).json({ message: "Unauthorized" });
    }

    await PaymentService.handlePaymentSuccess(paymentIntentId);

    res.json({
      message: "✅ Payment confirmed. Contract is now active.",
      contract,
    });
  } catch (err) {
    console.error("Error in confirmPayment:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const releaseMilestone = async (req, res) => {
  try {
    const { contractId, milestoneIndex } = req.params;

    const result = await PaymentService.releaseMilestonePayment(
      parseInt(contractId),
      parseInt(milestoneIndex),
      req.user.id,
    );

    res.json({
      message: "✅ Milestone payment released",
      ...result,
    });
  } catch (err) {
    console.error("Error in releaseMilestone:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const requestWithdrawal = async (req, res) => {
  try {
    const { amount } = req.body;

    const result = await PaymentService.requestWithdrawal(req.user.id, amount);

    res.json(result);
  } catch (err) {
    console.error("Error in requestWithdrawal:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getWallet = async (req, res) => {
  try {
    let wallet = await Wallet.findOne({ where: { UserId: req.user.id } });

    if (!wallet) {
      wallet = await Wallet.create({ UserId: req.user.id, balance: 0 });
    }

    const transactions = await Transaction.findAll({
      where: { wallet_id: wallet.id },
      order: [["createdAt", "DESC"]],
      limit: 50,
    });

    res.json({
      wallet,
      transactions,
    });
  } catch (err) {
    console.error("Error in getWallet:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const createCheckoutSession = async (req, res) => {
  try {
    const { contractId } = req.params;
    const { paymentIntentId } = req.body;

    console.log("🔍 Creating checkout session for contract:", contractId);
    console.log("🔍 Payment Intent ID:", paymentIntentId);

    const frontendUrl = process.env.FRONTEND_URL || "http://localhost:5000";
    console.log("🔍 Frontend URL:", frontendUrl);

    const result = await PaymentService.createCheckoutSession(
      contractId,
      req.user.id,
      frontendUrl,
    );

    console.log("✅ Checkout session result:", result);

    if (result.checkoutUrl) {
      res.json({
        success: true,
        checkoutUrl: result.checkoutUrl,
        sessionId: result.sessionId,
      });
    } else {
      res.status(400).json({
        success: false,
        message: "Failed to create checkout session",
      });
    }
  } catch (err) {
    console.error("Error creating checkout session:", err);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: err.message,
    });
  }
};

export const manualConfirmPayment = async (req, res) => {
  try {
    const { contractId } = req.params;

    console.log("💰 Manual payment confirmation for contract:", contractId);

    if (!contractId) {
      return res.status(400).json({ message: "Contract ID is required" });
    }

    const contract = await Contract.findByPk(contractId);

    if (!contract) {
      return res.status(404).json({ message: "Contract not found" });
    }

    console.log("📊 Contract found:", contract.id);
    console.log("📊 Agreed amount:", contract.agreed_amount);

    let agreedAmount = contract.agreed_amount;

    if (typeof agreedAmount === "string") {
      if (agreedAmount.includes(".") && agreedAmount.split(".").length > 2) {
        const parts = agreedAmount.split(".");
        agreedAmount = parts[0] + "." + parts[1];
      }
      agreedAmount = parseFloat(agreedAmount);
    }

    if (
      !isNaN(agreedAmount) &&
      agreedAmount < 1 &&
      agreedAmount > 0 &&
      agreedAmount.toString().includes("0012")
    ) {
      agreedAmount = agreedAmount * 10000;
    }

    if (isNaN(agreedAmount) || agreedAmount <= 0) {
      console.error("❌ Invalid agreed_amount:", contract.agreed_amount);
      return res.status(400).json({
        message: "Invalid contract amount",
        originalAmount: contract.agreed_amount,
      });
    }

    agreedAmount = Math.round(agreedAmount * 100) / 100;

    console.log("✅ Cleaned agreed_amount:", agreedAmount);

    await contract.update({
      escrow_status: "funded",
      payment_status: "escrow",
      funded_escrow_amount: agreedAmount,
    });

    console.log("✅ Contract updated with funded_escrow_amount:", agreedAmount);

    let clientWallet = await Wallet.findOne({
      where: { UserId: contract.ClientId },
    });

    if (!clientWallet) {
      clientWallet = await Wallet.create({
        UserId: contract.ClientId,
        balance: 0,
        pending_balance: 0,
      });
    }

    const currentPending = parseFloat(clientWallet.pending_balance || 0);
    const newPendingBalance = currentPending + agreedAmount;
    const roundedBalance = Math.round(newPendingBalance * 100) / 100;

    await clientWallet.update({
      pending_balance: roundedBalance,
    });

    console.log("✅ Wallet updated, pending_balance:", roundedBalance);

    const transaction = await Transaction.create({
      wallet_id: clientWallet.id,
      amount: agreedAmount,
      type: "deposit",
      status: "completed",
      description: `Manual escrow deposit for contract #${contract.id}`,
      reference_id: contract.id,
      reference_type: "contract",
      completed_at: new Date(),
    });

    console.log("✅ Transaction created:", transaction.id);

    await NotificationService.createNotification({
      userId: contract.ClientId,
      type: "payment_received",
      title: "Payment Confirmed ✅",
      body: `$${agreedAmount.toFixed(2)} has been deposited into escrow.`,
      data: { contractId: contract.id, screen: "contract" },
    });

    await NotificationService.createNotification({
      userId: contract.FreelancerId,
      type: "payment_received",
      title: "Payment Secured 💰",
      body: `The client has funded $${agreedAmount.toFixed(2)} into escrow.`,
      data: { contractId: contract.id, screen: "contract" },
    });

    res.json({
      success: true,
      message: "Payment confirmed successfully",
      contract: {
        id: contract.id,
        escrow_status: contract.escrow_status,
        payment_status: contract.payment_status,
        funded_escrow_amount: agreedAmount,
      },
    });
  } catch (err) {
    console.error("Error in manualConfirmPayment:", err);
    res.status(500).json({
      message: "Server error",
      error: err.message,
    });
  }
};

export const handlePaymentSuccess = async (req, res) => {
  try {
    const { session_id, contract_id } = req.query;

    console.log("💰 Payment success callback:", { session_id, contract_id });

    const result = await PaymentService.handleCheckoutSuccess(session_id);

    if (result.success) {
      res.redirect(
        `${process.env.FRONTEND_URL}/contract/${contract_id}?payment=success`,
      );
    } else {
      res.redirect(
        `${process.env.FRONTEND_URL}/contract/${contract_id}?payment=failed`,
      );
    }
  } catch (err) {
    console.error("Error handling payment success:", err);
    res.redirect(`${process.env.FRONTEND_URL}/contract?payment=failed`);
  }
};

export const approveMilestone = async (req, res) => {
  try {
    const { contractId, milestoneIndex } = req.params;
    const userId = req.user.id;

    const contract = await Contract.findOne({
      where: { id: contractId, ClientId: userId },
    });

    if (!contract) {
      return res.status(404).json({ message: "Contract not found" });
    }

    let milestones = contract.milestones;
    if (typeof milestones === "string") {
      milestones = JSON.parse(milestones);
    }

    if (!milestones[milestoneIndex]) {
      return res.status(404).json({ message: "Milestone not found" });
    }

    const milestone = milestones[milestoneIndex];

    if (milestone.status !== "completed") {
      return res.status(400).json({ message: "Milestone not completed yet" });
    }

    if (milestone.status === "approved") {
      return res.status(400).json({ message: "Milestone already approved" });
    }

    const pool =
      contract.funded_escrow_amount != null
        ? parseFloat(contract.funded_escrow_amount)
        : parseFloat(contract.agreed_amount);
    const alreadyReleased = parseFloat(contract.released_amount || 0);
    const milestoneAmt = parseFloat(milestone.amount || 0);

    if (alreadyReleased + milestoneAmt > pool + 0.01) {
      return res.status(400).json({
        message:
          "Cannot approve: total milestone releases would exceed funded escrow",
      });
    }

    await PaymentService.releaseMilestonePayment(
      contractId,
      milestoneIndex,
      userId,
    );

    milestone.status = "approved";
    milestone.approved_at = new Date();
    milestones[milestoneIndex] = milestone;

    await contract.update({
      milestones: JSON.stringify(milestones),
      released_amount: (contract.released_amount || 0) + milestoneAmt,
    });

    await NotificationService.createNotification({
      userId: contract.FreelancerId,
      type: "payment_released",
      title: "Milestone Payment Released! 💰",
      body: `$${milestone.amount} has been released for "${milestone.title}"`,
      data: { contractId: contract.id, screen: "contract_progress" },
    });

    res.json({ message: "✅ Milestone approved", milestone });
  } catch (err) {
    console.error("Error approving milestone:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getOrCreateWallet = async (req, res) => {
  try {
    let wallet = await Wallet.findOne({ where: { UserId: req.user.id } });

    if (!wallet) {
      wallet = await Wallet.create({
        UserId: req.user.id,
        balance: 0,
        pending_balance: 0,
        total_earned: 0,
        total_withdrawn: 0,
      });
    }

    const transactions = await Transaction.findAll({
      where: { wallet_id: wallet.id },
      order: [["createdAt", "DESC"]],
      limit: 50,
    });

    res.json({ wallet, transactions });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

export const createWallet = async (req, res) => {
  try {
    const existing = await Wallet.findOne({ where: { UserId: req.user.id } });
    if (existing) {
      return res.json({ success: true, wallet: existing });
    }

    const wallet = await Wallet.create({
      UserId: req.user.id,
      balance: 0,
      pending_balance: 0,
    });

    res.json({ success: true, wallet });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

export const createDirectPayment = async (req, res) => {
  try {
    const { contractId } = req.params;
    const userId = req.user.id;

    const contract = await Contract.findByPk(contractId, {
      include: [{ model: Project }],
    });

    if (!contract) {
      return res.status(404).json({ message: "Contract not found" });
    }

    if (contract.ClientId !== userId) {
      return res.status(403).json({ message: "Unauthorized" });
    }

    const agreed = parseFloat(contract.agreed_amount || 0);
    const discount = parseFloat(contract.coupon_discount_amount || 0);
    const chargeAmount = Math.max(0.5, agreed - discount);
    const cents = Math.round(chargeAmount * 100);
    if (cents < 50) {
      return res.status(400).json({
        success: false,
        message: "Amount too small for card payment (min $0.50)",
      });
    }

    let commissionPreview = { rate: 0.05, platformFee: agreed * 0.05 };
    try {
      commissionPreview = await CommissionService.calculateCommission(
        userId,
        agreed,
      );
    } catch (e) {
      console.warn("commission preview:", e.message);
    }

    const paymentIntent = await stripe.paymentIntents.create({
      amount: cents,
      currency: "usd",
      metadata: {
        contractId: String(contract.id),
        type: "escrow",
        projectTitle: contract.Project?.title || "Project Payment",
        agreed_amount: String(agreed),
        coupon_discount: String(discount),
        coupon_code: contract.coupon_code || "",
      },
      description: `Contract #${contract.id} - ${contract.Project?.title}`,
      automatic_payment_methods: {
        enabled: true,
      },
    });

    await contract.update({
      escrow_id: paymentIntent.id,
      escrow_status: "pending",
    });

    res.json({
      success: true,
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
      amount: chargeAmount,
      agreed_amount: agreed,
      coupon_discount: discount,
      coupon_code: contract.coupon_code,
      amount_to_charge: chargeAmount,
      commission_preview: {
        rate_percent: Math.round(commissionPreview.rate * 1000) / 10,
        estimated_fee_on_release: commissionPreview.platformFee,
        note: "Fee is estimated from your current subscription; charged when funds are released to the freelancer.",
      },
    });
  } catch (err) {
    console.error("Error creating direct payment:", err);
    res.status(500).json({
      success: false,
      message: err.message,
      error: err.toString(),
    });
  }
};

export const getClientDashboardOverview = async (req, res) => {
  try {
    const userId = req.user.id;
    const now = new Date();

    const projects = await Project.findAll({
      where: { UserId: userId },
      attributes: ["id", "title", "status", "budget", "createdAt"],
    });

    const totalProjects = projects.length;
    const openProjects = projects.filter((p) => p.status === "open").length;
    const inProgressProjects = projects.filter(
      (p) => p.status === "in_progress",
    ).length;
    const completedProjects = projects.filter(
      (p) => p.status === "completed",
    ).length;

    const projectIds = projects.map((p) => p.id);

    const proposals = await Proposal.findAll({
      where: { ProjectId: projectIds },
      include: [
        { model: User, as: "freelancer", attributes: ["id", "name", "avatar"] },
        {
          model: FreelancerProfile,
          as: "profile",
          attributes: ["title", "rating", "skills"],
        },
        { model: Project, attributes: ["title", "id"] },
      ],
      order: [["createdAt", "DESC"]],
      limit: 5,
    });

    const totalProposals = proposals.length;
    const pendingProposals = proposals.filter(
      (p) => p.status === "pending",
    ).length;
    const acceptedProposals = proposals.filter(
      (p) => p.status === "accepted",
    ).length;

    const contracts = await Contract.findAll({
      where: { ClientId: userId },
      include: [
        { model: Project, attributes: ["title", "category"] },
        { model: User, as: "freelancer", attributes: ["id", "name", "avatar"] },
      ],
      order: [["createdAt", "DESC"]],
      limit: 10,
    });

    const completedContracts = contracts.filter(
      (c) => c.status === "completed",
    );
    const totalSpent = completedContracts.reduce(
      (sum, c) => sum + (parseFloat(c.agreed_amount) || 0),
      0,
    );
    const escrowHeld = contracts
      .filter((c) => c.escrow_status === "funded")
      .reduce((sum, c) => sum + (parseFloat(c.agreed_amount) || 0), 0);

    const sixMonthsAgo = new Date(now);
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 5);
    sixMonthsAgo.setDate(1);
    sixMonthsAgo.setHours(0, 0, 0, 0);

    const wallet = await Wallet.findOne({ where: { UserId: userId } });
    let monthlySpending = [];

    if (wallet) {
      const raw = await Transaction.findAll({
        where: {
          wallet_id: wallet.id,
          type: "deposit",
          status: "completed",
          createdAt: { [Op.gte]: sixMonthsAgo },
        },
        attributes: [
          [sequelize.fn("YEAR", sequelize.col("createdAt")), "year"],
          [sequelize.fn("MONTH", sequelize.col("createdAt")), "month"],
          [sequelize.fn("SUM", sequelize.col("amount")), "total"],
        ],
        group: [
          sequelize.fn("YEAR", sequelize.col("createdAt")),
          sequelize.fn("MONTH", sequelize.col("createdAt")),
        ],
        order: [
          [sequelize.fn("YEAR", sequelize.col("createdAt")), "ASC"],
          [sequelize.fn("MONTH", sequelize.col("createdAt")), "ASC"],
        ],
        raw: true,
      });

      for (let i = 5; i >= 0; i--) {
        const d = new Date(now);
        d.setMonth(d.getMonth() - i);
        const y = d.getFullYear();
        const m = d.getMonth() + 1;
        const found = raw.find(
          (r) => Number(r.year) === y && Number(r.month) === m,
        );
        monthlySpending.push({
          label: d.toLocaleString("en", { month: "short" }),
          total: found ? parseFloat(found.total) : 0,
        });
      }
    } else {
      for (let i = 5; i >= 0; i--) {
        const d = new Date(now);
        d.setMonth(d.getMonth() - i);
        monthlySpending.push({
          label: d.toLocaleString("en", { month: "short" }),
          total: 0,
        });
      }
    }

    const activeContracts = contracts
      .filter((c) => c.status === "active")
      .map((c) => {
        const milestones = c.milestones
          ? Array.isArray(c.milestones)
            ? c.milestones
            : JSON.parse(c.milestones)
          : [];
        const total = milestones.length;
        const done = milestones.filter(
          (m) => m.status === "completed" || m.status === "approved",
        ).length;
        const progress = total > 0 ? Math.round((done / total) * 100) : 0;
        const nextMs = milestones.find(
          (m) => m.status !== "completed" && m.status !== "approved",
        );

        return {
          id: c.id,
          status: c.status,
          escrowStatus: c.escrow_status,
          agreedAmount: parseFloat(c.agreed_amount) || 0,
          releasedAmount: parseFloat(c.released_amount) || 0,
          progress: progress,
          milestonesTotal: total,
          milestonesDone: done,
          projectTitle: c.Project?.title,
          projectCategory: c.Project?.category,
          projectId: c.Project?.id,
          freelancerName: c.freelancer?.name,
          freelancerAvatar: c.freelancer?.avatar,
          nextMilestoneTitle: nextMs?.title || null,
        };
      });

    const notifications = await Notification.findAll({
      where: { userId: userId },
      order: [["createdAt", "DESC"]],
      limit: 5,
    });

    const statusBreakdown = [
      { label: "Open", value: openProjects, color: "#3B82F6" },
      { label: "In Progress", value: inProgressProjects, color: "#F59E0B" },
      { label: "Completed", value: completedProjects, color: "#10B981" },
    ].filter((s) => s.value > 0);

    const topFreelancers = await User.findAll({
      where: { role: "freelancer" },
      include: [{ model: FreelancerProfile, attributes: ["rating"] }],
      limit: 5,
      attributes: ["id", "name", "avatar"],
    });

    res.json({
      stats: {
        totalProjects,
        openProjects,
        inProgressProjects,
        completedProjects,
        totalProposals,
        pendingProposals,
        acceptedProposals,
        totalSpent,
        escrowHeld,
        totalReleased: 0,
        proposalAcceptRate:
          totalProposals > 0
            ? Math.round((acceptedProposals / totalProposals) * 100)
            : 0,
      },
      monthlySpending,
      statusBreakdown,
      recentProposals: proposals.map((p) => ({
        id: p.id,
        status: p.status,
        price: parseFloat(p.price) || 0,
        deliveryTime: p.delivery_time,
        proposalText: p.proposal_text,
        projectTitle: p.Project?.title,
        projectId: p.Project?.id,
        freelancerName: p.freelancer?.name,
        freelancerAvatar: p.freelancer?.avatar,
        freelancerTitle: p.profile?.title,
        freelancerRating: p.profile?.rating,
        skills: p.profile?.skills
          ? typeof p.profile.skills === "string"
            ? JSON.parse(p.profile.skills)
            : p.profile.skills
          : [],
      })),
      activeContracts,
      recentActivity: notifications.map((n) => ({
        id: n.id,
        type: n.type,
        title: n.title,
        body: n.body,
        isRead: n.isRead,
        createdAt: n.createdAt,
        data: n.data,
      })),
      topFreelancers: topFreelancers.map((f) => ({
        id: f.id,
        name: f.name,
        avatar: f.avatar,
        rating: f.FreelancerProfile?.rating || 0,
      })),
    });
  } catch (error) {
    console.error("❌ Error in getClientDashboardOverview:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
};

export const getClientProfile = async (req, res) => {
  try {
    const userId = req.user.id;

    const user = await User.findByPk(userId, {
      attributes: ["id", "name", "avatar", "email"],
    });

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    res.json({
      id: user.id,
      name: user.name,
      avatar: user.avatar,
      email: user.email,
      company: user.company || null,
      phone: user.phone || null,
    });
  } catch (error) {
    console.error("❌ Error in getClientProfile:", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

export const createContractFromProposalDirect = async (req, res) => {
  try {
    const { proposalId, agreedAmount, milestones, sowHtml, sowAnalysis } =
      req.body;
    const clientId = req.user.id;

    console.log("📝 Creating contract from proposal:", proposalId);
    console.log("📄 Has SOW HTML:", !!sowHtml);

    const proposal = await Proposal.findByPk(proposalId, {
      include: [
        { model: Project },
        { model: User, as: "freelancer", attributes: ["id", "name", "email"] },
      ],
    });

    if (!proposal) {
      return res
        .status(404)
        .json({ success: false, message: "Proposal not found" });
    }

    if (proposal.Project.UserId !== clientId) {
      return res.status(403).json({ success: false, message: "Unauthorized" });
    }

    const existingContract = await Contract.findOne({
      where: { ProjectId: proposal.ProjectId },
    });

    if (existingContract) {
      console.log("⚠️ Contract already exists:", existingContract.id);
      return res.json({
        success: true,
        contract: {
          id: existingContract.id,
          agreed_amount: existingContract.agreed_amount,
          status: existingContract.status,
        },
      });
    }

    const finalMilestones = milestones || [
      {
        title: "Project Start",
        description: "Begin work on project",
        amount: agreedAmount * 0.3,
        percentage: 30,
        due_date: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
        status: "pending",
      },
      {
        title: "Milestone 1",
        description: "First deliverable",
        amount: agreedAmount * 0.4,
        percentage: 40,
        due_date: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000).toISOString(),
        status: "pending",
      },
      {
        title: "Final Delivery",
        description: "Complete project",
        amount: agreedAmount * 0.3,
        percentage: 30,
        due_date: new Date(Date.now() + 21 * 24 * 60 * 60 * 1000).toISOString(),
        status: "pending",
      },
    ];

    let contractDocument;
    if (sowHtml) {
      contractDocument = sowHtml;
      console.log("✅ Using SOW HTML as contract document");
    } else {
      contractDocument = ContractService.generateContractDocument({
        projectId: proposal.ProjectId,
        freelancerId: proposal.UserId,
        clientId: clientId,
        agreed_amount: agreedAmount,
      });
      console.log("📄 Using regular contract document");
    }

    const contract = await Contract.create({
      ProjectId: proposal.ProjectId,
      FreelancerId: proposal.UserId,
      ClientId: clientId,
      agreed_amount: agreedAmount,
      contract_document: contractDocument,
      status: "draft",
      terms: sowHtml
        ? "AI-generated SOW document"
        : "Standard terms and conditions apply.",
      milestones: JSON.stringify(finalMilestones),
      ai_analysis: sowAnalysis ? JSON.stringify(sowAnalysis) : null,
    });

    console.log("✅ Contract created with ID:", contract.id);
    console.log("✅ Contract document type:", sowHtml ? "SOW" : "Regular");

    await proposal.update({ status: "accepted" });

    await Proposal.update(
      { status: "rejected" },
      {
        where: {
          ProjectId: proposal.ProjectId,
          id: { [Op.ne]: proposalId },
          status: "pending",
        },
      },
    );

    await NotificationService.createNotification({
      userId: proposal.UserId,
      type: "contract_created",
      title: "New Contract Created",
      body: `A ${sowHtml ? "SOW document" : "contract"} has been created for "${proposal.Project.title}". Please review and sign.`,
      data: {
        contractId: contract.id,
        projectId: proposal.ProjectId,
        screen: "contract",
      },
    });

    res.json({
      success: true,
      contract: {
        id: contract.id,
        agreed_amount: contract.agreed_amount,
        status: contract.status,
        projectId: contract.ProjectId,
        freelancerId: contract.FreelancerId,
        clientId: contract.ClientId,
        hasSOW: !!sowHtml,
      },
    });
  } catch (error) {
    console.error("❌ Error creating contract:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const sendOfferToFreelancer = async (req, res) => {
  try {
    const { freelancerId, projectId, amount, message } = req.body;
    const clientId = req.user.id;

    if (!freelancerId || !projectId) {
      return res.status(400).json({
        success: false,
        message: "Freelancer ID and Project ID are required",
      });
    }

    const project = await Project.findOne({
      where: {
        id: projectId,
        UserId: clientId,
      },
    });

    if (!project) {
      return res.status(404).json({
        success: false,
        message: "Project not found or you do not have permission",
      });
    }

    if (project.status !== "open") {
      return res.status(400).json({
        success: false,
        message: "Project is not open for offers",
      });
    }

    const freelancer = await User.findOne({
      where: {
        id: freelancerId,
        role: "freelancer",
      },
    });

    if (!freelancer) {
      return res.status(404).json({
        success: false,
        message: "Freelancer not found",
      });
    }

    const existingOffer = await Offer.findOne({
      where: {
        clientId: clientId,
        freelancerId: freelancerId,
        projectId: projectId,
        status: "pending",
      },
    });

    if (existingOffer) {
      return res.status(400).json({
        success: false,
        message:
          "You already have a pending offer for this freelancer on this project",
      });
    }

    const offer = await Offer.create({
      clientId: clientId,
      freelancerId: freelancerId,
      projectId: projectId,
      amount: amount || project.budget,
      message:
        message || `I would like to hire you for project: ${project.title}`,
      status: "pending",
    });

    const NotificationService = (
      await import("../services/notificationService.js")
    ).default;

    await NotificationService.createNotification({
      userId: freelancerId,
      type: "offer_received",
      title: "New Job Offer! 🎉",
      body: `You received a job offer${amount ? ` of $${amount}` : ""} from ${req.user.name}`,
      data: {
        offerId: offer.id,
        projectId: projectId,
        projectTitle: project.title,
        amount: amount || project.budget,
        type: "offer",
      },
    });

    res.status(201).json({
      success: true,
      message: "Offer sent successfully",
      offer: {
        id: offer.id,
        projectTitle: project.title,
        amount: offer.amount,
        message: offer.message,
        status: offer.status,
        expiresAt: offer.expiresAt,
      },
    });
  } catch (error) {
    console.error("Error in sendOfferToFreelancer:", error);
    res.status(500).json({
      success: false,
      message: "Error sending offer",
      error: error.message,
    });
  }
};

export const getContractByProjectId = async (req, res) => {
  try {
    const { projectId } = req.params;
    const userId = req.user.id;

    const contract = await Contract.findOne({
      where: {
        ProjectId: projectId,
        ClientId: userId,
      },
      include: [
        {
          model: Project,
          attributes: ['id', 'title'],
        },
        {
          model: User,
          as: 'freelancer',
          attributes: ['id', 'name', 'avatar', 'email'],
        },
      ],
    });

    if (!contract) {
      return res.status(404).json({
        success: false,
        message: 'Contract not found for this project',
      });
    }

    res.json({
      success: true,
      contract: {
        id: contract.id,
        status: contract.status,
        agreed_amount: contract.agreed_amount,
        escrow_status: contract.escrow_status,
        payment_status: contract.payment_status,
        project: contract.Project,
        freelancer: contract.freelancer,
        created_at: contract.createdAt,
      },
    });
  } catch (err) {
    console.error('Error in getContractByProjectId:', err);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: err.message,
    });
  }
};

export const getOpenProjectsForHiring = async (req, res) => {
  try {
    const clientId = req.user.id;
    const { currentProjectId } = req.query; 

    console.log("🔍 Client ID:", clientId);
    console.log("🎯 Current Project ID:", currentProjectId);

    const allClientProjects = await Project.findAll({
      where: { UserId: clientId },
    });

    console.log(`📊 Total projects for client: ${allClientProjects.length}`);

    if (allClientProjects.length > 0) {
      console.log("📋 Project statuses:");
      allClientProjects.forEach((p) => {
        console.log(
          `   - ID: ${p.id}, Status: "${p.status}", Title: ${p.title}`,
        );
      });
    }

    let openProjects = allClientProjects.filter((p) => p.status === "open");

    if (currentProjectId) {
      const currentProject = allClientProjects.find(
        (p) => p.id == currentProjectId
      );
      
      if (currentProject) {
        const existsInOpen = openProjects.some((p) => p.id == currentProjectId);
        
        if (!existsInOpen) {
          console.log(`📌 Adding current project (ID: ${currentProjectId}, Status: ${currentProject.status}) to list`);
          openProjects.unshift(currentProject); 
        }
      } else {
        console.log(`⚠️ Current project ID ${currentProjectId} not found for this client`);
      }
    }

    console.log(`📊 Final projects count: ${openProjects.length}`);
    console.log(`📊 Project IDs: ${openProjects.map(p => p.id).join(', ')}`);

    res.json({
      success: true,
      projects: openProjects,
      totalProjects: allClientProjects.length,
      openCount: openProjects.filter(p => p.status === "open").length,
    });
  } catch (error) {
    console.error("❌ Error:", error);
    res.status(500).json({
      success: false,
      message: "Error fetching projects",
      error: error.message,
    });
  }
};
