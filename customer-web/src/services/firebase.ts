/**
 * Firebase Auth for customer login (Session 2).
 *
 * Firebase verifies identity (Google / email+password); our backend mints
 * the JWT pair (POST /auth/firebase/), so token storage, refresh, logout,
 * roles and everything downstream stay exactly as they are.
 *
 * Config comes from VITE_FIREBASE_* baked at build time. When absent (local
 * dev without Firebase), every helper reports unconfigured and the UI hides
 * the Firebase paths — never a crash, never a half-wired button.
 */
import {
  GoogleAuthProvider,
  createUserWithEmailAndPassword,
  getAuth,
  signInWithEmailAndPassword,
  signInWithPopup,
  type Auth,
} from "firebase/auth";
import { initializeApp, type FirebaseApp } from "firebase/app";
import { api, type LoginResponse } from "./api";

let app: FirebaseApp | null = null;
let auth: Auth | null = null;

function config() {
  const env = import.meta.env;
  const apiKey = env.VITE_FIREBASE_API_KEY as string | undefined;
  const authDomain = env.VITE_FIREBASE_AUTH_DOMAIN as string | undefined;
  const projectId = env.VITE_FIREBASE_PROJECT_ID as string | undefined;
  const appId = env.VITE_FIREBASE_APP_ID as string | undefined;
  if (!apiKey || !authDomain || !projectId || !appId) return null;
  return { apiKey, authDomain, projectId, appId };
}

/** False when the build carries no Firebase config — hide Firebase UI. */
export function isFirebaseConfigured(): boolean {
  return config() !== null;
}

function getAuthInstance(): Auth {
  if (!auth) {
    const cfg = config();
    if (!cfg) throw new Error("Firebase is not configured in this build.");
    app ??= initializeApp(cfg);
    auth = getAuth(app);
  }
  return auth;
}

/** Google popup -> Firebase ID token. Throws nothing on user-cancel (null). */
export async function signInWithGoogle(): Promise<string | null> {
  const result = await signInWithPopup(getAuthInstance(), new GoogleAuthProvider());
  return result.user.getIdToken();
}

export async function signUpWithEmail(email: string, password: string): Promise<string> {
  const cred = await createUserWithEmailAndPassword(getAuthInstance(), email, password);
  return cred.user.getIdToken();
}

export async function signInWithEmail(email: string, password: string): Promise<string> {
  const cred = await signInWithEmailAndPassword(getAuthInstance(), email, password);
  return cred.user.getIdToken();
}

/** Exchange a Firebase ID token for our access+refresh pair (same shape as /auth/login/). */
export async function loginWithFirebase(idToken: string): Promise<LoginResponse> {
  return api<LoginResponse>("/auth/firebase/", {
    method: "POST",
    body: { id_token: idToken },
  });
}

/**
 * Map Firebase error codes to display text. Returns null when the user
 * simply cancelled (popup closed) — callers should stay silent then.
 */
export function firebaseErrorText(e: unknown): string | null {
  const code =
    typeof e === "object" && e !== null && "code" in e && typeof (e as { code: unknown }).code === "string"
      ? (e as { code: string }).code
      : "";
  switch (code) {
    case "auth/popup-closed-by-user":
    case "auth/cancelled-popup-request":
      return null;
    case "auth/unauthorized-domain":
      return "This site isn't allowlisted in Firebase console (Authentication → Settings → Authorized domains).";
    case "auth/operation-not-allowed":
      return "This sign-in method is disabled in Firebase console.";
    case "auth/user-not-found":
    case "auth/wrong-password":
    case "auth/invalid-credential":
      return "Invalid email or password.";
    case "auth/email-already-in-use":
      return "Email already registered. Sign in instead.";
    case "auth/weak-password":
      return "Password must be at least 6 characters.";
    case "auth/invalid-email":
      return "Enter a valid email address.";
    case "auth/too-many-requests":
      return "Too many attempts. Try again in a few minutes.";
    default:
      return e instanceof Error ? e.message : "Firebase sign-in failed.";
  }
}
