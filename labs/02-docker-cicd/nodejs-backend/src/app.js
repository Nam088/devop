const express = require("express");

function createApp() {
  const app = express();
  let isShuttingDown = false;

  // Middleware từ chối request mới khi nhận lệnh shutdown
  app.use((req, res, next) => {
    if (isShuttingDown) {
      res.setHeader("Connection", "close");
      return res.status(503).json({ error: "Server is shutting down..." });
    }
    next();
  });

  // Health check endpoint (phục vụ Docker / K8s probes)
  app.get("/health", (req, res) => {
    res.status(200).json({
      status: "healthy",
      uptime: process.uptime(),
      pid: process.pid,
      uid: process.getuid ? process.getuid() : null
    });
  });

  // Root API
  app.get("/", (req, res) => {
    res.status(200).json({
      message: "Hello from Production Node.js Container!",
      user_id: process.getuid ? process.getuid() : "unknown",
      environment: process.env.NODE_ENV || "development"
    });
  });

  // Helper kích hoạt trạng thái shutdown
  app.setShuttingDown = () => {
    isShuttingDown = true;
  };

  return app;
}

module.exports = { createApp };
