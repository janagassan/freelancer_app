// backend/src/services/websocketService.js
import { Server } from "socket.io";

let io;

export const initWebSocket = (server) => {
  if (io) {
    console.log("⚠️ WebSocket already initialized");
    return io;
  }

  io = new Server(server, {
    cors: {
      origin: [
        "https://freelancer-app-h6os.onrender.com",
        "https://freelancer-app-h6os.onrender.com",
        "https://freelancer-app-h6os.onrender.com/api",
        "http://127.0.0.1:3000",
      ],
      methods: ["GET", "POST"],
      credentials: true,
    },
    transports: ["websocket", "polling"],
    allowEIO3: true,
    path: "/socket.io-interview",
  });

  io.use((socket, next) => {
    const userId = socket.handshake.auth.userId;
    const token = socket.handshake.auth.token;

    console.log("🔐 WebSocket auth - userId:", userId);

    if (!userId) {
      console.log("❌ WebSocket auth failed: No userId");
      return next(new Error("Authentication error"));
    }

    socket.userId = userId;
    next();
  });

  io.on("connection", (socket) => {
    console.log(`🔌 WebSocket connected: User ${socket.userId}`);

    socket.join(`user_${socket.userId}`);

    socket.emit("connected", {
      message: "Connected to interview service",
      userId: socket.userId,
      timestamp: new Date().toISOString(),
    });

    socket.on("user_connected", (data) => {
      console.log(`📱 User ${socket.userId} confirmed connection:`, data);
    });

    socket.on("disconnect", (reason) => {
      console.log(
        `🔌 WebSocket disconnected: User ${socket.userId}, reason: ${reason}`,
      );
    });

    socket.on("error", (error) => {
      console.error(`WebSocket error for user ${socket.userId}:`, error);
    });
  });

  return io;
};

export const emitToUser = (userId, event, data) => {
  if (io) {
    console.log(`📡 Emitting ${event} to user ${userId}`);
    io.to(`user_${userId}`).emit(event, data);
  }
};

export const getIO = () => io;
