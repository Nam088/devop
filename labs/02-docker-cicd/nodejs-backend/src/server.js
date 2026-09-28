const { createApp } = require("./app");

const PORT = process.env.PORT || 3000;
const app = createApp();

const server = app.listen(PORT, () => {
  const uid = process.getuid ? process.getuid() : "N/A";
  console.log(`[START] Server running on port ${PORT} (PID: ${process.pid}, UID: ${uid})`);
});

// XỬ LÝ GRACEFUL SHUTDOWN KHI CONTAINER DỪNG (SIGTERM)
function gracefulShutdown(signal) {
  console.log(`\n[SHUTDOWN] Received ${signal}. Starting graceful shutdown sequence...`);
  app.setShuttingDown();

  server.close(() => {
    console.log("[SHUTDOWN] HTTP server closed. In-flight requests completed.");
    
    // Giả lập đóng database connection pool sạch sẽ
    console.log("[SHUTDOWN] Draining and closing database connection pool...");
    setTimeout(() => {
      console.log("[SHUTDOWN] Database pool closed cleanly. Exiting with code 0.");
      process.exit(0);
    }, 500);
  });

  // Timeout dự phòng: Cưỡng chế thoát sau 10s nếu có kết nối bị treo
  setTimeout(() => {
    console.error("[SHUTDOWN] Forceful shutdown timeout exceeded!");
    process.exit(1);
  }, 10000).unref();
}

process.on("SIGTERM", () => gracefulShutdown("SIGTERM"));
process.on("SIGINT", () => gracefulShutdown("SIGINT"));

module.exports = server;
