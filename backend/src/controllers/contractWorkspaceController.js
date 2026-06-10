import { Contract, Project, User, WorkSubmission } from "../models/index.js";
import CouponService from "../services/CouponService.js";
import CommissionService from "../services/commissionService.js";

const parseMilestones = (c) => {
  let m = c.milestones;
  if (typeof m === "string") m = JSON.parse(m || "[]");
  return Array.isArray(m) ? m : [];
};
export const requestMilestoneRevision = async (req, res) => {
  try {
    const { contractId, milestoneIndex } = req.params;
    const { revisionMessage } = req.body;
    const clientId = req.user.id;

    const contract = await Contract.findOne({
      where: { id: contractId, ClientId: clientId },
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

    let milestones = contract.milestones;
    if (typeof milestones === "string") {
      milestones = JSON.parse(milestones);
    }

    if (!milestones[milestoneIndex]) {
      return res
        .status(404)
        .json({ success: false, message: "Milestone not found" });
    }

    const milestone = milestones[milestoneIndex];

    if (milestone.status !== "completed") {
      return res
        .status(400)
        .json({ 
          success: false, 
          message: "Can only request revision for completed milestones" 
        });
    }

    if (milestone.status === "approved") {
      return res
        .status(400)
        .json({ 
          success: false, 
          message: "Cannot request revision for already approved milestone" 
        });
    }

    milestones[milestoneIndex].status = "revision_requested";
    milestones[milestoneIndex].revision_message = revisionMessage;
    milestones[milestoneIndex].revision_requested_at = new Date();

    await contract.update({
      milestones: JSON.stringify(milestones),
    });

    await NotificationService.createNotification({
      userId: contract.FreelancerId,
      type: "revision_requested",
      title: "Revision Requested",
      body: revisionMessage || "The client has requested changes to your work.",
      data: {
        contractId: contract.id,
        milestoneIndex: milestoneIndex,
        screen: "contract_progress",
      },
    });

    res.json({
      success: true,
      message: "Revision request sent successfully",
      milestone: milestones[milestoneIndex],
    });
  } catch (error) {
    console.error("Error requesting milestone revision:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const getContractProgress = async (req, res) => {
  try {
    const { contractId } = req.params;
    const uid = req.user.id;

    const contract = await Contract.findByPk(contractId, {
      include: [
        { model: Project, attributes: ["id", "title", "status"] },
        { model: User, as: "freelancer", attributes: ["id", "name", "avatar"] },
        { model: User, as: "client", attributes: ["id", "name", "avatar"] },
      ],
    });

    if (!contract) {
      return res
        .status(404)
        .json({ success: false, message: "Contract not found" });
    }

    if (contract.ClientId !== uid && contract.FreelancerId !== uid) {
      return res.status(403).json({ success: false, message: "Unauthorized" });
    }

    const role = contract.ClientId === uid ? "client" : "freelancer";
    const milestones = parseMilestones(contract);

    const submissions = await WorkSubmission.findAll({
      where: { contract_id: contractId },
      order: [["submitted_at", "DESC"]],
      limit: 50,
    });

    const pendingClient = [];
    const pendingFreelancer = [];

    submissions.forEach((s) => {
      if (s.status === "pending" && role === "client") {
        pendingClient.push({
          type: "review_submission",
          submissionId: s.id,
          title: s.title,
          milestoneIndex: s.milestone_index,
        });
      }
    });

    milestones.forEach((m, index) => {
      const st = m.status || "pending";
      if (
        role === "freelancer" &&
        contract.status === "active" &&
        contract.escrow_status === "funded" &&
        st !== "approved" &&
        st !== "completed"
      ) {
        const hasPending = submissions.some(
          (s) =>
            s.milestone_index === index &&
            (s.status === "pending" || s.status === "revision_requested"),
        );
        if (!hasPending) {
          pendingFreelancer.push({
            type: "submit_deliverable",
            milestoneIndex: index,
            title: m.title,
          });
        }
      }
      if (
        role === "client" &&
        st === "completed" &&
        contract.status === "active"
      ) {
        pendingClient.push({
          type: "approve_milestone",
          milestoneIndex: index,
          title: m.title,
          amount: m.amount,
        });
      }
    });

    const pool =
      contract.funded_escrow_amount != null
        ? parseFloat(contract.funded_escrow_amount)
        : parseFloat(contract.agreed_amount || 0);

    let commissionPreview = null;
    try {
      commissionPreview = await CommissionService.calculateCommission(
        contract.ClientId,
        parseFloat(contract.agreed_amount || 0),
      );
    } catch {
      commissionPreview = { rate: 0.05, amount: 0, platformFee: 0 };
    }

    const timeline = [];

    milestones.forEach((m, index) => {
      if (m.completed_at) {
        timeline.push({
          at: m.completed_at,
          kind: "milestone_completed",
          label: `Milestone completed: ${m.title}`,
          milestoneIndex: index,
        });
      }
      if (m.approved_at) {
        timeline.push({
          at: m.approved_at,
          kind: "milestone_approved",
          label: `Milestone approved: ${m.title}`,
          milestoneIndex: index,
        });
      }
    });

    submissions.forEach((s) => {
      if (s.submitted_at) {
        timeline.push({
          at: s.submitted_at,
          kind: "work_submitted",
          label: `Work submitted: ${s.title}`,
          submissionId: s.id,
          status: s.status,
        });
      }
      if (s.approved_at) {
        timeline.push({
          at: s.approved_at,
          kind: "work_approved",
          label: `Work approved: ${s.title}`,
          submissionId: s.id,
        });
      }
    });

    timeline.sort((a, b) => new Date(b.at || 0) - new Date(a.at || 0));

    res.json({
      success: true,
      role,
      contract: {
        id: contract.id,
        status: contract.status,
        agreed_amount: contract.agreed_amount,
        escrow_status: contract.escrow_status,
        payment_status: contract.payment_status,
        released_amount: contract.released_amount,
        funded_escrow_amount: contract.funded_escrow_amount,
        coupon_code: contract.coupon_code,
        coupon_discount_amount: contract.coupon_discount_amount,
        escrow_pool: pool,
      },
      project: contract.Project
        ? { id: contract.Project.id, title: contract.Project.title }
        : null,
      milestones: milestones.map((m, index) => ({
        index,
        title: m.title,
        status: m.status,
        progress: m.progress ?? 0,
        amount: m.amount,
        due_date: m.due_date,
        completed_at: m.completed_at,
        approved_at: m.approved_at,
      })),
      submissions: submissions.map((s) => ({
        id: s.id,
        title: s.title,
        description: s.description,
        status: s.status,
        milestone_index: s.milestone_index,
        submitted_at: s.submitted_at,
        approved_at: s.approved_at,
        revision_request_message: s.revision_request_message,
      })),
      pending_actions: role === "client" ? pendingClient : pendingFreelancer,
      timeline: timeline.slice(0, 40),
      commission_preview: {
        rate_percent: Math.round((commissionPreview.rate || 0) * 1000) / 10,
        estimated_fee: commissionPreview.platformFee,
        note: "Estimated platform fee when milestone payments are released (depends on your subscription plan).",
      },
    });
  } catch (err) {
    console.error("getContractProgress:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const applyContractCoupon = async (req, res) => {
  try {
    const { contractId } = req.params;
    const { code } = req.body;
    const userId = req.user.id;

    if (!code || typeof code !== "string") {
      return res.status(400).json({
        success: false,
        message: "Coupon code is required",
      });
    }

    const contract = await Contract.findByPk(contractId, {
      include: [{ model: Project }],
    });

    if (!contract || contract.ClientId !== userId) {
      return res.status(404).json({
        success: false,
        message: "Contract not found",
      });
    }

    if (contract.escrow_status !== "pending") {
      return res.status(400).json({
        success: false,
        message: "Coupon can only be applied before escrow is funded",
      });
    }

    const agreed = parseFloat(contract.agreed_amount || 0);
    const validation = await CouponService.validateCoupon(
      code.trim(),
      null,
      "contract",
    );

    if (!validation.valid) {
      return res.status(400).json({
        success: false,
        message: validation.message || "Invalid coupon",
      });
    }

    let discount = 0;
    const d = validation.discount;
    if (d?.type === "percentage") {
      discount = (agreed * parseFloat(d.value)) / 100;
    } else if (d?.type === "amount") {
      discount = parseFloat(d.value);
    }

    discount = Math.min(discount, Math.max(0, agreed - 0.5));
    discount = Math.round(discount * 100) / 100;

    await contract.update({
      coupon_code: validation.coupon.code,
      coupon_discount_amount: discount,
    });

    const chargeAmount = Math.max(0.5, agreed - discount);

    res.json({
      success: true,
      message: "Coupon applied to this contract checkout",
      coupon_code: validation.coupon.code,
      agreed_amount: agreed,
      discount_amount: discount,
      amount_to_pay: chargeAmount,
    });
  } catch (err) {
    console.error("applyContractCoupon:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const removeContractCoupon = async (req, res) => {
  try {
    const { contractId } = req.params;
    const userId = req.user.id;

    const contract = await Contract.findByPk(contractId);
    if (!contract || contract.ClientId !== userId) {
      return res.status(404).json({ success: false, message: "Not found" });
    }
    if (contract.escrow_status !== "pending") {
      return res.status(400).json({
        success: false,
        message: "Cannot remove coupon after payment started",
      });
    }

    await contract.update({
      coupon_code: null,
      coupon_discount_amount: 0,
    });

    res.json({ success: true, message: "Coupon removed" });
  } catch (err) {
    console.error("removeContractCoupon:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
};
