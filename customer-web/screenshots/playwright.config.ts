import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: ".",
  testMatch: "preview.spec.ts",
  outputDir: "./shots",
  // Live API cold start + font fetch: be patient, fail loudly instead.
  timeout: 180_000,
  retries: 0,
  reporter: "line",
  use: {
    baseURL: "http://127.0.0.1:4173",
  },
});
