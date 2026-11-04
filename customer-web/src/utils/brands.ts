import type { Brand } from "../services/api";

/**
 * Last-resort brand facet used when `GET /products/brands/` fails.
 * Keeps the sidebar useful during a transient API outage instead of
 * rendering an empty filter group.
 */
export const FALLBACK_BRANDS = ["Dabur Vatika", "Aswini", "VVD", "Patanjali", "Himalaya"];

export function brandNames(data: Brand[] | { results: Brand[] } | undefined | null): string[] {
  const rows = Array.isArray(data) ? data : data?.results ?? [];
  const names = rows
    .map((row) => (row?.name ?? "").trim())
    .filter((name): name is string => Boolean(name));
  return names.length ? names : [];
}
