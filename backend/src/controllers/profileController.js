import {
  User,
  FreelancerProfile,
  ClientProfile,
  Contract,
  Project,
  Rating,
  Portfolio,
  Proposal,
} from "../models/index.js";
import { Op } from "sequelize";
import { sequelize } from "../config/db.js";
import multer from "multer";
import path from "path";
import fs from "fs";

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const dir =
      file.fieldname === "cover" ? "uploads/covers" : "uploads/avatars";
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    const suffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    cb(
      null,
      `${file.fieldname}-${req.user.id}-${suffix}${path.extname(file.originalname)}`,
    );
  },
});

export const uploadProfileImages = multer({
  storage,
  fileFilter: (req, file, cb) => {
    const allowed = /jpeg|jpg|png|webp/;
    cb(
      null,
      allowed.test(path.extname(file.originalname).toLowerCase()) &&
        allowed.test(file.mimetype),
    );
  },
  limits: { fileSize: 5 * 1024 * 1024 },
}).fields([
  { name: "avatar", maxCount: 1 },
  { name: "cover", maxCount: 1 },
]);

const parseJSON = (val, fallback = []) => {
  try {
    return val ? (typeof val === "string" ? JSON.parse(val) : val) : fallback;
  } catch {
    return fallback;
  }
};

const calcFreelancerStrength = (profile, user) => {
  let score = 0;
  if (user?.name) score += 10;
  if (user?.avatar) score += 10;
  if (profile?.title) score += 10;
  if (profile?.bio && profile.bio.length > 50) score += 10;
  if (parseJSON(profile?.skills).length >= 3) score += 15;
  if (profile?.hourly_rate) score += 10;
  if (profile?.cv_url) score += 10;
  if (parseJSON(profile?.education).length > 0) score += 10;
  if (parseJSON(profile?.work_experience).length > 0) score += 10;
  if (user?.linkedin || user?.github) score += 5;
  return Math.min(score, 100);
};

const calcClientStrength = (profile, user) => {
  let score = 0;
  if (user?.name) score += 10;
  if (user?.avatar) score += 15;
  if (profile?.company_name) score += 15;
  if (profile?.bio && profile.bio.length > 30) score += 15;
  if (profile?.industry) score += 10;
  if (profile?.location) score += 10;
  if (profile?.payment_verified) score += 15;
  if (user?.phone) score += 10;
  return Math.min(score, 100);
};

