/**
 * NEXT_UI vertical-slice screenshots (DESIGN.md §7 acceptance evidence).
 *
 * Captures the flag-gated preview page against LIVE catalog data at
 * 375 / 768 / 1280 wide, light + dark — six shots per run, uploaded as the
 * `preview-shots` artifact. Runs in CI (see preview-shots.yml) against
 * `vite preview` serving the just-built dist; runs locally the same way:
 *   1. npm run build
 *   2. npx vite preview --port 4173 --strictPort
 *   3. npx playwright test --config=screenshots/playwright.config.ts
 *
 * Readiness gates (not beauty assertions): the serif heading renders and at
 * least one populated card renders. The human (or vision-model) critique of
 * the PNGs is the actual verdict — these shots are its input.
 */
import { expect, test } from "@playwright/test";

interface Shot {
  name: string;
  width: number;
  height: number;
  theme: "light" | "dark";
}

const SHOTS: Shot[] = [
  { name: "375-light", width: 375, height: 812, theme: "light" },
  { name: "375-dark", width: 375, height: 812, theme: "dark" },
  { name: "768-light", width: 768, height: 1024, theme: "light" },
  { name: "768-dark", width: 768, height: 1024, theme: "dark" },
  { name: "1280-light", width: 1280, height: 800, theme: "light" },
  { name: "1280-dark", width: 1280, height: 800, theme: "dark" },
];

for (const shot of SHOTS) {
  test(`preview ${shot.name}`, async ({ page }) => {
    await page.setViewportSize({ width: shot.width, height: shot.height });
    // preview.html resolves eg-theme from localStorage before first paint.
    await page.addInitScript(
      (theme: string) => window.localStorage.setItem("eg-theme", theme),
      shot.theme,
    );
    await page.goto("/preview.html?next_ui=1");
    // Live Render API cold-starts can take ~60s — wait generously.
    await page.getByRole("heading", { name: "Fresh picks" }).waitFor({ timeout: 120_000 });
    await expect(page.locator("article").first()).toBeVisible({ timeout: 120_000 });
    // eslint-disable-next-line no-await-in-loop
    await page.waitForTimeout(800); // let washes, fonts and images settle
    await page.screenshot({ path: `screenshots/shots/shot-${shot.name}.png`, fullPage: true });
  });
}
