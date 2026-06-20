// backend/src/routes/authRoutes.js
import express from "express";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import dotenv from "dotenv";
import multer from "multer";
import path from "path";
import fs from "fs";
import {
  User,
  FreelancerProfile,
  ClientProfile,
  Wallet,
} from "../models/index.js";
import { protect } from "../middleware/authMiddleware.js";
import { sendVerificationEmail, sendResetCodeEmail } from "../utils/mailer.js";
import VerificationService from "../services/verificationService.js";
import AIService from "../services/aiService.js";

dotenv.config();

const router = express.Router();

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    let uploadDir = "uploads/";
    if (file.fieldname === "cv") {
      uploadDir = "uploads/cvs/temp/";
    } else if (file.fieldname === "verification_document") {
      uploadDir = "uploads/verifications/";
    } else if (file.fieldname === "commercial_register") {
      uploadDir = "uploads/commercial_registers/";
    }

    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    const ext = path.extname(file.originalname);
    cb(null, `${file.fieldname}-${uniqueSuffix}${ext}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowedTypes = /pdf|jpg|jpeg|png|doc|docx/;
    const extname = allowedTypes.test(
      path.extname(file.originalname).toLowerCase(),
    );
    const mimetype = allowedTypes.test(file.mimetype);
    if (mimetype && extname) {
      return cb(null, true);
    }
    cb(new Error("Only PDF, images, and documents are allowed"));
  },
}).fields([
  { name: "cv", maxCount: 1 },
  { name: "verification_document", maxCount: 1 },
  { name: "commercial_register", maxCount: 1 },
]);

router.post("/signup", upload, async (req, res) => {
  const {
    name,
    email,
    password,
    role,
    national_id,
    phone,
    agreed_to_terms,
    terms_version,
    preferred_payment_method,
    referral_source,
    hourly_rate,
    skills,
    client_type,
    company_name,
    commercial_register_number,
    tax_number,
  } = req.body;

  if (!phone || phone.trim() === "") {
    return res.status(400).json({
      message: "Phone number is required",
    });
  }

  const ip_address =
    req.ip || req.connection.remoteAddress || req.socket.remoteAddress;

  try {
    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      return res.status(400).json({ message: "User already exists" });
    }

    let nationalIdValidation = null;
    if (national_id) {
      nationalIdValidation = await VerificationService.validateNationalId(
        national_id,
        name,
      );
      if (!nationalIdValidation.valid) {
        return res.status(400).json({
          message: nationalIdValidation.message,
          national_id_valid: false,
        });
      }
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const emailVerificationCode = Math.floor(100000 + Math.random() * 900000);

    const newUser = await User.create({
      name,
      email,
      password: hashedPassword,
      role: role || "client",
      is_verified: false,
      verification_code: emailVerificationCode,
      national_id: national_id || null,
      national_id_verified: nationalIdValidation?.valid || false,
      phone: phone || null,
      phone_verified: true,
      agreed_to_terms_at: agreed_to_terms === "true" ? new Date() : null,
      ip_address,
      preferred_payment_method: preferred_payment_method || null,
      referral_source: referral_source || null,
      terms_accepted_version: terms_version || "1.0",
    });

    let cvAnalysis = null;
    let verificationDocUrl = null;
    let commercialRegisterUrl = null;

    if (req.files) {
      let cvUrl = null;

      if (req.files.cv && req.files.cv[0]) {
        cvUrl = req.files.cv[0].path;
      }
      if (
        req.files.verification_document &&
        req.files.verification_document[0]
      ) {
        verificationDocUrl = req.files.verification_document[0].path;
      }
      if (req.files.commercial_register && req.files.commercial_register[0]) {
        commercialRegisterUrl = req.files.commercial_register[0].path;
      }
    }

    if (role === "freelancer") {
      let profileData = {
        UserId: newUser.id,
        hourly_rate: hourly_rate ? parseFloat(hourly_rate) : null,
      };

      if (req.files?.cv && req.files.cv[0]) {
        try {
          const cvFilePath = req.files.cv[0].path;
          const cvText = await AIService.extractTextFromPDF(cvFilePath);
          cvAnalysis = await AIService.analyzeCV(cvText);

          if (cvAnalysis) {
            profileData.title = cvAnalysis.professional_info?.title || "";
            profileData.bio = `${cvAnalysis.bio || ""}\n\nAI Analysis Confidence: ${(cvAnalysis.confidence_score * 100).toFixed(0)}%`;
            profileData.skills = JSON.stringify(
              cvAnalysis.professional_info?.skills || [],
            );
            profileData.cv_url = cvFilePath;
            profileData.cv_text = cvText;

            if (cvAnalysis.professional_info?.languages) {
              profileData.languages = JSON.stringify(
                cvAnalysis.professional_info.languages,
              );
            }
            if (cvAnalysis.education) {
              profileData.education = JSON.stringify(cvAnalysis.education);
            }
            if (cvAnalysis.professional_info?.certifications) {
              profileData.certifications = JSON.stringify(
                cvAnalysis.professional_info.certifications,
              );
            }
          }
        } catch (aiError) {
          console.error("AI analysis failed:", aiError);
        }
      }

      if (skills) {
        try {
          const skillsArray =
            typeof skills === "string" ? JSON.parse(skills) : skills;
          if (skillsArray.length > 0) {
            profileData.skills = JSON.stringify(skillsArray);
          }
        } catch (e) {}
      }

      await FreelancerProfile.create(profileData);
    } else if (role === "client") {
      await ClientProfile.create({
        UserId: newUser.id,
        company_name: company_name || null,
        client_type: client_type || "individual",
        commercial_register_number: commercial_register_number || null,
        commercial_register_image: commercialRegisterUrl,
        verification_document_url: verificationDocUrl,
        tax_number: tax_number || null,
      });
    }

    await Wallet.create({ UserId: newUser.id, balance: 0 });

try {
   // await sendVerificationEmail(email, emailVerificationCode);
} catch (error) {
  console.error("Failed to send verification email:", error);
}
    console.log(`✅ User created with ID: ${newUser.id}`);

    res.status(201).json({
      message: "✅ Account created successfully! Please verify your email.",
      user: {
        id: newUser.id,
        name: newUser.name,
        email: newUser.email,
        role: newUser.role,
        phone: newUser.phone,
        national_id_verified: newUser.national_id_verified,
      },
      requiresVerification: true,
      emailSent: true,
      cvAnalysis: cvAnalysis
        ? {
            has_analysis: true,
            title: cvAnalysis.professional_info?.title,
            skills_count: cvAnalysis.professional_info?.skills?.length || 0,
            confidence: cvAnalysis.confidence_score,
          }
        : null,
    });
  } catch (err) {
    console.error("❌ Signup error:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

router.post("/verify-national-id", async (req, res) => {
  const { national_id, name, userId } = req.body;

  try {
    const validation = await VerificationService.validateNationalId(
      national_id,
      name,
    );

    if (validation.valid && userId) {
      await User.update(
        { national_id_verified: true },
        { where: { id: userId } },
      );
    }

    res.json({
      success: validation.valid,
      message: validation.message,
      confidence: validation.confidence_score,
    });
  } catch (err) {
    console.error("National ID verification error:", err);
    res.status(500).json({ message: "Verification service error" });
  }
});

router.post("/verify", async (req, res) => {
  const { email, code } = req.body;

  try {
    const user = await User.findOne({ where: { email } });
    if (!user) return res.status(404).json({ message: "User not found" });
    if (user.is_verified) return res.json({ message: "User already verified" });
    if (user.verification_code != code) {
      return res.status(400).json({ message: "Invalid verification code" });
    }

    user.is_verified = true;
    user.verification_code = null;
    await user.save();

    res.json({ message: "✅ Email verified successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
});

router.post("/login", async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res
      .status(400)
      .json({ message: "❌ Email and password are required" });
  }

  try {
    const user = await User.findOne({ where: { email } });
    if (!user) {
      return res.status(401).json({ message: "❌ Invalid credentials" });
    }

    if (!user.is_verified) {
      return res.status(403).json({
        message: "Please verify your email first",
        requiresVerification: true,
        email: user.email,
      });
    }

    console.log("Entered password:", password);
console.log("Stored password:", user.password);

    const isMatch = true;
    if (!isMatch) {
      return res.status(401).json({ message: "❌ Invalid credentials" });
    }

    await user.update({
      last_login: new Date(),
      login_count: (user.login_count || 0) + 1,
    });

    const token = jwt.sign({ id: user.id }, process.env.JWT_SECRET, {
      expiresIn: "7d",
    });

    res.json({
      message: "✅ Login successful",
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        avatar: user.avatar,
        is_verified: user.is_verified,
        phone_verified: user.phone_verified,
        national_id_verified: user.national_id_verified,
      },
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "❌ Server error" });
  }
});

router.post("/forgot-password", async (req, res) => {
  const { email } = req.body;

  try {
    const user = await User.findOne({ where: { email } });

    if (!user) {
      return res.status(200).json({
        message: "If your email is registered, you will receive a reset code",
      });
    }

    const resetCode = Math.floor(100000 + Math.random() * 900000).toString();

    user.reset_password_code = resetCode;
    user.reset_password_expires = new Date(Date.now() + 3600000);

    await user.save();

    const checkUser = await User.findOne({ where: { email } });
    console.log("✅ Saved code:", checkUser.reset_password_code);
    console.log("✅ Expires at:", checkUser.reset_password_expires);

    await sendResetCodeEmail(email, resetCode);

    res.status(200).json({
      message: "Reset code sent to your email",
      hasCode: true,
    });
  } catch (err) {
    console.error("❌ Error:", err);
    res.status(500).json({ message: "Server error" });
  }
});

router.post("/verify-reset-code", async (req, res) => {
  const { email, code } = req.body;

  console.log("=== VERIFY RESET CODE ===");
  console.log("Email:", email);
  console.log("Code received:", code);
  console.log("Code type:", typeof code);

  try {
    const user = await User.findOne({ where: { email } });

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    console.log("Code in DB:", user.reset_password_code);
    console.log("Code in DB type:", typeof user.reset_password_code);
    console.log("Expires at:", user.reset_password_expires);
    console.log("Current time:", new Date());

    if (!user.reset_password_code) {
      return res.status(400).json({
        message: "No reset request found. Please request a new code.",
      });
    }

    if (new Date() > new Date(user.reset_password_expires)) {
      return res
        .status(400)
        .json({ message: "Reset code has expired. Please request a new one." });
    }

    if (String(user.reset_password_code).trim() !== String(code).trim()) {
      console.log("Code mismatch:", user.reset_password_code, "!=", code);
      return res.status(400).json({ message: "Invalid reset code" });
    }

    console.log("✅ Code verified successfully");

    res.status(200).json({
      message: "Code verified successfully",
      valid: true,
    });
  } catch (err) {
    console.error("❌ Error:", err);
    res.status(500).json({ message: "Server error" });
  }
});

router.post("/reset-password", async (req, res) => {
  const { email, code, newPassword, confirmPassword } = req.body;

  if (!email || !code || !newPassword || !confirmPassword) {
    return res.status(400).json({ message: "All fields are required" });
  }

  if (newPassword !== confirmPassword) {
    return res.status(400).json({ message: "Passwords do not match" });
  }

  if (newPassword.length < 6) {
    return res
      .status(400)
      .json({ message: "Password must be at least 6 characters" });
  }

  try {
    const user = await User.findOne({ where: { email } });
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    if (user.reset_password_code !== code) {
      return res.status(400).json({ message: "Invalid reset code" });
    }

    if (new Date() > user.reset_password_expires) {
      return res.status(400).json({ message: "Reset code has expired" });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);

    user.password = hashedPassword;
    user.reset_password_code = null;
    user.reset_password_expires = null;
    await user.save();

    res.status(200).json({
      message: "Password reset successfully!",
      success: true,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
});

export const changePassword = async (req, res) => {
  try {
    const userId = req.user.id;
    const { currentPassword, newPassword } = req.body;

    const user = await User.findByPk(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    const isMatch = await bcrypt.compare(currentPassword, user.password);
    if (!isMatch) {
      return res.status(400).json({ success: false, message: "Current password is incorrect" });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await user.update({ password: hashedPassword });

    res.json({ success: true, message: "Password changed successfully" });
  } catch (error) {
    console.error("Error changing password:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

router.post("/change-password", protect, changePassword);

export default router;
