// src/controllers/chatController.js
import { sequelize } from "../config/db.js";
import { Chat, Message, User, Project, Contract } from "../models/index.js";
import { Op } from "sequelize";
import NotificationService from "../services/notificationService.js";

const generateUniqueChatId = (userId1, userId2) => {
  const sorted = [userId1, userId2].sort((a, b) => a - b);
  return `${sorted[0]}_${sorted[1]}`;
};

export const createChat = async (req, res) => {
  try {
    const otherUserId = req.body.other_user_id || req.body.otherUserId;
    const currentUserId = req.user.id;

    console.log(
      "📱 Create chat - currentUser:",
      currentUserId,
      "otherUser:",
      otherUserId,
    );
    console.log("📦 Request body:", req.body);

    if (!otherUserId) {
      return res.status(400).json({ message: "Other user ID is required" });
    }

    const otherUser = await User.findByPk(otherUserId);
    if (!otherUser) {
      return res.status(404).json({ message: "User not found" });
    }

    const uniqueId = generateUniqueChatId(currentUserId, otherUserId);
    let chat = await Chat.findOne({ where: { unique_id: uniqueId } });

    if (!chat) {
      chat = await Chat.create({
        unique_id: uniqueId,
        participant_ids: [currentUserId, otherUserId],
        unread_counts: {
          [currentUserId]: 0,
          [otherUserId]: 0,
        },
        status: "active",
      });
      console.log("✅ New chat created with ID:", chat.id);
    } else {
      console.log("✅ Existing chat found with ID:", chat.id);
    }

    const participants = await User.findAll({
      where: { id: { [Op.in]: chat.participant_ids } },
      attributes: ["id", "name", "avatar"],
    });

    res.status(201).json({
      success: true,
      chat: {
        id: chat.id,
        ...chat.toJSON(),
        participants,
      },
    });
  } catch (err) {
    console.error("Error in createChat:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getUserChats = async (req, res) => {
  try {
    const userId = req.user.id;

    const chats = await Chat.findAll({
      where: {
        [Op.and]: [
          sequelize.literal(`JSON_CONTAINS(participant_ids, '[${userId}]')`),
          { status: "active" },
        ],
      },
      order: [["last_message_time", "DESC"]],
    });

    const chatsWithParticipants = await Promise.all(
      chats.map(async (chat) => {
        const participants = await User.findAll({
          where: { id: { [Op.in]: chat.participant_ids } },
          attributes: ["id", "name", "avatar"],
        });

        const otherParticipant = participants.find((p) => p.id !== userId);
        const unreadCount = chat.unread_counts?.[userId] || 0;

        const lastMessages = await Message.findAll({
          where: { chat_id: chat.id },
          order: [["createdAt", "DESC"]],
          limit: 3,
        });

        const lastMessagesWithSenders = await Promise.all(
          lastMessages.map(async (msg) => {
            const sender = await User.findByPk(msg.sender_id, {
              attributes: ["id", "name", "avatar"],
            });
            return {
              ...msg.toJSON(),
              sender_name: sender?.name,
              sender_avatar: sender?.avatar,
            };
          }),
        );

        return {
          id: chat.id,
          unique_id: chat.unique_id,
          otherUser: otherParticipant,
          last_message: chat.last_message,
          last_message_time: chat.last_message_time,
          last_message_sender_id: chat.last_message_sender_id,
          unreadCount: unreadCount,
          lastMessages: lastMessagesWithSenders.reverse(),
          createdAt: chat.createdAt,
          updatedAt: chat.updatedAt,
        };
      }),
    );

    res.json(chatsWithParticipants);
  } catch (err) {
    console.error("Error in getUserChats:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getChatMessages = async (req, res) => {
  try {
    const { chatId } = req.params;
    const userId = req.user.id;
    const { limit = 50, offset = 0 } = req.query;

    const chat = await Chat.findByPk(chatId);
    if (!chat) {
      return res.status(404).json({ message: "Chat not found" });
    }

    const isParticipant = await Chat.findOne({
      where: {
        id: chatId,
        [Op.and]: [
          sequelize.literal(`JSON_CONTAINS(participant_ids, '[${userId}]')`),
        ],
      },
    });

    if (!isParticipant) {
      return res.status(403).json({ message: "Unauthorized" });
    }

    const messages = await Message.findAll({
      where: { chat_id: chatId },
      order: [["createdAt", "DESC"]],
      limit: parseInt(limit),
      offset: parseInt(offset),
    });

    const messagesWithSenders = await Promise.all(
      messages.map(async (message) => {
        const sender = await User.findByPk(message.sender_id, {
          attributes: ["id", "name", "avatar"],
        });

        return {
          ...message.toJSON(),
          sender_name: sender?.name,
          sender_avatar: sender?.avatar,
          is_read_by_me: message.read_by.includes(userId),
        };
      }),
    );

    if (chat.unread_counts?.[userId] > 0) {
      const newUnreadCounts = { ...chat.unread_counts };
      newUnreadCounts[userId] = 0;
      await chat.update({ unread_counts: newUnreadCounts });
    }

    res.json({
      messages: messagesWithSenders.reverse(),
      total: messages.length,
      hasMore: messages.length === parseInt(limit),
    });
  } catch (err) {
    console.error("Error in getChatMessages:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const sendMessage = async (req, res) => {
  try {
    const { chatId, content, type, mediaUrl, sender_name, sender_avatar } =
      req.body;
    const senderId = req.user.id;

    if (!chatId || !content) {
      return res
        .status(400)
        .json({ message: "Chat ID and content are required" });
    }

    const chat = await Chat.findByPk(chatId);
    if (!chat) {
      return res.status(404).json({ message: "Chat not found" });
    }

    if (!chat.participant_ids.includes(senderId)) {
      return res.status(403).json({ message: "Unauthorized" });
    }

    const receiverId = chat.participant_ids.find((id) => id !== senderId);

    const message = await Message.create({
      chat_id: chatId,
      sender_id: senderId,
      content,
      type: type || "text",
      media_url: mediaUrl || null,
      read_by: [],
    });

    const newUnreadCounts = { ...chat.unread_counts };
    newUnreadCounts[receiverId] = (newUnreadCounts[receiverId] || 0) + 1;

    await chat.update({
      last_message: content,
      last_message_time: new Date(),
      last_message_sender_id: senderId,
      unread_counts: newUnreadCounts,
    });

    const sender = await User.findByPk(senderId, {
      attributes: ["id", "name", "avatar"],
    });

    await NotificationService.createNotification({
      userId: receiverId,
      type: "message",
      title: `New message from ${sender?.name}`,
      body: content.length > 100 ? content.substring(0, 100) + "..." : content,
      data: {
        chatId: chat.id,
        messageId: message.id,
        senderId: senderId,
        screen: "chat",
      },
    });

    const finalSenderName = sender_name || sender?.name;
    const finalSenderAvatar = sender_avatar || sender?.avatar;

    res.status(201).json({
      success: true,
      message: {
        ...message.toJSON(),
        sender_name: finalSenderName,
        sender_avatar: finalSenderAvatar,
        is_read_by_me: false,
      },
    });
  } catch (err) {
    console.error("Error in sendMessage:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const markMessagesAsRead = async (req, res) => {
  try {
    const { chatId } = req.params;
    const userId = req.user.id;

    const chat = await Chat.findByPk(chatId);
    if (!chat) {
      return res.status(404).json({ message: "Chat not found" });
    }

    const messages = await Message.findAll({
      where: {
        chat_id: chatId,
        is_read: false,
      },
    });

    await Promise.all(
      messages.map(async (message) => {
        const readBy = message.read_by;
        if (!readBy.includes(userId)) {
          readBy.push(userId);
          await message.update({
            read_by: readBy,
            is_read: readBy.length === chat.participant_ids.length,
          });
        }
      }),
    );

    const newUnreadCounts = { ...chat.unread_counts };
    newUnreadCounts[userId] = 0;
    await chat.update({ unread_counts: newUnreadCounts });

    res.json({ success: true, message: "Messages marked as read" });
  } catch (err) {
    console.error("Error in markMessagesAsRead:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const deleteMessage = async (req, res) => {
  try {
    const { messageId } = req.params;
    const userId = req.user.id;

    const message = await Message.findByPk(messageId);
    if (!message) {
      return res.status(404).json({ message: "Message not found" });
    }

    if (message.sender_id !== userId) {
      return res
        .status(403)
        .json({ message: "You can only delete your own messages" });
    }

    await message.destroy();

    res.json({ success: true, message: "Message deleted" });
  } catch (err) {
    console.error("Error in deleteMessage:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getUnreadCount = async (req, res) => {
  try {
    const userId = req.user.id;

    const chats = await Chat.findAll({
      where: {
        [Op.and]: [
          sequelize.literal(`JSON_CONTAINS(participant_ids, '[${userId}]')`),
        ],
      },
    });

    const totalUnread = chats.reduce((sum, chat) => {
      return sum + (chat.unread_counts?.[userId] || 0);
    }, 0);

    res.json({ unreadCount: totalUnread });
  } catch (err) {
    console.error("Error in getUnreadCount:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const createChatFromContract = async (req, res) => {
  try {
    const { contractId } = req.params;
    const userId = req.user.id;

    const contract = await Contract.findByPk(contractId);
    if (!contract) {
      return res.status(404).json({ message: "Contract not found" });
    }

    const otherUserId =
      contract.ClientId === userId ? contract.FreelancerId : contract.ClientId;

    const uniqueId = generateUniqueChatId(userId, otherUserId);
    let chat = await Chat.findOne({ where: { unique_id: uniqueId } });

    if (!chat) {
      chat = await Chat.create({
        unique_id: uniqueId,
        participant_ids: [userId, otherUserId],
        unread_counts: { [userId]: 0, [otherUserId]: 0 },
        status: "active",
      });
    }

    res.json({
      success: true,
      chatId: chat.id,
    });
  } catch (err) {
    console.error("Error in createChatFromContract:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};
