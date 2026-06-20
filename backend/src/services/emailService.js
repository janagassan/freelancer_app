// services/emailService.js
import nodemailer from "nodemailer";
import dotenv from "dotenv";
dotenv.config();

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: process.env.SMTP_PORT,
  secure: false,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
  connectionTimeout: 30000,
greetingTimeout: 30000,
socketTimeout: 30000,
});

export const sendVerificationEmail = async (to, code) => {
  try {
    console.log(`📧 Preparing to send email to ${to} with code: ${code}`);

    const mailOptions = {
      from: process.env.SMTP_FROM,
      to,
      subject: "🔐 Verification Code for Contract Signing",
      html: `
        <div dir="ltr" style="font-family: Arial; max-width: 500px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
          <h2 style="color: #14A800; text-align: center;">Electronic Contract Signing</h2>
          <p>Hello,</p>
          <p>You requested to sign a contract on the platform. Use the following code to complete the signing process:</p>
          <div style="background: #f5f5f5; padding: 20px; text-align: center; margin: 20px 0; border-radius: 5px;">
            <h1 style="font-size: 48px; letter-spacing: 5px; color: #14A800; margin: 0;">${code}</h1>
          </div>
          <p>This code is valid for only <strong>10 minutes</strong>.</p>
          <p>If you didn't request this, please ignore this message.</p>
          <hr style="border: none; border-top: 1px solid #e0e0e0; margin: 20px 0;">
          <p style="color: #999; font-size: 12px; text-align: center;">This is an automated message, please do not reply.</p>
        </div>
      `,
    };

    const info = await transporter.sendMail(mailOptions);
    console.log(
      "✅ Verification email sent to",
      to,
      "Message ID:",
      info.messageId,
    );
    return true;
  } catch (err) {
    console.error("❌ Failed to send email:", err.message);
    console.error("Full error:", err);
    throw err;
  }
};

export const sendInterviewInvitationEmail = async (
  freelancer,
  client,
  project,
  invitation,
) => {
  const suggestedTimes = Array.isArray(invitation.suggested_times)
    ? invitation.suggested_times
    : [];

  const timesHtml = suggestedTimes
    .map((time) => {
      try {
        const date = new Date(time);
        if (isNaN(date.getTime())) {
          console.warn(`Invalid date: ${time}`);
          return "";
        }
        return `<li><strong>${date.toLocaleString()}</strong></li>`;
      } catch (err) {
        console.warn(`Error parsing date: ${time}`, err);
        return "";
      }
    })
    .filter((html) => html !== "")
    .join("");

  const timesSection = timesHtml
    ? `
    <h3>🤖 AI Suggested Times:</h3>
    <ul style="background: white; padding: 15px 15px 15px 35px; border-radius: 8px;">
      ${timesHtml}
    </ul>
  `
    : `
    <div style="background: #FEF3C7; padding: 15px; border-radius: 8px; margin: 15px 0;">
      <p><strong>⏰ Time options will be available in the platform.</strong></p>
      <p>Please login to view and select your preferred time.</p>
    </div>
  `;

  const mailOptions = {
    from: process.env.SMTP_FROM,
    to: freelancer.email,
    subject: `📅 Interview Invitation: ${project.title}`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
          <h1 style="color: white; margin: 0;">Interview Invitation</h1>
        </div>
        <div style="background: #f9fafb; padding: 30px; border-radius: 0 0 10px 10px;">
          <p>Hello <strong>${freelancer.name || freelancer.fullName || "Freelancer"}</strong>,</p>
          <p><strong>${client.name || client.fullName || "Client"}</strong> has invited you for an interview regarding the project:</p>
          
          <div style="background: white; padding: 15px; border-radius: 8px; margin: 20px 0;">
            <h3 style="margin: 0 0 10px 0; color: #333;">${project.title}</h3>
            <p style="color: #666; margin: 0;">${project.description ? project.description.substring(0, Math.min(200, project.description.length)) : "No description provided"}...</p>
          </div>
          
          ${timesSection}
          
          <p><strong>⏰ Duration:</strong> ${invitation.duration_minutes || 30} minutes</p>
          
          ${
            invitation.message
              ? `
            <div style="background: #e8f4fd; padding: 15px; border-radius: 8px; margin: 15px 0;">
              <p style="margin: 0;"><strong>💬 Message from client:</strong></p>
              <p style="margin: 5px 0 0 0; color: #555;">${invitation.message}</p>
            </div>
          `
              : ""
          }
          
          <div style="text-align: center; margin: 30px 0;">
            <a href="${process.env.FRONTEND_URL || "https://freelancer-app-h6os.onrender.com"}/interviews/${invitation.id}" 
               style="background-color: #764ba2; color: white; padding: 12px 30px; 
                      text-decoration: none; border-radius: 25px; display: inline-block;">
              View & Select Time
            </a>
          </div>
          
          <hr style="border: none; border-top: 1px solid #e0e0e0; margin: 20px 0;">
          <p style="font-size: 12px; color: #999;">
            Please select your preferred time from the options above.<br>
            This invitation expires on <strong>${invitation.expires_at ? new Date(invitation.expires_at).toLocaleString() : "7 days"}</strong>
          </p>
        </div>
      </div>
    `,
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log(`📧 Interview invitation email sent to ${freelancer.email}`);
    return true;
  } catch (error) {
    console.error(`❌ Failed to send email to ${freelancer.email}:`, error);
    return false;
  }
};

export const sendInterviewConfirmationEmail = async (
  invitation,
  client,
  freelancer,
  project,
) => {
  if (!invitation || !client || !freelancer || !project) {
    console.error("Missing required data for confirmation email:", {
      hasInvitation: !!invitation,
      hasClient: !!client,
      hasFreelancer: !!freelancer,
      hasProject: !!project,
    });
    return false;
  }

  try {
    const mailOptions = {
      from: process.env.SMTP_FROM,
      to: `${client.email}, ${freelancer.email}`,
      subject: `✅ Interview Confirmed: ${project.title}`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background: linear-gradient(135deg, #14A800 0%, #0F7A00 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
            <h1 style="color: white; margin: 0;">Interview Confirmed ✅</h1>
          </div>
          <div style="background: #f9fafb; padding: 30px; border-radius: 0 0 10px 10px;">
            <p>Dear <strong>${client.name}</strong> and <strong>${freelancer.name}</strong>,</p>
            <p>Your interview has been confirmed for the project:</p>
            
            <div style="background: white; padding: 15px; border-radius: 8px; margin: 20px 0;">
              <h3 style="margin: 0 0 10px 0; color: #333;">${project.title}</h3>
              ${project.description ? `<p style="color: #666; margin: 0;">${project.description.substring(0, 150)}...</p>` : ""}
            </div>
            
            <div style="background: #e8f4fd; padding: 15px; border-radius: 8px; margin: 20px 0;">
              <p><strong>📅 Date & Time:</strong> ${new Date(invitation.selected_time).toLocaleString()}</p>
              <p><strong>⏰ Duration:</strong> ${invitation.duration_minutes || 30} minutes</p>
              <p><strong>🎥 Meeting Link:</strong> <a href="${invitation.meeting_link}">${invitation.meeting_link}</a></p>
            </div>
            
            <div style="text-align: center; margin: 30px 0;">
              <a href="${invitation.meeting_link}" 
                 style="background-color: #14A800; color: white; padding: 12px 30px; 
                        text-decoration: none; border-radius: 25px; display: inline-block;">
                Join Meeting
              </a>
            </div>
            
            <hr style="border: none; border-top: 1px solid #e0e0e0; margin: 20px 0;">
            <p style="font-size: 12px; color: #999;">
              Please make sure you have a stable internet connection and a working camera/microphone.
            </p>
          </div>
        </div>
      `,
    };

    await transporter.sendMail(mailOptions);
    console.log(
      `📧 Interview confirmation email sent to ${client.email} and ${freelancer.email}`,
    );
    return true;
  } catch (error) {
    console.error("❌ Failed to send confirmation email:", error);
    return false;
  }
};

