import assert from "node:assert/strict";
import { afterEach, test } from "node:test";
import { createApp } from "../src/app.js";

const servers = [];

afterEach(async () => {
  await Promise.all(servers.splice(0).map((server) => new Promise((resolve) => server.close(resolve))));
});

const start = async (options) => {
  const server = createApp(options);
  servers.push(server);
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  const { port } = server.address();
  return `http://127.0.0.1:${port}`;
};

test("GET / devuelve identidad, versión, mensaje y hostname", async () => {
  const baseUrl = await start({ version: "v1", message: "mensaje de prueba", hostname: "pod-abc" });
  const response = await fetch(`${baseUrl}/`);

  assert.equal(response.status, 200);
  assert.match(response.headers.get("content-type"), /^application\/json/);
  assert.deepEqual(await response.json(), {
    service: "ucab-lab-3-api",
    version: "v1",
    message: "mensaje de prueba",
    hostname: "pod-abc",
  });
});

test("GET /health informa que el proceso está saludable", async () => {
  const baseUrl = await start();
  const response = await fetch(`${baseUrl}/health`);

  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { status: "ok" });
});

test("una ruta inexistente devuelve 404 en JSON", async () => {
  const baseUrl = await start();
  const response = await fetch(`${baseUrl}/no-existe`);

  assert.equal(response.status, 404);
  assert.deepEqual(await response.json(), { error: "not_found" });
});

test("un método distinto de GET devuelve 405", async () => {
  const baseUrl = await start();
  const response = await fetch(`${baseUrl}/`, { method: "POST" });

  assert.equal(response.status, 405);
  assert.deepEqual(await response.json(), { error: "method_not_allowed" });
});
