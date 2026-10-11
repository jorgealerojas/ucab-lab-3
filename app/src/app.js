import http from "node:http";
import os from "node:os";

const sendJson = (response, statusCode, payload) => {
  response.writeHead(statusCode, { "content-type": "application/json; charset=utf-8" });
  response.end(JSON.stringify(payload));
};

export const createRequestHandler = ({
  version = process.env.APP_VERSION || "dev",
  message = process.env.APP_MESSAGE || "Hola desde UCAB Lab 3",
  hostname = os.hostname(),
} = {}) => {
  return (request, response) => {
    if (request.method !== "GET") {
      sendJson(response, 405, { error: "method_not_allowed" });
      return;
    }

    const url = new URL(request.url, "http://localhost");

    if (url.pathname === "/health") {
      sendJson(response, 200, { status: "ok" });
      return;
    }

    if (url.pathname === "/") {
      sendJson(response, 200, {
        service: "ucab-lab-3-api",
        version,
        message,
        hostname,
      });
      return;
    }

    sendJson(response, 404, { error: "not_found" });
  };
};

export const createApp = (options) => http.createServer(createRequestHandler(options));
