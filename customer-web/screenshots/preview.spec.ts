/**
 * NEXT_UI vertical-slice screenshots (DESIGN.md §7 acceptance evidence).
 *
 * Captures the flag-gated preview page at 375 / 768 / 1280 wide, light +
 * dark — six shots per run, uploaded as the `preview-shots` artifact. Runs
 * in CI (see preview-shots.yml) against `vite preview` serving the
 * just-built dist; runs locally the same way:
 *   1. npm run build
 *   2. npx vite preview --port 4173 --strictPort
 *   3. npx playwright test --config=screenshots/playwright.config.ts
 *
 * Deterministic by design: the catalog call is fulfilled with a FROZEN
 * capture of real live copy (below), so shots never flake on Render
 * cold-starts, data drift, or CORS (the CI origin is not allow-listed).
 * Refresh FIXTURE from GET /products/ when real copy changes. Images stay
 * null on purpose — live media 404s until Supabase storage lands, so the
 * washes (the surface under review) are what gets screenshotted.
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

/** Frozen 2026-10-04 from GET /api/v1/products/ (names, brands, prices, mrp, ratings verbatim). */
const FIXTURE = [
  { id: 294, name: "Baby skin care products", slug: "baby-skin-care-products", brand: "GlowHerb", base_price: "97.00", mrp: "152.00", rating_avg: 5.0, rating_count: 1, primary_image: null, category: { id: 15, name: "Skin Care", slug: "skin-care" } },
  { id: 295, name: "Deodorant", slug: "deodorant", brand: "SkinMild", base_price: "60.00", mrp: "86.00", rating_avg: null, rating_count: 0, primary_image: null, category: null },
  { id: 296, name: "Hair oil", slug: "hair-oil", brand: "GlowHerb", base_price: "493.00", mrp: "646.00", rating_avg: null, rating_count: 0, primary_image: null, category: null },
  { id: 297, name: "Makeup remover", slug: "makeup-remover", brand: "SkinMild", base_price: "456.00", mrp: "538.00", rating_avg: null, rating_count: 0, primary_image: null, category: null },
  { id: 298, name: "Cleansing milk", slug: "cleansing-milk", brand: "GlowHerb", base_price: "419.00", mrp: "628.00", rating_avg: null, rating_count: 0, primary_image: null, category: null },
  { id: 299, name: "Face oil", slug: "face-oil", brand: "SkinMild", base_price: "382.00", mrp: "523.00", rating_avg: null, rating_count: 0, primary_image: null, category: null },
];

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
    // Fulfill the catalog call locally: no Render cold-start, no drift, no
    // CORS (the CI origin is not allow-listed on the API). Regex, not glob —
    // glob star semantics against query strings proved unreliable.
    await page.route(/\/api\/v1\/products\//, (route) => {
      if (route.request().method() === "OPTIONS") {
        return route.fulfill({
          status: 204,
          headers: {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, OPTIONS",
            "Access-Control-Allow-Headers": "*",
          },
        });
      }
      return route.fulfill({
        status: 200,
        contentType: "application/json",
        headers: { "Access-Control-Allow-Origin": "*" },
        body: JSON.stringify({ results: FIXTURE }),
      });
    });
    await page.goto("/preview.html?next_ui=1");
    await page.getByRole("heading", { name: "Fresh picks" }).waitFor({ timeout: 30_000 });
    await expect(page.locator("article").first()).toBeVisible({ timeout: 30_000 });
    // eslint-disable-next-line no-await-in-loop
    await page.waitForTimeout(800); // let washes, fonts and images settle
    await page.screenshot({ path: `screenshots/shots/shot-${shot.name}.png`, fullPage: true });
  });
}