export const getMyFreelancerProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const user = await User.findByPk(userId, {
      attributes: {
        exclude: [
          "password",
          "verification_code",
          "reset_password_token",
          "reset_password_expires",
        ],
      },
    });

    let profile = await FreelancerProfile.findOne({
      where: { UserId: userId },
    });
    if (!profile) {
      profile = await FreelancerProfile.create({ UserId: userId });
    }

    const strength = calcFreelancerStrength(profile, user);
    await profile.update({ profile_strength: strength });

    const completedContracts = await Contract.count({
      where: { FreelancerId: userId, status: "completed" },
    });
    const totalEarned = await Contract.sum("released_amount", {
      where: { FreelancerId: userId, status: "completed" },
    });
    const recentCompletedContracts = await Contract.findAll({
      where: { FreelancerId: userId, status: "completed" },
      include: [
        {
          model: Project,
          attributes: ["id", "title", "category", "budget"],
          required: false,
        },
      ],
      attributes: ["id", "ProjectId", "agreed_amount", "end_date", "updatedAt"],
      order: [
        ["end_date", "DESC"],
        ["updatedAt", "DESC"],
      ],
      limit: 8,
    });

    res.json({
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        avatar: user.avatar,
        cover_image: user.cover_image,
        tagline: user.tagline,
        bio: user.bio,
        location: user.location,
        country: user.country,
        timezone: user.timezone,
        phone: user.phone,
        website: user.website,
        linkedin: user.linkedin,
        github: user.github,
        twitter: user.twitter,
        is_verified: user.is_verified,
      },
      profile: {
        id: profile.id,
        title: profile.title,
        bio: profile.bio,
        tagline: profile.tagline,
        skills: parseJSON(profile.skills),
        top_skills: parseJSON(profile.top_skills),
        categories: parseJSON(profile.categories),
        experience_years: profile.experience_years,
        hourly_rate: profile.hourly_rate,
        availability: profile.availability,
        weekly_hours: profile.weekly_hours,
        languages: parseJSON(profile.languages),
        education: parseJSON(profile.education),
        certifications: parseJSON(profile.certifications),
        work_experience: parseJSON(profile.work_experience),
        social_links: parseJSON(profile.social_links, {}),
        cv_url: profile.cv_url,
        is_available: profile.is_available,
        profile_strength: strength,
        website: profile.website,
        github: profile.github,
        linkedin: profile.linkedin,
        behance: profile.behance,
        dribbble: profile.dribbble,
      },
      stats: {
        rating: profile.rating || 0,
        total_reviews: profile.total_reviews || 0,
        completed_projects: completedContracts || 0,
        total_earnings: totalEarned || 0,
        job_success_score: profile.job_success_score || 0,
        response_time: profile.response_time || 0,
      },
      recent_completed_projects: recentCompletedContracts.map((c) => ({
        contract_id: c.id,
        project_id: c.ProjectId,
        title: c.Project?.title || `Project #${c.ProjectId}`,
        category: c.Project?.category || null,
        budget: c.Project?.budget || c.agreed_amount || null,
        delivered_at: c.end_date || c.updatedAt,
      })),
    });
  } catch (err) {
    console.error("getMyFreelancerProfile:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const updateFreelancerProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const body = req.body;

    const userFields = [
      "name",
      "tagline",
      "bio",
      "location",
      "country",
      "timezone",
      "phone",
      "website",
      "linkedin",
      "github",
      "twitter",
    ];
    const userUpdate = {};
    userFields.forEach((f) => {
      if (body[f] !== undefined) userUpdate[f] = body[f];
    });

    if (req.files?.avatar?.[0])
      userUpdate.avatar = `/uploads/avatars/${req.files.avatar[0].filename}`;
    if (req.files?.cover?.[0])
      userUpdate.cover_image = `/uploads/covers/${req.files.cover[0].filename}`;

    if (Object.keys(userUpdate).length > 0) {
      await User.update(userUpdate, { where: { id: userId } });
    }

    const profileFields = [
      "title",
      "tagline",
      "bio",
      "experience_years",
      "hourly_rate",
      "availability",
      "weekly_hours",
      "is_available",
      "website",
      "github",
      "linkedin",
      "behance",
      "dribbble",
    ];
    const jsonFields = [
      "skills",
      "top_skills",
      "languages",
      "education",
      "certifications",
      "work_experience",
      "categories",
      "social_links",
    ];
    const profileUpdate = {};

    profileFields.forEach((f) => {
      if (body[f] !== undefined) profileUpdate[f] = body[f];
    });
    jsonFields.forEach((f) => {
      if (body[f] !== undefined) {
        profileUpdate[f] =
          Array.isArray(body[f]) || typeof body[f] === "object"
            ? JSON.stringify(body[f])
            : body[f];
      }
    });

    let profile = await FreelancerProfile.findOne({
      where: { UserId: userId },
    });
    if (!profile) {
      profile = await FreelancerProfile.create({
        UserId: userId,
        ...profileUpdate,
      });
    } else {
      await profile.update(profileUpdate);
    }

    const user = await User.findByPk(userId);
    const strength = calcFreelancerStrength(profile, user);
    await profile.update({ profile_strength: strength });

    res.json({ message: "✅ Profile updated", profile_strength: strength });
  } catch (err) {
    console.error("updateFreelancerProfile:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getClientPublicProfile = async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await User.findByPk(userId, {
      attributes: [
        "id",
        "name",
        "avatar",
        "cover_image",
        "tagline",
        "bio",
        "location",
        "website",
        "linkedin",
        "profile_views",
        "last_seen",
        "createdAt",
      ],
    });
    if (!user) return res.status(404).json({ message: "User not found" });

    if (req.user?.id !== parseInt(userId))
      await user.increment("profile_views");

    let profile = await ClientProfile.findOne({ where: { UserId: userId } });

    const projects = await Project.findAll({
      where: { UserId: userId },
      attributes: ["id", "title", "status", "budget", "category", "createdAt"],
      order: [["createdAt", "DESC"]],
      limit: 10,
    });

    const completedContracts = await Contract.findAll({
      where: { ClientId: userId, status: "completed" },
      attributes: ["agreed_amount", "createdAt"],
    });

    const totalSpent = completedContracts.reduce(
      (s, c) => s + parseFloat(c.agreed_amount || 0),
      0,
    );

    const givenRatings = await Rating.findAll({
      where: { fromUserId: userId, role: "client" },
      attributes: ["rating"],
    });
    const avgGivenRating =
      givenRatings.length > 0
        ? givenRatings.reduce((s, r) => s + r.rating, 0) / givenRatings.length
        : 0;

    res.json({
      user: {
        id: user.id,
        name: user.name,
        avatar: user.avatar,
        cover_image: user.cover_image,
        tagline: user.tagline,
        bio: user.bio,
        location: user.location,
        website: user.website,
        linkedin: user.linkedin,
        last_seen: user.last_seen,
        member_since: user.createdAt,
        profile_views: user.profile_views,
      },
      profile: profile
        ? {
            company_name: profile.company_name,
            company_size: profile.company_size,
            company_website: profile.company_website,
            company_description: profile.company_description,
            company_logo: profile.company_logo,
            industry: profile.industry,
            founded_year: profile.founded_year,
            tagline: profile.tagline,
            bio: profile.bio,
            location: profile.location,
            country: profile.country,
            payment_verified: profile.payment_verified,
            id_verified: profile.id_verified,
            preferred_skills: parseJSON(profile.preferred_skills),
            hiring_for: parseJSON(profile.hiring_for),
            preferred_contract_type: profile.preferred_contract_type,
            linkedin: profile.linkedin,
            twitter: profile.twitter,
            profile_strength: profile.profile_strength,
          }
        : null,
      stats: {
        total_projects: projects.length,
        completed_contracts: completedContracts.length,
        total_spent: totalSpent,
        avg_rating_given: Math.round(avgGivenRating * 10) / 10,
        active_projects: projects.filter((p) => p.status === "in_progress")
          .length,
        open_projects: projects.filter((p) => p.status === "open").length,
        hire_rate: profile?.hire_rate || 0,
      },
      recent_projects: projects.map((p) => ({
        id: p.id,
        title: p.title,
        status: p.status,
        budget: p.budget,
        category: p.category,
        createdAt: p.createdAt,
      })),
    });
  } catch (err) {
    console.error("getClientPublicProfile:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getMyClientProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const user = await User.findByPk(userId, {
      attributes: {
        exclude: [
          "password",
          "verification_code",
          "reset_password_token",
          "reset_password_expires",
        ],
      },
    });

    let profile = await ClientProfile.findOne({ where: { UserId: userId } });
    if (!profile) profile = await ClientProfile.create({ UserId: userId });

    const strength = calcClientStrength(profile, user);
    await profile.update({ profile_strength: strength });

    const stats = {
      total_projects: await Project.count({ where: { UserId: userId } }),
      open_projects: await Project.count({
        where: { UserId: userId, status: "open" },
      }),
      active_projects: await Project.count({
        where: { UserId: userId, status: "in_progress" },
      }),
      completed_projects: await Project.count({
        where: { UserId: userId, status: "completed" },
      }),
      total_spent:
        (await Contract.sum("agreed_amount", {
          where: { ClientId: userId, status: "completed" },
        })) || 0,
      active_contracts: await Contract.count({
        where: { ClientId: userId, status: "active" },
      }),
    };

    res.json({
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        avatar: user.avatar,
        cover_image: user.cover_image,
        tagline: user.tagline,
        bio: user.bio,
        location: user.location,
        country: user.country,
        timezone: user.timezone,
        phone: user.phone,
        website: user.website,
        linkedin: user.linkedin,
        twitter: user.twitter,
        is_verified: user.is_verified,
      },
      profile: {
        company_name: profile.company_name,
        company_size: profile.company_size,
        company_website: profile.company_website,
        company_description: profile.company_description,
        company_logo: profile.company_logo,
        industry: profile.industry,
        founded_year: profile.founded_year,
        tagline: profile.tagline,
        bio: profile.bio,
        location: profile.location,
        country: profile.country,
        timezone: profile.timezone,
        phone: profile.phone,
        payment_verified: profile.payment_verified,
        id_verified: profile.id_verified,
        preferred_skills: parseJSON(profile.preferred_skills),
        hiring_for: parseJSON(profile.hiring_for),
        preferred_contract_type: profile.preferred_contract_type,
        budget_range_min: profile.budget_range_min,
        budget_range_max: profile.budget_range_max,
        linkedin: profile.linkedin,
        twitter: profile.twitter,
        profile_strength: strength,
      },
      stats,
    });
  } catch (err) {
    console.error("getMyClientProfile:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const updateClientProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const body = req.body;

    const userFields = [
      "name",
      "tagline",
      "bio",
      "location",
      "country",
      "timezone",
      "phone",
      "website",
      "linkedin",
      "twitter",
    ];
    const userUpdate = {};
    userFields.forEach((f) => {
      if (body[f] !== undefined) userUpdate[f] = body[f];
    });

    if (req.files?.avatar?.[0])
      userUpdate.avatar = `/uploads/avatars/${req.files.avatar[0].filename}`;
    if (req.files?.cover?.[0])
      userUpdate.cover_image = `/uploads/covers/${req.files.cover[0].filename}`;

    if (Object.keys(userUpdate).length > 0)
      await User.update(userUpdate, { where: { id: userId } });

    const profileFields = [
      "company_name",
      "company_size",
      "company_website",
      "company_description",
      "industry",
      "founded_year",
      "tagline",
      "bio",
      "location",
      "country",
      "timezone",
      "phone",
      "preferred_contract_type",
      "budget_range_min",
      "budget_range_max",
      "linkedin",
      "twitter",
    ];
    const jsonFields = ["preferred_skills", "hiring_for"];
    const profileUpdate = {};

    profileFields.forEach((f) => {
      if (body[f] !== undefined) profileUpdate[f] = body[f];
    });
    jsonFields.forEach((f) => {
      if (body[f] !== undefined)
        profileUpdate[f] = Array.isArray(body[f])
          ? JSON.stringify(body[f])
          : body[f];
    });

    let profile = await ClientProfile.findOne({ where: { UserId: userId } });
    if (!profile)
      profile = await ClientProfile.create({
        UserId: userId,
        ...profileUpdate,
      });
    else await profile.update(profileUpdate);

    const user = await User.findByPk(userId);
    const strength = calcClientStrength(profile, user);
    await profile.update({ profile_strength: strength });

    res.json({ message: "✅ Profile updated", profile_strength: strength });
  } catch (err) {
    console.error("updateClientProfile:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const uploadCompanyLogo = multer({
  storage: multer.diskStorage({
    destination: (req, file, cb) => {
      const dir = "uploads/logos";
      if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
      cb(null, dir);
    },
    filename: (req, file, cb) =>
      cb(
        null,
        `logo-${req.user.id}-${Date.now()}${path.extname(file.originalname)}`,
      ),
  }),
  limits: { fileSize: 3 * 1024 * 1024 },
}).single("logo");

export const handleCompanyLogoUpload = async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ message: "No file uploaded" });
    const logoUrl = `/uploads/logos/${req.file.filename}`;
    await ClientProfile.update(
      { company_logo: logoUrl },
      { where: { UserId: req.user.id } },
    );
    res.json({ message: "✅ Logo uploaded", logo_url: logoUrl });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const searchFreelancers = async (req, res) => {
  try {
    const {
      q,
      skills,
      min_rate,
      max_rate,
      availability,
      min_rating,
      location,
      category,
      sort = "rating",
      page = 1,
      limit = 12,
    } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    const whereProfile = {};
    const whereUser = { role: "freelancer" };

    if (availability) whereProfile.availability = availability;
    if (min_rate) whereProfile.hourly_rate = { [Op.gte]: parseFloat(min_rate) };
    if (max_rate)
      whereProfile.hourly_rate = {
        ...whereProfile.hourly_rate,
        [Op.lte]: parseFloat(max_rate),
      };
    if (min_rating) whereProfile.rating = { [Op.gte]: parseFloat(min_rating) };
    if (skills) whereProfile.skills = { [Op.like]: `%${skills}%` };
    if (location) whereUser.location = { [Op.like]: `%${location}%` };
    if (q) whereUser.name = { [Op.like]: `%${q}%` };

    const order =
      sort === "rating"
        ? [["rating", "DESC"]]
        : sort === "hourly_rate_asc"
          ? [["hourly_rate", "ASC"]]
          : sort === "hourly_rate_desc"
            ? [["hourly_rate", "DESC"]]
            : sort === "experience"
              ? [["experience_years", "DESC"]]
              : [["createdAt", "DESC"]];

    const { count, rows } = await FreelancerProfile.findAndCountAll({
      where: whereProfile,
      include: [
        {
          model: User,
          where: whereUser,
          attributes: ["id", "name", "avatar", "location", "createdAt"],
        },
      ],
      order,
      limit: parseInt(limit),
      offset,
    });

    res.json({
      freelancers: rows.map((p) => ({
        id: p.UserId,
        name: p.User.name,
        avatar: p.User.avatar,
        location: p.User.location,
        title: p.title,
        tagline: p.tagline,
        skills: parseJSON(p.skills).slice(0, 6),
        hourly_rate: p.hourly_rate,
        rating: p.rating,
        total_reviews: p.total_reviews,
        completed_projects: p.completed_projects_count,
        job_success_score: p.job_success_score,
        availability: p.availability,
        is_available: p.is_available,
        profile_strength: p.profile_strength,
        member_since: p.User.createdAt,
      })),
      total: count,
      page: parseInt(page),
      total_pages: Math.ceil(count / parseInt(limit)),
    });
  } catch (err) {
    console.error("searchFreelancers:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getFreelancerPublicProfile = async (req, res) => {
  try {
    const { userId } = req.params;

    console.log("🔍 === GET FREELANCER PUBLIC PROFILE ===");
    console.log("📌 Freelancer ID:", userId);
    console.log("📌 Request params:", req.params);

    const freelancerId = parseInt(userId);
    if (isNaN(freelancerId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid user ID",
      });
    }

    const user = await User.findByPk(freelancerId, {
      attributes: [
        "id",
        "name",
        "email",
        "phone",
        "avatar",
        "role",
        "bio",
        "location",
        "createdAt",
        "website",
        "linkedin",
        "github",
        "twitter",
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

    console.log("📧 Email from database:", user.email);
    console.log("📞 Phone from database:", user.phone);

    const responseData = {
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        avatar: user.avatar,
        bio: user.bio,
        location: user.location,
        website: user.website,
        linkedin: user.linkedin,
        github: user.github,
        twitter: user.twitter,
        member_since: user.createdAt,
        profile_views: user.profile_views || 0,
      },
      profile: {
        id: profile?.id,
        title: profile?.title || "",
        bio: profile?.bio || "",
        skills: profile?.skills
          ? typeof profile.skills === "string"
            ? JSON.parse(profile.skills)
            : profile.skills
          : [],
        languages: profile?.languages
          ? typeof profile.languages === "string"
            ? JSON.parse(profile.languages)
            : profile.languages
          : [],
        education: profile?.education
          ? typeof profile.education === "string"
            ? JSON.parse(profile.education)
            : profile.education
          : [],
        certifications: profile?.certifications
          ? typeof profile.certifications === "string"
            ? JSON.parse(profile.certifications)
            : profile.certifications
          : [],
        work_experience: profile?.work_experience
          ? typeof profile.work_experience === "string"
            ? JSON.parse(profile.work_experience)
            : profile.work_experience
          : [],
        hourly_rate: profile?.hourly_rate || 0,
        experience_years: profile?.experience_years || 0,
        rating: profile?.rating || 0,
        is_available: profile?.is_available ?? true,
        availability: profile?.availability,
        weekly_hours: profile?.weekly_hours || 40,
        completed_projects_count: profile?.completed_projects_count || 0,
        total_earnings: profile?.total_earnings || 0,
        job_success_score: profile?.job_success_score || 0,
        response_time: profile?.response_time || 24,
        website: profile?.website,
        linkedin: profile?.linkedin,
        github: profile?.github,
        behance: profile?.behance,
        dribbble: profile?.dribbble,
      },
      stats: {
        rating: profile?.rating || 0,
        total_reviews: 0,
        completed_projects: profile?.completed_projects_count || 0,
        active_projects: 0,
        portfolio_count: 0,
        job_success_score: profile?.job_success_score || 0,
        response_time: profile?.response_time || 24,
      },
      trust: {
        identity_verified: user.is_verified || false,
        top_rated: (profile?.rating || 0) >= 4.8,
        rising_talent: false,
      },
      contact_links: {
        website: user.website || profile?.website,
        linkedin: user.linkedin || profile?.linkedin,
        github: user.github || profile?.github,
        twitter: user.twitter,
        behance: profile?.behance,
        dribbble: profile?.dribbble,
      },
      reviews: [],
      portfolio: [],
      recent_completed_projects: [],
    };

    console.log("📤 Response email:", responseData.user.email);
    console.log("📤 Response phone:", responseData.user.phone);

    res.json(responseData);
  } catch (error) {
    console.error("Get freelancer public profile error:", error);
    res.status(500).json({
      success: false,
      message: "Error fetching freelancer profile",
      error: error.message,
    });
  }
};
