const test = require("node:test");
const assert = require("node:assert");
const { createApp } = require("../src/app");

test("GET /health should return 200 and healthy status", async (t) => {
  const app = createApp();
  const server = app.listen(0); // Cổng ngẫu nhiên
  const port = server.address().port;

  try {
    const res = await fetch(`http://127.0.0.1:${port}/health`);
    assert.strictEqual(res.status, 200);

    const data = await res.json();
    assert.strictEqual(data.status, "healthy");
    assert.ok(typeof data.uptime === "number");
  } finally {
    server.close();
  }
});

test("GET / should return 200 and welcome message", async (t) => {
  const app = createApp();
  const server = app.listen(0);
  const port = server.address().port;

  try {
    const res = await fetch(`http://127.0.0.1:${port}/`);
    assert.strictEqual(res.status, 200);

    const data = await res.json();
    assert.ok(data.message.includes("Production"));
  } finally {
    server.close();
  }
});
