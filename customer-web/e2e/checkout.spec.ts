import { expect, test, type APIRequestContext, type Page } from "@playwright/test";

/**
 * End-to-end checkout journey:
 * home -> product -> add to cart -> cart -> checkout -> COD -> confirmation.
 *
 * Auth is injected through the seeded demo account, so the test exercises the
 * real signed-in cart/address/order APIs rather than mocking application state.
 * Override the account or API origin with E2E_EMAIL / E2E_PASSWORD / E2E_API_URL.
 */

const API = (process.env.E2E_API_URL ?? "http://127.0.0.1:8000/api/v1").replace(/\/+$/, "");
const EMAIL = process.env.E2E_EMAIL ?? "customer@easyget.app";
const PASSWORD = process.env.E2E_PASSWORD ?? "Customer@123";

type Tokens = { access: string; refresh: string };

async function login(request: APIRequestContext): Promise<Tokens> {
  const response = await request.post(`${API}/auth/login/`, {
    data: { email: EMAIL, password: PASSWORD },
  });
  expect(
    response.ok(),
    `Demo login failed (${response.status()}): ${await response.text()}`,
  ).toBeTruthy();
  return (await response.json()) as Tokens;
}

async function clearServerCart(request: APIRequestContext, access: string) {
  // Best effort: a fresh account has no cart yet.
  await request.delete(`${API}/cart/clear/`, {
    headers: { Authorization: `Bearer ${access}` },
  });
}

function trackAnalytics(page: Page): string[] {
  const events: string[] = [];
  page.on("console", (message) => {
    const match = /^\[Analytics\] ([a-z_]+)/.exec(message.text());
    if (match) events.push(match[1]);
  });
  return events;
}

test("home → product → cart → COD checkout → confirmation", async ({ page, request }) => {
  const tokens = await login(request);
  await clearServerCart(request, tokens.access);

  const analytics = trackAnalytics(page);

  // Arrive already signed in, with no stale guest/cart state.
  await page.addInitScript((session: Tokens) => {
    localStorage.clear();
    localStorage.setItem("eg-cust-tokens", JSON.stringify(session));
  }, tokens);

  await page.goto("/");

  const firstProduct = page.locator("a.product-card").first();
  await expect(firstProduct).toBeVisible({ timeout: 60_000 });
  await firstProduct.click();
  await expect(page).toHaveURL(/#\/product\//);

  const addToCart = page.locator(".buybox-actions button.btn-cart");
  await expect(addToCart).toBeEnabled();
  await addToCart.click();
  await expect(page.getByText("Added to cart")).toBeVisible();

  await page.locator("a.nav-cart").first().click();
  await expect(page).toHaveURL(/#\/cart$/);

  const proceed = page.getByRole("button", { name: "Proceed to checkout" });
  await expect(proceed).toBeEnabled();
  await proceed.click();
  await expect(page).toHaveURL(/#\/checkout$/);
  await expect(page.getByRole("heading", { name: "Checkout" })).toBeVisible();

  // The demo account may or may not already have an address.
  const saveAddress = page.getByRole("button", { name: "Save address" });
  const firstAddress = page.locator("label.addr-option").first();
  await expect(saveAddress.or(firstAddress)).toBeVisible();

  if (await saveAddress.isVisible()) {
    const fields = page.locator(".checkout-steps .form-grid input");
    await fields.nth(1).fill("9876543210");
    await fields.nth(2).fill("12 E2E Test Street");
    await fields.nth(4).fill("Chennai");
    await fields.nth(5).fill("Tamil Nadu");
    await fields.nth(6).fill("600001");
    await saveAddress.click();
    await expect(firstAddress).toBeVisible();
  } else {
    await firstAddress.click();
  }

  const cod = page.locator("label.pay-option").filter({ hasText: "Cash on Delivery" });
  await cod.click();
  await expect(cod).toHaveClass(/selected/);

  const placeOrder = page.getByRole("button", { name: /Place order/i });
  await expect(placeOrder).toBeEnabled();
  await placeOrder.click();

  await expect(page).toHaveURL(/#\/order\/[^/]+\/confirmation$/, { timeout: 60_000 });
  await expect(
    page.getByRole("heading", { name: "Order Placed Successfully!" }),
  ).toBeVisible();

  // Funnel events must fire exactly once despite StrictMode and re-renders.
  await expect
    .poll(() => analytics.filter((event) => event === "view_item").length)
    .toBe(1);
  await expect
    .poll(() => analytics.filter((event) => event === "add_to_cart").length)
    .toBe(1);
  await expect
    .poll(() => analytics.filter((event) => event === "begin_checkout").length)
    .toBe(1);
  await expect
    .poll(() => analytics.filter((event) => event === "purchase").length)
    .toBe(1);
});
