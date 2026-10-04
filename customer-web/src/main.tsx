import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import App from "./App";
// DESIGN.md §1 numeric face: Geist Mono for prices, ETAs, order IDs.
// Loaded via fontsource (bundled, no extra round-trip); Cormorant Garamond
// and Inter come from the Google Fonts link in index.html.
import "@fontsource/geist-mono/400.css";
import "@fontsource/geist-mono/500.css";
// Token layer first: it declares the custom properties the legacy stylesheet
// resolves against, and it must be present before any component that reads
// var(--color-canvas) or similar. Additive — styles.css still owns layout.
import "./theme/index.css";
import "./styles.css";

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
