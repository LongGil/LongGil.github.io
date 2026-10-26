#!/usr/bin/env node
/**
 * Official Long Gil Studio CLI (@longgilstudio/cli)
 * Usage:
 *   node lgs.mjs info
 *   node lgs.mjs projects [--format json]
 *   node lgs.mjs sandbox
 */

const BASE_URL = process.env.LGS_API_URL || "https://longgilstudio.com";
const args = process.argv.slice(2);
const command = (args[0] || "info").toLowerCase();

const ENDPOINTS = {
  info: "/v1/studio.json",
  studio: "/v1/studio.json",
  projects: "/v1/projects.json",
  games: "/v1/projects.json",
  sandbox: "/v1/sandbox.json",
  openapi: "/openapi.json"
};

async function main() {
  if (command === "--help" || command === "-h" || command === "help") {
    console.log("Long Gil Studio CLI (@longgilstudio/cli v1.0.0)");
    console.log("Usage: lgs <command>");
    console.log("Commands: info | projects | sandbox | openapi");
    process.exit(0);
  }

  const path = ENDPOINTS[command] || ENDPOINTS.info;
  const res = await fetch(`${BASE_URL}${path}`, {
    headers: {
      "Accept": "application/json",
      "X-API-Version": "v1",
      "User-Agent": "longgilstudio-cli/1.0.0"
    }
  });

  if (!res.ok) {
    console.error(`Error ${res.status}: Failed to fetch ${path}`);
    process.exit(1);
  }

  const data = await res.json();
  console.log(JSON.stringify(data, null, 2));
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});

