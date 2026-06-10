// socket/socketManager.js
import { Server } from "socket.io";
import { Chat, Message, User, Notification } from "../models/index.js";
import { Op } from "sequelize";
import { sequelize } from "../config/db.js";
import NotificationService from "../services/notificationService.js";

let io;

export const initSocket = (server) => {
  io = new Server(server, {
    cors: {
      origin: "*",
      methods: ["GET", "POST"],
      credentials: true,
    },
    transports: ["websocket", "polling"],
  });

  io.use(async (socket, next) => {
    try {
      let userId = socket.handshake.auth.userId;
      const token = socket.handshake.auth.token;

      if (!userId) {
        return next(new Error("Authentication error: No user ID"));
      }

      if (typeof userId === "string") {
        userId = parseInt(userId, 10);
      }

      if (isNaN(userId)) {
        return next(new Error("Authentication error: Invalid user ID"));
      }

      const user = await User.findByPk(userId);
      if (!user) {
        return next(new Error("User not found"));
      }

      socket.userId = userId;
      socket.user = user;
      next();
    } catch (err) {
      console.error("Socket auth error:", err);
      next(new Error("Authentication error"));
    }
  });

  io.on("connection", (socket) => {
    console.log(`✅ User connected: ${socket.userId} - ${socket.user.name}`);

    socket.join(`user_${socket.userId}`);

    sendUserChats(socket);

    socket.on("join_chat", (chatId) => {
      if (chatId) {
        socket.join(`chat_${chatId}`);
        console.log(`User ${socket.userId} joined chat ${chatId}`);

        socket.emit("joined_chat", { chatId, success: true });
      }
    });

    socket.on("leave_chat", (chatId) => {
      if (chatId) {
        socket.leave(`chat_${chatId}`);
        console.log(`User ${socket.userId} left chat ${chatId}`);
      }
    });

    socket.on("typing", ({ chatId, isTyping }) => {
      if (chatId) {
        socket.to(`chat_${chatId}`).emit("user_typing", {
          userId: socket.userId,
          userName: socket.user.name,
          isTyping: isTyping,
          timestamp: new Date(),
        });
      }
    });

    socket.on("send_message", async (data) => {
      const {
        chatId,
        content,
        type,
        mediaUrl,
        fileName,
        replyTo,
        replyToId,
        senderName,
        senderAvatar,
      } = data;

      const finalSenderName = senderName || socket.user?.name;
      const finalSenderAvatar = senderAvatar || socket.user?.avatar;

      console.log("📨 Received send_message:", {
        chatId,
        content,
        senderName: finalSenderName,
        senderAvatar: finalSenderAvatar,
      });

      const replyToMessageId = replyTo || replyToId;

      console.log("📨 Received send_message:", {
        chatId,
        content,
        type,
        replyToMessageId,
        senderId: socket.userId,
      });

      if (!chatId || !content) {
        socket.emit("message_error", {
          error: "Chat ID and content are required",
        });
        return;
      }

      try {
        const chat = await Chat.findByPk(chatId);
        if (!chat) {
          socket.emit("message_error", { error: "Chat not found" });
          return;
        }

        if (!chat.participant_ids.includes(socket.userId)) {
          socket.emit("message_error", { error: "Unauthorized" });
          return;
        }

        const receiverId = chat.participant_ids.find(
          (id) => id !== socket.userId,
        );

        let replyToMessage = null;
        if (replyToMessageId) {
          replyToMessage = await Message.findByPk(replyToMessageId);
          if (replyToMessage && replyToMessage.chat_id !== chatId) {
            socket.emit("message_error", { error: "Invalid reply reference" });
            return;
          }
        }

        const message = await Message.create({
          chat_id: chatId,
          sender_id: socket.userId,
          content: content,
          type: type || "text",
          media_url: mediaUrl || null,
          file_name: fileName || null,
          reply_to_id: replyToMessageId || null,
          read_by: [],
          is_read: false,
        });

        const newUnreadCounts = { ...chat.unread_counts };
        newUnreadCounts[receiverId] = (newUnreadCounts[receiverId] || 0) + 1;

        await chat.update({
          last_message: content,
          last_message_time: new Date(),
          last_message_sender_id: socket.userId,
          unread_counts: newUnreadCounts,
        });

        let replyPreview = null;
        if (replyToMessage) {
          const replySender = await User.findByPk(replyToMessage.sender_id);
          replyPreview = {
            id: replyToMessage.id,
            content: replyToMessage.content,
            senderName: replySender?.name || "Unknown",
            type: replyToMessage.type,
          };
        }

        const messageData = {
          id: message.id,
          chat_id: message.chat_id,
          sender_id: message.sender_id,
          content: message.content,
          type: message.type,
          media_url: message.media_url,
          file_name: message.file_name,
          reply_to_id: message.reply_to_id,
          reply_to: replyPreview,
          createdAt: message.createdAt.toISOString(),
          sender_name: finalSenderName,
          sender_avatar: finalSenderAvatar,
          read_by: [],
          is_read_by_me: false,
        };

        io.to(`chat_${chatId}`).emit("new_message", messageData);

        io.to(`user_${receiverId}`).emit("new_message_notification", {
          chatId: chatId,
          message: messageData,
          unreadCount: newUnreadCounts[receiverId],
          sender: {
            id: socket.userId,
            name: socket.user.name,
            avatar: socket.user.avatar,
          },
        });
      } catch (err) {
        console.error("Error sending message:", err);
        socket.emit("message_error", { error: "Failed to send message" });
      }
    });

    socket.on("delete_message", async (data) => {
      const { messageId } = data;

      try {
        const message = await Message.findByPk(messageId);
        if (!message) {
          socket.emit("message_error", { error: "Message not found" });
          return;
        }

        if (message.sender_id !== socket.userId) {
          socket.emit("message_error", { error: "Unauthorized" });
          return;
        }

        await message.destroy();

        io.to(`chat_${message.chat_id}`).emit("message_deleted", {
          chatId: message.chat_id,
          messageId: messageId,
          deletedBy: socket.userId,
          timestamp: new Date(),
        });

        console.log(`🗑️ Message ${messageId} deleted by user ${socket.userId}`);
      } catch (err) {
        console.error("Error deleting message:", err);
        socket.emit("message_error", { error: "Failed to delete message" });
      }
    });

    socket.on("update_user", async (userData) => {
      console.log(`🔄 Updating user ${socket.userId} data:`, userData);

      if (userData.name) socket.user.name = userData.name;
      if (userData.avatar) socket.user.avatar = userData.avatar;

      socket.emit("user_updated", { success: true });
    });

    socket.on("edit_message", async (data) => {
      const { messageId, content } = data;

      try {
        const message = await Message.findByPk(messageId);
        if (!message) {
          socket.emit("message_error", { error: "Message not found" });
          return;
        }

        if (message.sender_id !== socket.userId) {
          socket.emit("message_error", { error: "Unauthorized" });
          return;
        }

        await message.update({
          content: content,
          is_edited: true,
          edited_at: new Date(),
        });

        io.to(`chat_${message.chat_id}`).emit("message_edited", {
          chatId: message.chat_id,
          messageId: messageId,
          content: content,
          editedBy: socket.userId,
          editedAt: new Date(),
        });

        console.log(`✏️ Message ${messageId} edited by user ${socket.userId}`);
      } catch (err) {
        console.error("Error editing message:", err);
        socket.emit("message_error", { error: "Failed to edit message" });
      }
    });

    socket.on("send_reaction", async (data) => {
      const { messageId, reaction } = data;

      try {
        const message = await Message.findByPk(messageId);
        if (!message) {
          socket.emit("message_error", { error: "Message not found" });
          return;
        }

        await message.update({
          reaction: reaction,
        });

        io.to(`chat_${message.chat_id}`).emit("message_reaction", {
          chatId: message.chat_id,
          messageId: messageId,
          reaction: reaction,
          userId: socket.userId,
          timestamp: new Date(),
        });

        console.log(`😊 Reaction ${reaction} added to message ${messageId}`);
      } catch (err) {
        console.error("Error adding reaction:", err);
        socket.emit("message_error", { error: "Failed to add reaction" });
      }
    });

    socket.on("mark_read", async ({ chatId }) => {
      if (!chatId) return;

      try {
        const chat = await Chat.findByPk(chatId);
        if (!chat) return;

        if (!chat.participant_ids.includes(socket.userId)) return;

        const messages = await Message.findAll({
          where: {
            chat_id: chatId,
            is_read: false,
          },
        });

        for (const message of messages) {
          const readBy = message.read_by || [];
          if (!readBy.includes(socket.userId)) {
            readBy.push(socket.userId);
            const isRead = readBy.length === chat.participant_ids.length;
            await message.update({
              read_by: readBy,
              is_read: isRead,
              read_at: isRead ? new Date() : null,
            });
          }
        }

        const newUnreadCounts = { ...chat.unread_counts };
        newUnreadCounts[socket.userId] = 0;
        await chat.update({ unread_counts: newUnreadCounts });

        socket.to(`chat_${chatId}`).emit("messages_read", {
          userId: socket.userId,
          chatId: chatId,
          timestamp: new Date(),
        });
      } catch (err) {
        console.error("Error marking read:", err);
      }
    });

    socket.on("load_more_messages", async ({ chatId, offset, limit }) => {
      try {
        const chat = await Chat.findByPk(chatId);
        if (!chat || !chat.participant_ids.includes(socket.userId)) {
          socket.emit("load_more_error", { error: "Unauthorized" });
          return;
        }

        const messages = await Message.findAll({
          where: { chat_id: chatId },
          order: [["createdAt", "DESC"]],
          limit: limit || 20,
          offset: offset || 0,
        });

        const messagesWithSenders = await Promise.all(
          messages.map(async (msg) => {
            const sender = await User.findByPk(msg.sender_id, {
              attributes: ["id", "name", "avatar"],
            });
            return {
              ...msg.toJSON(),
              sender_name: sender?.name,
              sender_avatar: sender?.avatar,
              is_read_by_me: (msg.read_by || []).includes(socket.userId),
            };
          }),
        );

        socket.emit("messages_loaded", {
          chatId,
          messages: messagesWithSenders.reverse(),
          hasMore: messages.length === (limit || 20),
        });
      } catch (err) {
        console.error("Error loading messages:", err);
        socket.emit("load_more_error", { error: "Failed to load messages" });
      }
    });

    socket.on("ping", () => {
      socket.emit("pong", { timestamp: new Date() });
    });

    socket.on("disconnect", () => {
      console.log(`❌ User disconnected: ${socket.userId}`);

      socket.broadcast.emit("user_status", {
        userId: socket.userId,
        status: "offline",
        timestamp: new Date(),
      });
    });
  });

  return io;
};

