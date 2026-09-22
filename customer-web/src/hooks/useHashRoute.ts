import { useEffect, useState } from "react";

export type RouteInfo = {
  /** e.g. "product" from "#/product/foo" */
  name: string;
  /** remaining segments, e.g. ["foo"] */
  params: string[];
  /** query in the hash, e.g. {category: "drinks"} for "#/browse?category=drinks" */
  query: URLSearchParams;
};

function parse(): RouteInfo {
  const raw = window.location.hash.replace(/^#\/?/, "");
  const [pathPart, queryPart = ""] = raw.split("?");
  const segments = pathPart.split("/").filter(Boolean);
  return {
    name: (segments[0] || "home").toLowerCase(),
    params: segments.slice(1),
    query: new URLSearchParams(queryPart),
  };
}

export function useHashRoute(): RouteInfo {
  const [route, setRoute] = useState(parse);

  useEffect(() => {
    const onChange = () => setRoute(parse());
    window.addEventListener("hashchange", onChange);
    return () => window.removeEventListener("hashchange", onChange);
  }, []);

  return route;
}

export function navigate(path: string, opts: { replace?: boolean } = {}) {
  const hash = `#/${path.replace(/^\/+/, "")}`;
  if (opts.replace) {
    history.replaceState(null, "", hash);
    window.dispatchEvent(new Event("hashchange"));
  } else {
    window.location.hash = hash;
  }
}

export function href(path: string): string {
  return `#/${path.replace(/^\/+/, "")}`;
}
