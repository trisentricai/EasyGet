import { useEffect, useState } from "react";

/** Minimal hash router: "#/storefront" → "storefront". Default: "dashboard". */
export function useHashRoute(): string {
  const pick = () =>
    (window.location.hash.replace(/^#\/?/, "").split("/")[0] || "dashboard").toLowerCase();

  const [route, setRoute] = useState(pick);

  useEffect(() => {
    const onChange = () => setRoute(pick());
    window.addEventListener("hashchange", onChange);
    return () => window.removeEventListener("hashchange", onChange);
  }, []);

  return route;
}

export function navigate(route: string) {
  window.location.hash = `#/${route}`;
}
