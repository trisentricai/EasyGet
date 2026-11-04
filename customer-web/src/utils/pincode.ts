import {
  ApiError,
  checkPincode as checkBackendPincode,
  type PincodeResult,
} from "../services/api";

/**
 * One pincode lookup for the whole storefront.
 *
 * The Django endpoint is authoritative for serviceability, delivery ETA and
 * fees. It already falls back to a format-only result if postalpincode.in is
 * down, so when city/state are missing we ask the public postal API directly
 * as a second chance. Results (including the enriched fallback) are cached in
 * memory for the session and concurrent callers share one request.
 */

export type PincodeLookup = Omit<PincodeResult, "source"> & {
  city: string | null;
  state: string | null;
  source: "api" | "postal" | "fallback";
};

type PostalOffice = {
  Name?: string;
  District?: string;
  State?: string;
};

type PostalResponse = {
  Status?: string;
  Message?: string;
  PostOffice?: PostalOffice[];
};

const cache = new Map<string, PincodeLookup>();
const inflight = new Map<string, Promise<PincodeLookup>>();

const POSTAL_API = "https://api.postalpincode.in/pincode";

/** Postal API shape → the city/state fields our address form needs. */
async function lookupPostal(pin: string): Promise<{
  city: string | null;
  state: string | null;
} | null> {
  try {
    const res = await fetch(`${POSTAL_API}/${encodeURIComponent(pin)}`, {
      headers: { Accept: "application/json" },
    });
    if (!res.ok) return null;
    const data = (await res.json()) as PostalResponse[] | PostalResponse;
    const entry = Array.isArray(data) ? data[0] : data;
    const office = entry?.PostOffice?.[0];
    if (!office) return null;
    const city = office.District?.trim() || office.Name?.trim() || null;
    const state = office.State?.trim() || null;
    if (!city && !state) return null;
    return { city, state };
  } catch {
    return null;
  }
}

/**
 * Resolve a PIN into serviceability + delivery metadata.
 *
 * Throws when the backend and postal fallback are both unreachable. An
 * explicit backend 404 (not serviceable/invalid) is always surfaced as an
 * ApiError so callers can show the backend's reason.
 */
export function checkPincode(pin: string): Promise<PincodeLookup> {
  const clean = pin.trim();
  if (!/^\d{6}$/.test(clean)) {
    return Promise.reject(new Error("Pincode must be exactly 6 digits."));
  }

  const cached = cache.get(clean);
  if (cached) return Promise.resolve(cached);

  const pending = inflight.get(clean);
  if (pending) return pending;

  const request = (async (): Promise<PincodeLookup> => {
    let backend: PincodeResult | null = null;
    let backendError: unknown = null;

    try {
      backend = await checkBackendPincode(clean);
    } catch (error) {
      // A 404 is an explicit serviceability answer from the backend, not a
      // transport failure: never let the postal fallback turn it into a
      // deliverable pin.
      if (error instanceof ApiError && error.status === 404) throw error;
      backendError = error;
    }

    const needsCityState = !backend?.city || !backend?.state;
    const postal = needsCityState ? await lookupPostal(clean) : null;

    if (postal) {
      const result: PincodeLookup = {
        valid: backend?.valid ?? true,
        reason: backend?.reason,
        pincode: clean,
        city: postal.city ?? backend?.city ?? null,
        state: postal.state ?? backend?.state ?? null,
        eta_days: backend?.eta_days ?? 4,
        delivery_fee: backend?.delivery_fee ?? "29.00",
        free_delivery_over: backend?.free_delivery_over ?? "499.00",
        source: "postal",
      };
      cache.set(clean, result);
      return result;
    }

    if (backend) {
      const result: PincodeLookup = {
        ...backend,
        city: backend.city ?? null,
        state: backend.state ?? null,
        source: backend.source ?? "fallback",
      };
      cache.set(clean, result);
      return result;
    }

    throw backendError ?? new Error("Couldn't check this pincode");
  })().finally(() => inflight.delete(clean));

  inflight.set(clean, request);
  return request;
}
