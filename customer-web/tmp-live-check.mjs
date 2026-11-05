import { chromium } from "@playwright/test";

const browser = await chromium.launch({ headless: true });
const base = "https://easyget-customer.pages.dev";

async function desktopPdp() {
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  const errors = [];
  page.on("console", (m) => {
    if (m.type() === "error") errors.push(m.text());
  });
  await page.goto(`${base}/#/product/lux-rose`, { waitUntil: "networkidle", timeout: 120000 });
  await page.waitForTimeout(2500);

  const before = await page.evaluate(() => {
    const el = (sel) => document.querySelector(sel);
    const box = (sel) => {
      const e = el(sel);
      if (!e) return null;
      const r = e.getBoundingClientRect();
      return { x: Math.round(r.x), y: Math.round(r.y), w: Math.round(r.width), h: Math.round(r.height) };
    };
    const btn = el(".buybox-actions .btn-cart");
    const cs = btn ? getComputedStyle(btn) : null;
    const img = el(".pdp-stage-img");
    return {
      title: document.title,
      productTitle: el(".detail-title")?.textContent?.trim(),
      price: el(".pdp-price .now")?.textContent?.trim(),
      cartButton: box(".buybox-actions .btn-cart"),
      buyButton: box(".buybox-actions .btn-buy"),
      buttonFont: cs?.fontSize,
      buttonWeight: cs?.fontWeight,
      buttonDisplay: cs ? getComputedStyle(el(".buybox-actions")).gridTemplateColumns : null,
      stickybar: el(".pdp-stickybar") ? getComputedStyle(el(".pdp-stickybar")).display : "missing",
      buybox: box(".buybox"),
      imageSrc: img?.getAttribute("src"),
      imageLoaded: img ? img.complete && img.naturalWidth > 0 : null,
      fallbackShown: Boolean(el(".pdp-stage-fallback")),
      overflowX: document.documentElement.scrollWidth - document.documentElement.clientWidth,
      primary: getComputedStyle(document.documentElement).getPropertyValue("--primary").trim(),
    };
  });

  // Scroll until the buy box has room to stick, then confirm top == 100.
  await page.evaluate(() => window.scrollTo(0, 700));
  await page.waitForTimeout(800);
  const scrolled = await page.evaluate(() => {
    const b = document.querySelector(".buybox")?.getBoundingClientRect();
    const g = document.querySelector(".pdp-gallery")?.getBoundingClientRect();
    return {
      buyboxTop: b ? Math.round(b.top) : null,
      galleryTop: g ? Math.round(g.top) : null,
      scrollY: Math.round(window.scrollY),
      stickybar: document.querySelector(".pdp-stickybar")
        ? getComputedStyle(document.querySelector(".pdp-stickybar")).display
        : "missing",
    };
  });

  // Scroll to the very bottom of the product detail row to see the buy box release.
  await page.evaluate(() => {
    const detail = document.querySelector(".product-detail");
    if (!detail) return;
    const bottom = detail.getBoundingClientRect().bottom + window.scrollY;
    window.scrollTo(0, Math.max(0, bottom - window.innerHeight + 120));
  });
  await page.waitForTimeout(800);
  const released = await page.evaluate(() => {
    const b = document.querySelector(".buybox")?.getBoundingClientRect();
    const d = document.querySelector(".product-detail")?.getBoundingClientRect();
    return {
      buyboxTop: b ? Math.round(b.top) : null,
      buyboxBottom: b ? Math.round(b.bottom) : null,
      detailBottom: d ? Math.round(d.bottom) : null,
      scrollY: Math.round(window.scrollY),
    };
  });

  await page.screenshot({ path: "C:/Users/Rahul/AppData/Local/Temp/opencode/prod-pdp-desktop.png", fullPage: false });
  await page.close();
  return { before, scrolled, released, errors };
}

async function home() {
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  const errors = [];
  page.on("console", (m) => {
    if (m.type() === "error") errors.push(m.text());
  });
  await page.goto(`${base}/#/home`, { waitUntil: "networkidle", timeout: 120000 });
  await page.waitForTimeout(2500);
  const result = await page.evaluate(() => {
    const imgs = [...document.querySelectorAll("img")];
    const hero = [...document.querySelectorAll(".hero-slide img, .carousel-slide img, .hero-media img, .carousel img")];
    return {
      primary: getComputedStyle(document.documentElement).getPropertyValue("--primary").trim(),
      heroSlides: document.querySelectorAll(".hero-slide, .carousel-slide").length,
      heroImages: hero.length,
      heroLoaded: hero.filter((i) => i.complete && i.naturalWidth > 0).length,
      categoryTiles: document.querySelectorAll(".cat-tile").length,
      categoryBanners: document.querySelectorAll(".cat-banner").length,
      productCards: document.querySelectorAll(".product-card").length,
      productImages: imgs.filter((i) => i.closest(".product-card")).length,
      broken: imgs.filter((i) => i.complete && i.naturalWidth === 0).map((i) => i.src).slice(0, 8),
      overflowX: document.documentElement.scrollWidth - document.documentElement.clientWidth,
    };
  });
  await page.screenshot({ path: "C:/Users/Rahul/AppData/Local/Temp/opencode/prod-home.png" });
  await page.close();
  return { result, errors };
}

async function mobile() {
  const page = await browser.newPage({ viewport: { width: 390, height: 844 }, isMobile: true, hasTouch: true });
  const errors = [];
  page.on("console", (m) => {
    if (m.type() === "error") errors.push(m.text());
  });
  await page.goto(`${base}/#/product/lux-rose`, { waitUntil: "networkidle", timeout: 120000 });
  await page.waitForTimeout(2500);
  const result = await page.evaluate(() => {
    const el = (sel) => document.querySelector(sel);
    const box = (sel) => {
      const e = el(sel);
      if (!e) return null;
      const r = e.getBoundingClientRect();
      return { x: Math.round(r.x), y: Math.round(r.y), w: Math.round(r.width), h: Math.round(r.height) };
    };
    const img = el(".pdp-stage-img");
    return {
      cartButton: box(".buybox-actions .btn-cart"),
      stickybar: el(".pdp-stickybar") ? getComputedStyle(el(".pdp-stickybar")).display : "missing",
      stickyCart: box(".pdp-stickybar .btn-cart"),
      stickyBuy: box(".pdp-stickybar .btn-buy"),
      stage: box(".pdp-stage"),
      imageLoaded: img ? img.complete && img.naturalWidth > 0 : null,
      overflowX: document.documentElement.scrollWidth - document.documentElement.clientWidth,
    };
  });
  await page.screenshot({ path: "C:/Users/Rahul/AppData/Local/Temp/opencode/prod-pdp-mobile.png" });
  await page.close();
  return { result, errors };
}

const [pdp, homeResult, mobileResult] = await Promise.all([desktopPdp(), home(), mobile()]);
console.log("DESKTOP_PDP", JSON.stringify(pdp, null, 2));
console.log("HOME", JSON.stringify(homeResult, null, 2));
console.log("MOBILE_PDP", JSON.stringify(mobileResult, null, 2));
await browser.close();
