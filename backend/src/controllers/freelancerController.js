// controllers/freelancerController.js
import {
  FreelancerProfile,
  Proposal,
  Project,
  Contract,
  Wallet,
  Message,
  User,
  Transaction,
} from "../models/index.js";
import { Op } from "sequelize";
import multer from "multer";
import path from "path";
import fs from "fs";
import AIService from "../services/aiService.js";
import PaymentService from "../services/paymentService.js";

const parseJSON = (field, defaultValue = []) => {
  try {
    if (!field) return defaultValue;
    if (typeof field === "string") {
      return JSON.parse(field);
    }
    return field;
  } catch (e) {
    console.error("Error parsing JSON:", e);
    return defaultValue;
  }
};

const parseMilestones = (raw) => {
  const out = parseJSON(raw, []);
  return Array.isArray(out) ? out : [];
};

const stringifyJSON = (data) => {
  try {
    if (data === null || data === undefined) return null;
    if (typeof data === "string") return data;
    return JSON.stringify(data);
  } catch (e) {
    console.error("Error stringifying JSON:", e);
    return null;
  }
};

export const getSuggestedProjects = async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 10;

    const suggestedProjects = await suggestProjectsForFreelancer(
      req.user.id,
      limit,
    );

    const aiSuggestions = await getAIPersonalizedSuggestions(req.user.id);

    res.json({
      projects: suggestedProjects,
      aiSuggestions,
      message: "✅ Suggested projects retrieved successfully",
    });
  } catch (err) {
    console.error("Error in getSuggestedProjects:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getMessages = async (req, res) => {
  try {
    const messages = await Message.findAll({
      where: { senderId: req.user.id },
    });
    res.json(messages);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
};

export const updateMilestoneProgress = async (req, res) => {
  try {
    const { contractId, milestoneIndex } = req.params;
    const { progress, status } = req.body;

    const contract = await Contract.findOne({
      where: { id: contractId, FreelancerId: req.user.id },
    });

    if (!contract) {
      return res.status(404).json({ message: "Contract not found" });
    }

    const milestones = parseMilestones(contract.milestones);
    const idx = Number(milestoneIndex);
    const milestone = milestones[idx];

    if (!milestone) {
      return res.status(404).json({ message: "Milestone not found" });
    }

    if (milestone.status === "approved") {
      return res.status(400).json({ message: "Milestone already approved" });
    }

    if (progress !== undefined) {
      milestone.progress = Math.min(100, Math.max(0, parseFloat(progress)));
    }

    if (status === "completed" && milestone.progress >= 100) {
      milestone.status = "completed";
      milestone.completed_at = new Date();

      await NotificationService.createNotification({
        userId: contract.ClientId,
        type: "milestone_completed",
        title: "Milestone Completed",
        body: `"${milestone.title}" has been marked as completed by the freelancer`,
        data: { contractId: contract.id, milestoneIndex, screen: "contract" },
      });
    } else if (status === "in_progress") {
      milestone.status = "in_progress";
    }

    milestones[idx] = milestone;

    await contract.update({ milestones: JSON.stringify(milestones) });

    res.json({
      message: "✅ Milestone progress updated",
      milestone,
      totalProgress:
        milestones.reduce((sum, m) => sum + (m.progress || 0), 0) /
        milestones.length,
    });
  } catch (err) {
    console.error("Error in updateMilestoneProgress:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getWallet = async (req, res) => {
  try {
    console.log("🔍 ===== GET /api/freelancer/wallet =====");
    console.log("📌 User ID:", req.user.id);
    console.log("📌 User Role:", req.user.role);

    let wallet = await Wallet.findOne({ where: { UserId: req.user.id } });
    console.log("📌 Wallet found:", wallet ? "YES" : "NO");

    if (!wallet) {
      console.log("📌 Creating new wallet for UserId:", req.user.id);
      wallet = await Wallet.create({ UserId: req.user.id, balance: 0 });
      console.log("📌 Wallet created:", wallet ? "YES" : "NO");
    }

    const transactions = await Transaction.findAll({
      where: { wallet_id: wallet.id },
      order: [["createdAt", "DESC"]],
      limit: 50,
    });
    console.log("📌 Transactions count:", transactions.length);

    res.json({
      wallet,
      transactions,
    });
  } catch (err) {
    console.error("❌ Error in getWallet:", err);
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

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    let dir = "uploads/";
    if (file.fieldname === "cv") {
      dir = "uploads/cvs";
    } else if (file.fieldname === "avatar") {
      dir = "uploads/avatars";
    }
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    const ext = path.extname(file.originalname);
    cb(null, `${file.fieldname}-${req.user.id}-${uniqueSuffix}${ext}`);
  },
});

export const uploadCV = multer({
  storage: storage,
  fileFilter: (req, file, cb) => {
    if (file.mimetype === "application/pdf") {
      cb(null, true);
    } else {
      cb(new Error("Only PDF files are allowed"));
    }
  },
  limits: { fileSize: 5 * 1024 * 1024 },
}).single("cv");

export const uploadAvatarMiddleware = multer({
  storage: storage,
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif/;
    const extname = allowedTypes.test(
      path.extname(file.originalname).toLowerCase(),
    );
    const mimetype = allowedTypes.test(file.mimetype);
    if (mimetype && extname) {
      cb(null, true);
    } else {
      cb(new Error("Only image files are allowed"));
    }
  },
  limits: { fileSize: 2 * 1024 * 1024 },
}).single("avatar");

export const getProfile = async (req, res) => {
  try {
    console.log("📥 [getProfile] Fetching profile for user:", req.user.id);

    const user = await User.findByPk(req.user.id, {
      attributes: [
        "id",
        "name",
        "email",
        "avatar",
        "role",
        "tagline",
        "bio",
        "location",
        "website",
        "linkedin",
        "github",
        "twitter",
      ],
    });

    if (!user) {
      console.log("❌ [getProfile] User not found");
      return res.status(404).json({ message: "User not found" });
    }

    let profile = await FreelancerProfile.findOne({
      where: { UserId: req.user.id },
    });

    if (!profile) {
      console.log("📝 [getProfile] Creating new profile for user");
      profile = await FreelancerProfile.create({ UserId: req.user.id });
    }

    const skills = parseJSON(profile.skills);
    const languages = parseJSON(profile.languages);
    const education = parseJSON(profile.education);
    const certifications = parseJSON(profile.certifications);
    const workExperience = parseJSON(profile.work_experience);

    const responseData = {
      id: profile.id,
      name: user.name,
      email: user.email,
      avatar: user.avatar,
      tagline: user.tagline || "",
      title: profile.title || "",
      bio: profile.bio || user.bio || "",
      location: profile.location || user.location || "",
      location_coordinates: profile.location_coordinates,
      experience_years: profile.experience_years || 0,
      rating: profile.rating || 0,
      skills: skills,
      languages: languages,
      education: education,
      certifications: certifications,
      work_experience: workExperience,
      cv_url: profile.cv_url,
      is_available: profile.is_available ?? true,
      hourly_rate: profile.hourly_rate,
      availability: profile.availability,
      weekly_hours: profile.weekly_hours,
      completed_projects_count: profile.completed_projects_count || 0,
      website: profile.website || user.website,
      github: profile.github || user.github,
      linkedin: profile.linkedin || user.linkedin,
      behance: profile.behance,
      total_earnings: profile.total_earnings || 0,
      job_success_score: profile.job_success_score || 0,
      response_time: profile.response_time || 0,
    };

    console.log("✅ [getProfile] Profile fetched successfully");
    console.log(
      "📦 [getProfile] Response:",
      JSON.stringify(responseData, null, 2),
    );

    res.json(responseData);
  } catch (err) {
    console.error("❌ [getProfile] Error:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const updateProfile = async (req, res) => {
  try {
    console.log("📥 [updateProfile] Updating profile for user:", req.user.id);
    console.log("📦 [updateProfile] Request body:", req.body);

    const body = { ...req.body };

    const jsonProfileKeys = [
      "skills",
      "languages",
      "education",
      "certifications",
      "work_experience",
      "categories",
      "top_skills",
    ];
    jsonProfileKeys.forEach((field) => {
      if (body[field] !== undefined) {
        if (typeof body[field] === "string") {
          try {
            body[field] = JSON.parse(body[field]);
          } catch {}
        }
        if (Array.isArray(body[field]) || typeof body[field] === "object") {
          body[field] = stringifyJSON(body[field]);
        }
      }
    });

    let social = body.social_links;
    if (social !== undefined) {
      if (typeof social === "string") {
        try {
          social = JSON.parse(social);
        } catch {
          social = {};
        }
      }
      if (social && typeof social === "object") {
        if (social.website) body.website = social.website;
        if (social.github) body.github = social.github;
        if (social.linkedin) body.linkedin = social.linkedin;
        if (social.behance) body.behance = social.behance;
        if (social.dribbble) body.dribbble = social.dribbble;
      }
      body.social_links = stringifyJSON(social);
    }

    const userKeys = [
      "name",
      "tagline",
      "bio",
      "location",
      "website",
      "linkedin",
      "github",
      "twitter",
    ];
    const userUpdate = {};
    userKeys.forEach((k) => {
      if (body[k] !== undefined) userUpdate[k] = body[k];
    });

    const profileKeys = [
      "title",
      "bio",
      "tagline",
      "experience_years",
      "hourly_rate",
      "availability",
      "weekly_hours",
      "is_available",
      "skills",
      "languages",
      "education",
      "certifications",
      "work_experience",
      "categories",
      "top_skills",
      "social_links",
      "location",
      "location_coordinates",
      "website",
      "github",
      "linkedin",
      "behance",
      "dribbble",
    ];
    const profileUpdate = {};
    profileKeys.forEach((k) => {
      if (body[k] !== undefined) profileUpdate[k] = body[k];
    });

    if (Object.keys(userUpdate).length > 0) {
      await User.update(userUpdate, { where: { id: req.user.id } });
    }

    let profile = await FreelancerProfile.findOne({
      where: { UserId: req.user.id },
    });

    if (!profile) {
      console.log("📝 [updateProfile] Creating new profile");
      profile = await FreelancerProfile.create({
        UserId: req.user.id,
        ...profileUpdate,
      });
    } else if (Object.keys(profileUpdate).length > 0) {
      console.log("✏️ [updateProfile] Updating existing profile");
      await profile.update(profileUpdate);
    }

    if (req.file) {
      const avatarUrl = `/uploads/avatars/${req.file.filename}`;
      await User.update({ avatar: avatarUrl }, { where: { id: req.user.id } });
    }

    console.log("✅ [updateProfile] Profile updated successfully");

    res.json({
      message: "✅ Profile updated successfully",
      profile: profile,
    });
  } catch (err) {
    console.error("❌ [updateProfile] Error:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const uploadAvatar = async (req, res) => {
  try {
    console.log("📥 [uploadAvatar] Uploading avatar for user:", req.user.id);

    if (!req.file) {
      return res.status(400).json({ message: "Please upload an image" });
    }

    const avatarUrl = `/uploads/avatars/${req.file.filename}`;

    await User.update({ avatar: avatarUrl }, { where: { id: req.user.id } });

    console.log("✅ [uploadAvatar] Avatar uploaded successfully:", avatarUrl);

    res.json({
      message: "✅ Avatar uploaded successfully",
      avatar: avatarUrl,
    });
  } catch (err) {
    console.error("❌ [uploadAvatar] Error:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const uploadAndAnalyzeCV = async (req, res) => {
  try {
    console.log("📥 [uploadAndAnalyzeCV] Uploading CV for user:", req.user.id);

    if (!req.file) {
      return res.status(400).json({ message: "Please upload a PDF file" });
    }

    console.log("📁 [uploadAndAnalyzeCV] File received:", req.file.filename);
    const cvUrl = `/uploads/cvs/${req.file.filename}`;
    const cvPath = req.file.path;

    let profile = await FreelancerProfile.findOne({
      where: { UserId: req.user.id },
    });

    if (!profile) {
      profile = await FreelancerProfile.create({ UserId: req.user.id });
    }

    await profile.update({ cv_url: cvUrl });

    let aiAnalysis = null;
    try {
      const cvText = await AIService.extractTextFromPDF(cvPath);
      if (cvText) {
        aiAnalysis = await AIService.analyzeCV(cvText);

        if (aiAnalysis) {
          const updateData = {};

          if (aiAnalysis.professional_info?.title) {
            updateData.title = aiAnalysis.professional_info.title;
          }
          if (aiAnalysis.bio) {
            updateData.bio = aiAnalysis.bio;
          }
          if (aiAnalysis.professional_info?.skills) {
            updateData.skills = stringifyJSON(
              aiAnalysis.professional_info.skills,
            );
          }
          if (aiAnalysis.professional_info?.languages) {
            updateData.languages = stringifyJSON(
              aiAnalysis.professional_info.languages,
            );
          }
          if (aiAnalysis.education) {
            updateData.education = stringifyJSON(aiAnalysis.education);
          }
          if (aiAnalysis.professional_info?.certifications) {
            updateData.certifications = stringifyJSON(
              aiAnalysis.professional_info.certifications,
            );
          }

          if (Object.keys(updateData).length > 0) {
            await profile.update(updateData);
          }
        }
      }
    } catch (aiError) {
      console.error(
        "⚠️ [uploadAndAnalyzeCV] AI analysis failed:",
        aiError.message,
      );
    }

    const updatedProfile = await FreelancerProfile.findOne({
      where: { UserId: req.user.id },
    });

    const user = await User.findByPk(req.user.id);

    console.log("✅ [uploadAndAnalyzeCV] CV uploaded successfully");

    res.json({
      message: "✅ CV uploaded and analyzed successfully",
      profile: {
        id: updatedProfile.id,
        cv_url: updatedProfile.cv_url,
        title: updatedProfile.title,
        bio: updatedProfile.bio,
        skills: parseJSON(updatedProfile.skills),
        languages: parseJSON(updatedProfile.languages),
        education: parseJSON(updatedProfile.education),
        certifications: parseJSON(updatedProfile.certifications),
        aiAnalysis: aiAnalysis
          ? {
              title: aiAnalysis.professional_info?.title,
              skills: aiAnalysis.professional_info?.skills,
              languages: aiAnalysis.professional_info?.languages,
              education: aiAnalysis.education,
              certifications: aiAnalysis.professional_info?.certifications,
              bio: aiAnalysis.bio,
              confidence: aiAnalysis.confidence_score,
            }
          : null,
      },
    });
  } catch (err) {
    console.error("❌ [uploadAndAnalyzeCV] Error:", err);
    res.status(500).json({
      message: "Server error",
      error: err.message,
    });
  }
};

export const updateLocation = async (req, res) => {
  try {
    console.log("📥 [updateLocation] Updating location for user:", req.user.id);
    console.log("📦 [updateLocation] Request body:", req.body);

    const { lat, lng, address } = req.body;

    if (!lat || !lng) {
      return res
        .status(400)
        .json({ message: "Latitude and longitude are required" });
    }

    const coordinates = `${lat},${lng}`;

    let profile = await FreelancerProfile.findOne({
      where: { UserId: req.user.id },
    });

    if (!profile) {
      profile = await FreelancerProfile.create({
        UserId: req.user.id,
        location: address || `${lat},${lng}`,
        location_coordinates: coordinates,
      });
    } else {
      await profile.update({
        location: address || `${lat},${lng}`,
        location_coordinates: coordinates,
      });
    }

    console.log("✅ [updateLocation] Location updated successfully");

    res.json({
      message: "✅ Location updated successfully",
      location: address,
      coordinates,
    });
  } catch (err) {
    console.error("❌ [updateLocation] Error:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getFreelancerStats = async (req, res) => {
  try {
    console.log(
      "📥 [getFreelancerStats] Fetching stats for user:",
      req.user.id,
    );

    const userId = req.user.id;

    const completedProjects = await Contract.count({
      where: { FreelancerId: userId, status: "completed" },
    });

    const activeProjects = await Contract.count({
      where: { FreelancerId: userId, status: "active" },
    });

    const totalProposals = await Proposal.count({
      where: { UserId: userId },
    });

    const acceptedProposals = await Proposal.count({
      where: { UserId: userId, status: "accepted" },
    });

    const profile = await FreelancerProfile.findOne({
      where: { UserId: userId },
      attributes: ["rating", "total_earnings"],
    });

    const totalEarnings = profile?.total_earnings || 0;

    console.log("✅ [getFreelancerStats] Stats fetched successfully");

    res.json({
      stats: {
        completedProjects,
        activeProjects,
        totalProposals,
        acceptedProposals,
        totalEarnings: parseFloat(totalEarnings),
        acceptanceRate:
          totalProposals > 0
            ? ((acceptedProposals / totalProposals) * 100).toFixed(1)
            : 0,
        rating: profile?.rating || 0,
      },
    });
  } catch (err) {
    console.error("❌ [getFreelancerStats] Error:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getFreelancerContracts = async (req, res) => {
  try {
    console.log(
      "📥 [getFreelancerContracts] Fetching contracts for user:",
      req.user.id,
    );

    const contracts = await Contract.findAll({
      where: { FreelancerId: req.user.id },
      include: [
        {
          model: Project,
          include: [
            {
              model: User,
              as: "client",
              attributes: ["id", "name", "avatar", "email"],
            },
          ],
        },
      ],
      order: [["createdAt", "DESC"]],
    });

    console.log(
      `✅ [getFreelancerContracts] Found ${contracts.length} contracts`,
    );

    res.json(contracts);
  } catch (err) {
    console.error("❌ [getFreelancerContracts] Error:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getProjects = async (req, res) => {
  try {
    console.log(
      "📥 [getProjects] Fetching projects for freelancer:",
      req.user.id,
    );

    const contracts = await Contract.findAll({
      where: {
        FreelancerId: req.user.id,
        status: {
          [Op.in]: [
            "draft",
            "pending_client",
            "pending_freelancer",
            "active",
            "completed",
          ],
        },
      },
      include: [
        {
          model: Project,
          include: [
            {
              model: User,
              as: "client",
              attributes: ["id", "name", "avatar", "email"],
            },
          ],
        },
      ],
    });

    const projects = contracts
      .filter((c) => c.Project)
      .map((c) => ({
        ...c.Project.toJSON(),
        contractId: c.id,
        contractStatus: c.status,
        escrowStatus: c.escrow_status,
      }));

    console.log(`✅ [getProjects] Found ${projects.length} active projects`);

    res.json(projects);
  } catch (err) {
    console.error("❌ [getProjects] Error:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getProjectContract = async (req, res) => {
  try {
    const projectId = parseInt(req.params.projectId);
    if (!projectId) {
      return res.status(400).json({ message: "Invalid projectId" });
    }

    const contract = await Contract.findOne({
      where: {
        ProjectId: projectId,
        FreelancerId: req.user.id,
        status: {
          [Op.in]: [
            "draft",
            "pending_client",
            "pending_freelancer",
            "active",
            "completed",
          ],
        },
      },
      attributes: ["id", "status", "escrow_status", "ProjectId"],
    });

    if (!contract) {
      return res.json({ success: true, contract: null });
    }

    return res.json({
      success: true,
      contract: {
        id: contract.id,
        status: contract.status,
        escrow_status: contract.escrow_status,
        projectId: contract.ProjectId,
      },
    });
  } catch (err) {
    console.error("❌ [getProjectContract] Error:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getProposals = async (req, res) => {
  try {
    console.log(
      "📥 [getProposals] Fetching proposals for freelancer:",
      req.user.id,
    );

    const proposals = await Proposal.findAll({
      where: { UserId: req.user.id },
      include: [
        {
          model: Project,
          include: [
            {
              model: User,
              as: "client",
              attributes: ["id", "name", "avatar", "email"],
            },
          ],
        },
      ],
      order: [["createdAt", "DESC"]],
    });

    console.log(`✅ [getProposals] Found ${proposals.length} proposals`);

    res.json(proposals);
  } catch (err) {
    console.error("❌ [getProposals] Error:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getAISuggestedProjects = async (req, res) => {
  try {
    console.log(
      "📥 [getAISuggestedProjects] Getting AI suggestions for user:",
      req.user.id,
    );

    const limit = parseInt(req.query.limit) || 10;

    const profile = await FreelancerProfile.findOne({
      where: { UserId: req.user.id },
    });

    const skills = parseJSON(profile?.skills, []);

    let projects = [];

    if (skills.length > 0) {
      const skillConditions = skills.map((skill) => ({
        skills: { [Op.like]: `%${skill}%` },
      }));

      const matchingProjects = await Project.findAll({
        where: {
          status: "open",
          [Op.or]: skillConditions,
        },
        include: [
          {
            model: User,
            as: "client",
            attributes: ["id", "name", "avatar", "email"],
          },
        ],
        limit: limit,
        order: [["createdAt", "DESC"]],
      });

      projects = matchingProjects;
    } else {
      projects = await Project.findAll({
        where: { status: "open" },
        include: [
          {
            model: User,
            as: "client",
            attributes: ["id", "name", "avatar", "email"],
          },
        ],
        limit: limit,
        order: [["createdAt", "DESC"]],
      });
    }

    const projectsWithScores = projects.map((project) => {
      const projectSkills = parseJSON(project.skills, []);
      let matchScore = 0;

      if (skills.length > 0 && projectSkills.length > 0) {
        const matchingSkills = skills.filter((skill) =>
          projectSkills.some((ps) =>
            ps.toLowerCase().includes(skill.toLowerCase()),
          ),
        );
        matchScore = Math.round(
          (matchingSkills.length /
            Math.max(skills.length, projectSkills.length)) *
            100,
        );
      }

      return {
        ...project.toJSON(),
        matchScore: matchScore,
      };
    });

    projectsWithScores.sort((a, b) => b.matchScore - a.matchScore);

    console.log(
      `✅ [getAISuggestedProjects] Found ${projectsWithScores.length} suggestions`,
    );

    res.json({
      success: true,
      suggestions: projectsWithScores,
      message: "✅ AI suggestions generated",
    });
  } catch (err) {
    console.error("❌ [getAISuggestedProjects] Error:", err);
    res.json({
      success: false,
      suggestions: [],
      message: "Could not generate AI suggestions",
    });
  }
};

export const searchFreelancers = async (req, res) => {
  try {
    const {
      q = "",
      skill = "",
      minRating = 0,
      maxHourlyRate = 500,
      minExperience = 0,
      sortBy = "rating",
      page = 1,
      limit = 20,
    } = req.query;

    console.log("🔍 Search params:", {
      q,
      skill,
      minRating,
      maxHourlyRate,
      minExperience,
      sortBy,
      page,
      limit,
    });

    let whereClause = { role: "freelancer" };

    if (q) {
      whereClause.name = { [Op.like]: `%${q}%` };
    }

    const offset = (parseInt(page) - 1) * parseInt(limit);

    const { count, rows: users } = await User.findAndCountAll({
      where: whereClause,
      attributes: [
        "id",
        "name",
        "email",
        "avatar",
        "role",
        "bio",
        "location",
        "createdAt",
      ],
      limit: parseInt(limit),
      offset: offset,
      order: [["createdAt", "DESC"]],
    });

    const userIds = users.map((u) => u.id);

    let profiles = [];
    if (userIds.length > 0) {
      profiles = await FreelancerProfile.findAll({
        where: { UserId: { [Op.in]: userIds } },
      });
    }

    const profileMap = new Map();
    profiles.forEach((profile) => {
      profileMap.set(profile.UserId, profile);
    });

    let freelancers = users.map((user) => {
      const profile = profileMap.get(user.id);

      let skills = [];
      if (profile?.skills) {
        try {
          skills =
            typeof profile.skills === "string"
              ? JSON.parse(profile.skills)
              : profile.skills;
        } catch (e) {
          skills = [];
        }
      }

      return {
        id: user.id,
        name: user.name,
        avatar: user.avatar,
        title: profile?.title || "Professional Freelancer",
        rating: profile?.rating || 0,
        skills: skills,
        experience: profile?.experience_years || 0,
        completedProjects: profile?.completed_projects_count || 0,
        hourlyRate: profile?.hourly_rate || 0,
        bio: user.bio || profile?.bio || "",
        location: user.location || profile?.location || "",
      };
    });

    if (skill) {
      freelancers = freelancers.filter((f) =>
        f.skills.some((s) => s.toLowerCase().includes(skill.toLowerCase())),
      );
    }

    if (minRating > 0) {
      freelancers = freelancers.filter(
        (f) => f.rating >= parseFloat(minRating),
      );
    }

    if (minExperience > 0) {
      freelancers = freelancers.filter(
        (f) => f.experience >= parseInt(minExperience),
      );
    }

    if (maxHourlyRate < 500) {
      freelancers = freelancers.filter(
        (f) => f.hourlyRate <= parseFloat(maxHourlyRate),
      );
    }

    switch (sortBy) {
      case "rating":
        freelancers.sort((a, b) => b.rating - a.rating);
        break;
      case "hourlyRate_asc":
        freelancers.sort((a, b) => a.hourlyRate - b.hourlyRate);
        break;
      case "hourlyRate_desc":
        freelancers.sort((a, b) => b.hourlyRate - a.hourlyRate);
        break;
      case "experience_desc":
        freelancers.sort((a, b) => b.experience - a.experience);
        break;
      default:
        freelancers.sort((a, b) => b.rating - a.rating);
    }

    const totalFiltered = freelancers.length;
    const paginatedFreelancers = freelancers.slice(
      offset,
      offset + parseInt(limit),
    );

    console.log(
      `✅ Found ${totalFiltered} freelancers, returning ${paginatedFreelancers.length}`,
    );

    res.json({
      success: true,
      freelancers: paginatedFreelancers,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: totalFiltered,
        pages: Math.ceil(totalFiltered / parseInt(limit)),
      },
    });
  } catch (error) {
    console.error("Search freelancers error:", error);
    res.status(500).json({
      success: false,
      message: "Error searching freelancers",
      error: error.message,
    });
  }
};

export const compareFreelancers = async (req, res) => {
  try {
    const { freelancerIds, projectId } = req.body;

    if (!freelancerIds || freelancerIds.length < 2) {
      return res.status(400).json({
        success: false,
        message: "Please select at least 2 freelancers to compare",
      });
    }

    let project = null;
    if (projectId && projectId !== 0) {
      project = await Project.findByPk(projectId);
    }

    const freelancers = await User.findAll({
      where: {
        id: { [Op.in]: freelancerIds },
        role: "freelancer",
      },
      include: [
        {
          model: FreelancerProfile,
          as: "freelancerProfile",
        },
      ],
      attributes: ["id", "name", "avatar"],
    });

    if (freelancers.length < 2) {
      return res.status(404).json({
        success: false,
        message: "Freelancers not found",
      });
    }

    const comparisons = await Promise.all(
      freelancers.map(async (freelancer) => {
        const profile = freelancer.freelancerProfile;
        const skills = profile?.skills ? parseJSON(profile.skills) : [];

        let skillsMatch = 0;
        if (project) {
          const rawProjectSkills =
            project.skills || project.required_skills || [];
          const projectSkills = Array.isArray(rawProjectSkills)
            ? rawProjectSkills
            : parseJSON(rawProjectSkills, []);

          const matchingSkills = skills.filter((skill) =>
            projectSkills.some(
              (ps) => ps.toLowerCase() === skill.toLowerCase(),
            ),
          );
          skillsMatch =
            projectSkills.length > 0
              ? Math.round((matchingSkills.length / projectSkills.length) * 100)
              : 0;
        }

        const contracts = await Contract.findAll({
          where: { FreelancerId: freelancer.id },
        });

        const completedContracts = contracts.filter(
          (c) => c.status === "completed",
        );
        const onTimeContracts = contracts.filter((c) => {
          if (c.status === "completed" && c.completed_at) {
            return true;
          }
          return false;
        });

        const completionRate =
          contracts.length > 0
            ? Math.round((completedContracts.length / contracts.length) * 100)
            : 0;

        const onTimeDelivery =
          contracts.length > 0
            ? Math.round((onTimeContracts.length / contracts.length) * 100)
            : 0;

        let responseTimeHours = 24;

        const overallScore = Math.round(
          (profile?.rating || 0) * 20 +
            skillsMatch * 0.25 +
            completionRate * 0.2 +
            onTimeDelivery * 0.15 +
            (profile?.experience_years || 0) * 2,
        );

        return {
          id: freelancer.id,
          name: freelancer.name,
          avatar: freelancer.avatar,
          title: profile?.title || "Professional Freelancer",
          rating: profile?.rating || 0,
          skills: skills,
          experience: profile?.experience_years || 0,
          completedProjects: profile?.completed_projects_count || 0,
          completionRate,
          onTimeDelivery,
          responseTimeHours,
          hourlyRate: profile?.hourly_rate || 0,
          totalReviews: 0,
          skillsMatch,
          projectBudget: project?.budget || 0,
          overallScore: Math.min(100, overallScore),
        };
      }),
    );

    res.json({
      success: true,
      comparisons,
    });
  } catch (error) {
    console.error("Compare freelancers error:", error);
    res.status(500).json({
      success: false,
      message: "Error comparing freelancers",
      error: error.message,
    });
  }
};

export const getFreelancerPreview = async (req, res) => {
  try {
    const { id } = req.params;
    const { projectId } = req.query;

    const user = await User.findByPk(id, {
      attributes: [
        "id",
        "name",
        "email",
        "avatar",
        "role",
        "bio",
        "location",
        "createdAt",
      ],
    });

    if (!user || user.role !== "freelancer") {
      return res.status(404).json({
        success: false,
        message: "Freelancer not found",
      });
    }

    const profile = await FreelancerProfile.findOne({
      where: { UserId: user.id },
    });

    const skills = profile?.skills
      ? typeof profile.skills === "string"
        ? JSON.parse(profile.skills)
        : profile.skills
      : [];
    const languages = profile?.languages
      ? typeof profile.languages === "string"
        ? JSON.parse(profile.languages)
        : profile.languages
      : [];
    const education = profile?.education
      ? typeof profile.education === "string"
        ? JSON.parse(profile.education)
        : profile.education
      : [];
    const certifications = profile?.certifications
      ? typeof profile.certifications === "string"
        ? JSON.parse(profile.certifications)
        : profile.certifications
      : [];
    const workExperience = profile?.work_experience
      ? typeof profile.work_experience === "string"
        ? JSON.parse(profile.work_experience)
        : profile.work_experience
      : [];

    const contracts = await Contract.findAll({
      where: { FreelancerId: user.id },
    });

    const completedContracts = contracts.filter(
      (c) => c.status === "completed",
    );
    const activeContracts = contracts.filter((c) => c.status === "active");

    const completionRate =
      contracts.length > 0
        ? Math.round((completedContracts.length / contracts.length) * 100)
        : 0;

    let skillsMatch = 0;
    if (projectId && projectId !== 0) {
      const project = await Project.findByPk(projectId);
      if (project && project.required_skills) {
        let projectSkills = [];
        try {
          projectSkills =
            typeof project.required_skills === "string"
              ? JSON.parse(project.required_skills)
              : project.required_skills || [];
        } catch (e) {
          projectSkills = [];
        }

        const matchingSkills = skills.filter((skill) =>
          projectSkills.some((ps) => ps.toLowerCase() === skill.toLowerCase()),
        );
        skillsMatch =
          projectSkills.length > 0
            ? Math.round((matchingSkills.length / projectSkills.length) * 100)
            : 0;
      }
    }

    res.json({
      success: true,
      freelancer: {
        id: user.id,
        name: user.name,
        avatar: user.avatar,
        title: profile?.title || "Professional Freelancer",
        bio: profile?.bio || user.bio || "",
        rating: profile?.rating || 0,
        skills: skills,
        experience: profile?.experience_years || 0,
        hourlyRate: profile?.hourly_rate || 0,
        completedProjects: profile?.completed_projects_count || 0,
        location: profile?.location || user.location || "",
        education: education,
        certifications: certifications,
        languages: languages,
        workExperience: workExperience,
        memberSince: user.createdAt,
        stats: {
          completionRate,
          activeProjects: activeContracts.length,
          totalProjects: contracts.length,
          totalEarned: contracts.reduce(
            (sum, c) => sum + (c.agreed_amount || 0),
            0,
          ),
        },
        skillsMatch,
      },
    });
  } catch (error) {
    console.error("Get freelancer preview error:", error);
    res.status(500).json({
      success: false,
      message: "Error fetching freelancer profile",
      error: error.message,
    });
  }
};

export const getTopFreelancers = async (req, res) => {
  try {
    const { limit = 10, skill } = req.query;

    let whereClause = { role: "freelancer" };

    const users = await User.findAll({
      where: whereClause,
      attributes: ["id", "name", "email", "avatar", "role"],
      limit: 100,
    });

    const userIds = users.map((u) => u.id);
    const profiles = await FreelancerProfile.findAll({
      where: { UserId: { [Op.in]: userIds } },
    });

    const profileMap = new Map();
    profiles.forEach((profile) => {
      profileMap.set(profile.UserId, profile);
    });

    let freelancers = users.map((user) => {
      const profile = profileMap.get(user.id);

      let skills = [];
      if (profile?.skills) {
        try {
          skills =
            typeof profile.skills === "string"
              ? JSON.parse(profile.skills)
              : profile.skills;
        } catch (e) {
          skills = [];
        }
      }

      return {
        id: user.id,
        name: user.name,
        avatar: user.avatar,
        title: profile?.title || "Professional Freelancer",
        rating: profile?.rating || 0,
        skills: skills,
        hourlyRate: profile?.hourly_rate || 0,
        completedProjects: profile?.completed_projects_count || 0,
      };
    });

    if (skill) {
      freelancers = freelancers.filter((f) =>
        f.skills.some((s) => s.toLowerCase().includes(skill.toLowerCase())),
      );
    }

    freelancers.sort((a, b) => {
      if (b.rating !== a.rating) return b.rating - a.rating;
      return b.completedProjects - a.completedProjects;
    });

    freelancers = freelancers.slice(0, parseInt(limit));

    res.json({
      success: true,
      freelancers: freelancers,
    });
  } catch (error) {
    console.error("Get top freelancers error:", error);
    res.status(500).json({
      success: false,
      message: "Error fetching top freelancers",
      error: error.message,
    });
  }
};

export const getFreelancerStatsForClient = async (req, res) => {
  try {
    const { id } = req.params;

    const user = await User.findByPk(id, {
      include: [
        {
          model: FreelancerProfile,
          as: "freelancerProfile",
        },
      ],
    });

    if (!user || user.role !== "freelancer") {
      return res.status(404).json({
        success: false,
        message: "Freelancer not found",
      });
    }

    const profile = user.freelancerProfile;
    const contracts = await Contract.findAll({
      where: { FreelancerId: user.id },
    });

    const completedContracts = contracts.filter(
      (c) => c.status === "completed",
    );
    const activeContracts = contracts.filter((c) => c.status === "active");

    res.json({
      success: true,
      stats: {
        totalProjects: contracts.length,
        completedProjects: completedContracts.length,
        activeProjects: activeContracts.length,
        completionRate:
          contracts.length > 0
            ? Math.round((completedContracts.length / contracts.length) * 100)
            : 0,
        totalEarned: contracts.reduce(
          (sum, c) => sum + (c.agreed_amount || 0),
          0,
        ),
        avgResponseTimeHours: 24,
        onTimeDeliveryRate: profile?.job_success_score || 0,
        rating: profile?.rating || 0,
      },
    });
  } catch (error) {
    console.error("Get freelancer stats error:", error);
    res.status(500).json({
      success: false,
      message: "Error fetching freelancer stats",
      error: error.message,
    });
  }
};
