// controllers/projectController.js
import { Project, User, Proposal, Contract } from "../models/index.js";
import { Op } from "sequelize";

export const getAllProjects = async (req, res) => {
  try {
    console.log("📥 Fetching all projects...");

    const userId = req.user?.id;

    const proposedProjectIds = userId
      ? (
          await Proposal.findAll({
            where: { UserId: userId },
            attributes: ["ProjectId"],
          })
        ).map((p) => p.ProjectId)
      : [];

    const assignedProjectIds = (
      await Contract.findAll({
        where: { status: ["active", "pending_client", "pending_freelancer"] },
        attributes: ["ProjectId"],
      })
    ).map((c) => c.ProjectId);

    const projects = await Project.findAll({
      where: {
        status: "open",
        id: {
          [Op.not]: [...proposedProjectIds, ...assignedProjectIds],
        },
      },
      include: [
        {
          model: User,
          as: "client",
          attributes: ["id", "name", "avatar", "email"],
        },
      ],
      order: [["createdAt", "DESC"]],
      limit: 50,
    });

    console.log(`✅ Found ${projects.length} projects (filtered)`);
    res.json(projects);
  } catch (err) {
    console.error("❌ Error in getAllProjects:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getProjectById = async (req, res) => {
  try {
    console.log("📥 Fetching project by ID:", req.params.id);

    const project = await Project.findByPk(req.params.id, {
      include: [
        {
          model: User,
          as: "client",
          attributes: ["id", "name", "avatar", "email"],
        },
      ],
    });

    if (!project) {
      return res.status(404).json({ message: "Project not found" });
    }

    console.log("✅ Project found:", project.title);
    console.log("👤 Client:", project.client?.name);

    res.json(project);
  } catch (err) {
    console.error("❌ Error in getProjectById:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const analyzeProjectWithAI = async (req, res) => {
  try {
    const { title, description, category, skills, budget } = req.body;

    if (!title || title.trim().length < 3) {
      return res.status(400).json({
        success: false,
        message: "Project title is required (min 3 characters)",
      });
    }

    console.log(`🔍 Analyzing project: "${title}"`);

    let analysis;
    try {
      analysis = await AIService.analyzeProject({
        title: title.trim(),
        description: description || "",
        category: category || "general",
        skills: skills || [],
        budget: budget || 1000,
      });
    } catch (aiError) {
      console.warn("AI service failed, using fallback:", aiError.message);
      analysis = AIService.getDefaultProjectAnalysis({
        title,
        description,
        category,
        skills,
      });
    }

    if (
      !analysis.suggested_milestones ||
      analysis.suggested_milestones.length === 0
    ) {
      analysis.suggested_milestones = [
        { title: "Planning", description: "Project planning", percentage: 20 },
        {
          title: "Development",
          description: "Main development",
          percentage: 50,
        },
        {
          title: "Delivery",
          description: "Testing & delivery",
          percentage: 30,
        },
      ];
    }

    res.json({
      success: true,
      analysis,
      message: "Project analyzed successfully",
    });
  } catch (error) {
    console.error("Analysis controller error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to analyze project",
      error: error.message,
    });
  }
};
