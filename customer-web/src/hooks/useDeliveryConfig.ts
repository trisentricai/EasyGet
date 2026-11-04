import { useEffect, useState } from "react";
import { checkPincode } from "../utils/pincode";
import {
  DEFAULT_DELIVERY_CONFIG,
  DELIVERY_FEE,
  FREE_DELIVERY_OVER,
  toNumber,
  type DeliveryConfig,
} from "../utils/pricing";

/**
 * Delivery pricing from the pincode endpoint, with the site fallback when no
 * pincode is known yet. One module-level cache keeps the header, cart, and
 * checkout from re-fetching the same pin.
 */
export const PINCODE_STORAGE_KEY = "eg-pincode";
export const PINCODE_CHANGE_EVENT = "eg-pincode-change";

const configCache = new Map<string, DeliveryConfig>();
const inflight = new Map<string, Promise<DeliveryConfig>>();

function readPincode(): string | null {
  try {
    const pin = localStorage.getItem(PINCODE_STORAGE_KEY)?.trim();
    return pin && /^\d{6}$/.test(pin) ? pin : null;
  } catch {
    return null;
  }
}

/** Remember a serviceable pincode so cart/checkout can price delivery. */
export function rememberPincode(pin: string): void {
  const clean = pin.trim();
  if (!/^\d{6}$/.test(clean)) return;
  try {
    localStorage.setItem(PINCODE_STORAGE_KEY, clean);
  } catch {
    /* storage unavailable — the event still updates this tab */
  }
  window.dispatchEvent(new CustomEvent(PINCODE_CHANGE_EVENT, { detail: clean }));
}

function configFromResponse(res: {
  delivery_fee?: string;
  free_delivery_over?: string;
}): DeliveryConfig {
  const fee = toNumber(res.delivery_fee);
  const threshold = toNumber(res.free_delivery_over);
  return {
    deliveryFee: fee > 0 ? fee : DELIVERY_FEE,
    freeDeliveryOver: threshold > 0 ? threshold : FREE_DELIVERY_OVER,
  };
}

function loadConfig(pin: string): Promise<DeliveryConfig> {
  const cached = configCache.get(pin);
  if (cached) return Promise.resolve(cached);
  const pending = inflight.get(pin);
  if (pending) return pending;

  const request = checkPincode(pin)
    .then((res) => {
      const config = configFromResponse(res);
      configCache.set(pin, config);
      return config;
    })
    .catch(() => DEFAULT_DELIVERY_CONFIG)
    .finally(() => inflight.delete(pin));

  inflight.set(pin, request);
  return request;
}

export function useDeliveryConfig(): {
  config: DeliveryConfig;
  pincode: string | null;
  loading: boolean;
} {
  const [pincode, setPincode] = useState<string | null>(readPincode);
  const [config, setConfig] = useState<DeliveryConfig>(() => {
    const pin = readPincode();
    return (pin && configCache.get(pin)) || DEFAULT_DELIVERY_CONFIG;
  });
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const onChange = (event: Event) => {
      const detail = (event as CustomEvent<string>).detail;
      setPincode(typeof detail === "string" ? detail : readPincode());
    };
    const onStorage = (event: StorageEvent) => {
      if (event.key === PINCODE_STORAGE_KEY) setPincode(readPincode());
    };
    window.addEventListener(PINCODE_CHANGE_EVENT, onChange);
    window.addEventListener("storage", onStorage);
    return () => {
      window.removeEventListener(PINCODE_CHANGE_EVENT, onChange);
      window.removeEventListener("storage", onStorage);
    };
  }, []);

  useEffect(() => {
    if (!pincode) {
      setConfig(DEFAULT_DELIVERY_CONFIG);
      setLoading(false);
      return;
    }

    let cancelled = false;
    const cached = configCache.get(pincode);
    if (cached) {
      setConfig(cached);
      setLoading(false);
      return;
    }

    setLoading(true);
    void loadConfig(pincode).then((next) => {
      if (!cancelled) {
        setConfig(next);
        setLoading(false);
      }
    });
    return () => {
      cancelled = true;
    };
  }, [pincode]);

  return { config, pincode, loading };
}