async function sendUserChats(socket) {
  try {
    const { Op } = await import("sequelize");

    const chats = await Chat.findAll({
      where: {
        [Op.and]: [
          sequelize.literal(
            `JSON_CONTAINS(participant_ids, '[${socket.userId}]')`,
          ),
          { status: "active" },
        ],
      },
      order: [["last_message_time", "DESC"]],
    });

    const chatsWithData = await Promise.all(
      chats.map(async (chat) => {
        const participants = await User.findAll({
          where: { id: { [Op.in]: chat.participant_ids } },
          attributes: ["id", "name", "avatar"],
        });

        const otherParticipant = participants.find(
          (p) => p.id !== socket.userId,
        );
        const unreadCount = chat.unread_counts?.[socket.userId] || 0;

        return {
          id: chat.id,
          unique_id: chat.unique_id,
          otherUser: otherParticipant
            ? {
                id: otherParticipant.id,
                name: otherParticipant.name,
                avatar: otherParticipant.avatar,
              }
            : null,
          last_message: chat.last_message,
          last_message_time: chat.last_message_time,
          last_message_sender_id: chat.last_message_sender_id,
          unreadCount: unreadCount,
          createdAt: chat.createdAt,
          updatedAt: chat.updatedAt,
        };
      }),
    );

    socket.emit("chats_list", chatsWithData);
  } catch (err) {
    console.error("Error sending chats:", err);
  }
}

export const getIO = () => io;
