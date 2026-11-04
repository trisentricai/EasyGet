import { defineConfig } from "@playwright/test";

/**
 * Storefront E2E suite.
 *
 * Run locally with:
 *   1. backend on http://127.0.0.1:8000
 *   2. npx playwright test
 *
 * The dev server is started automatically unless one is already listening on
 * port 3000 (the normal local setup), so reruns are fast.
 */
export default defineConfig({
  testDir: "./e2e",
  outputDir: "./e2e/.artifacts",
  timeout: 120_000,
  expect: { timeout: 20_000 },
  fullyParallel: false,
  workers: 1,
  retries: 0,
  reporter: "line",
  use: {
    baseURL: "http://127.0.0.1:3000",
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
    viewport: { width: 1280, height: 900 },
  },
  webServer: {
    command: "npm run dev -- --host 127.0.0.1 --port 3000",
    url: "http://127.0.0.1:3000",
    reuseExistingServer: true,
    timeout: 120_000,
  },
});