export const sendInterviewReminderEmail = async (
  invitation,
  client,
  freelancer,
  project,
  hoursBefore,
) => {
  const mailOptions = {
    from: process.env.SMTP_FROM,
    to: `${client.email}, ${freelancer.email}`,
    subject: `⏰ Interview Reminder: ${project.title} in ${hoursBefore} hours`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <div style="background: linear-gradient(135deg, #F59E0B 0%, #D97706 100%); padding: 20px; text-align: center; border-radius: 10px 10px 0 0;">
          <h1 style="color: white; margin: 0;">Interview Reminder</h1>
        </div>
        <div style="background: #f9fafb; padding: 30px; border-radius: 0 0 10px 10px;">
          <p>Hello <strong>${client.name}</strong> and <strong>${freelancer.name}</strong>,</p>
          <p>This is a reminder that your interview for <strong>${project.title}</strong> is in <strong>${hoursBefore} hours</strong>.</p>
          
          <div style="background: #FEF3C7; padding: 15px; border-radius: 8px; margin: 20px 0;">
            <p><strong>📅 Date & Time:</strong> ${new Date(invitation.selected_time).toLocaleString()}</p>
            <p><strong>⏰ Duration:</strong> ${invitation.duration_minutes} minutes</p>
            <p><strong>🎥 Meeting Link:</strong> <a href="${invitation.meeting_link}">${invitation.meeting_link}</a></p>
          </div>
          
          <div style="text-align: center; margin: 30px 0;">
            <a href="${invitation.meeting_link}" 
               style="background-color: #F59E0B; color: white; padding: 12px 30px; 
                      text-decoration: none; border-radius: 25px; display: inline-block;">
              Join Meeting Now
            </a>
          </div>
          
          <p style="font-size: 12px; color: #999;">
            Please make sure you have a stable internet connection and a working camera/microphone.
          </p>
        </div>
      </div>
    `,
  };

  await transporter.sendMail(mailOptions);
  console.log(
    `📧 Interview reminder email sent to ${client.email} and ${freelancer.email}`,
  );
};

const generateGoogleCalendarLink = (invitation, project) => {
  const startTime = new Date(invitation.selected_time);
  const endTime = new Date(
    startTime.getTime() + invitation.duration_minutes * 60000,
  );

  const event = {
    text: `Interview: ${project.title}`,
    dates: `${formatGoogleDate(startTime)}/${formatGoogleDate(endTime)}`,
    details: invitation.message || "Interview discussion",
    location: invitation.meeting_link,
  };

  return `https://calendar.google.com/calendar/render?action=TEMPLATE&text=${encodeURIComponent(event.text)}&dates=${event.dates}&details=${encodeURIComponent(event.details)}&location=${encodeURIComponent(event.location)}`;
};

const formatGoogleDate = (date) => {
  return date.toISOString().replace(/-|:|\.\d+/g, "");
};
