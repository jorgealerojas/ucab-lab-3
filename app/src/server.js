import { createApp } from "./app.js";

const port = Number.parseInt(process.env.PORT || "3000", 10);
const server = createApp();

server.listen(port, "0.0.0.0", () => {
  console.log(`ucab-lab-3-api listening on port ${port}`);
});

const shutdown = (signal) => {
  console.log(`${signal} received, shutting down`);
  server.close((error) => {
    if (error) {
      console.error(error);
      process.exit(1);
    }
    process.exit(0);
  });
};

process.on("SIGTERM", () => shutdown("SIGTERM"));
process.on("SIGINT", () => shutdown("SIGINT"));
