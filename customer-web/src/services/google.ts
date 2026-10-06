/**
 * Google sign-in WITHOUT Firebase (Google Identity Services).
 *
 * Renders Google's official button, resolves with a Google ID token, and
 * exchanges it at POST /auth/google/ for our JWT pair (same shape as
 * /auth/login/, so token storage and everything downstream is untouched).
 *
 * Client ID comes from VITE_GOOGLE_CLIENT_ID baked at build time. When
 * absent, isGoogleConfigured() is false and callers hide the button —
 * never a crash, never a dead button.
 */
import { api, type LoginResponse } from "./api";

interface GsiCredentialResponse {
  credential?: string;
}

interface GsiAccounts {
  id: {
    initialize(options: {
      client_id: string;
      callback: (response: GsiCredentialResponse) => void;
    }): void;
    renderButton(
      element: HTMLElement,
      options?: {
        type?: string;
        theme?: string;
        size?: string;
        text?: string;
        shape?: string;
        width?: number;
      },
    ): void;
  };
}

declare global {
  interface Window {
    google?: { accounts?: GsiAccounts };
  }
}

export function googleClientId(): string | null {
  const id = import.meta.env.VITE_GOOGLE_CLIENT_ID as string | undefined;
  return id && id.length > 0 ? id : null;
}

export function isGoogleConfigured(): boolean {
  return googleClientId() !== null;
}

let scriptPromise: Promise<void> | null = null;

function ensureGsiScript(): Promise<void> {
  if (typeof window === "undefined") return Promise.reject(new Error("No window."));
  if (window.google?.accounts?.id) return Promise.resolve();
  if (!scriptPromise) {
    scriptPromise = new Promise<void>((resolve, reject) => {
      const script = document.createElement("script");
      script.src = "https://accounts.google.com/gsi/client";
      script.async = true;
      script.defer = true;
      script.onload = () => resolve();
      script.onerror = () =>
        reject(new Error("Could not load Google sign-in. Check your connection."));
      document.head.appendChild(script);
    });
  }
  return scriptPromise;
}

/**
 * Render the official Google button into `element`. Resolves with the Google
 * ID token on success; never resolves when the user closes the popup.
 */
export async function renderGoogleButton(
  element: HTMLElement,
  onToken: (idToken: string) => void,
): Promise<void> {
  const clientId = googleClientId();
  if (!clientId) throw new Error("Google login is not configured.");
  await ensureGsiScript();
  const accounts = window.google?.accounts;
  if (!accounts) throw new Error("Could not load Google sign-in. Check your connection.");
  accounts.id.initialize({
    client_id: clientId,
    callback: (response) => {
      if (response.credential) onToken(response.credential);
    },
  });
  accounts.id.renderButton(element, {
    type: "standard",
    theme: "outline",
    size: "large",
    text: "continue_with",
    shape: "pill",
    width: 320,
  });
}

/** Exchange a Google ID token for our access+refresh pair. */
export async function loginWithGoogle(idToken: string): Promise<LoginResponse> {
  return api<LoginResponse>("/auth/google/", {
    method: "POST",
    body: { id_token: idToken },
  });
}
