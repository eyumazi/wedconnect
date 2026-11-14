import { createHash } from "node:crypto";
import { getApps, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { defineString } from "firebase-functions/params";
import { onRequest } from "firebase-functions/v2/https";
import { Response as ExpressResponse } from "express";

const firebaseWebApiKey = defineString("FIREBASE_WEB_API_KEY");
const maxFailedAttempts = 5;
const lockoutDurationMs = 15 * 60 * 1000;

if (getApps().length === 0) {
  initializeApp();
}

const firestore = getFirestore();

interface LoginLockout {
  failedAttempts?: number;
  lockedUntil?: number;
}

interface FirebasePasswordLoginResponse {
  idToken: string;
  localId: string;
}

function lockoutDocumentId(email: string): string {
  return createHash("sha256").update(email).digest("hex");
}

function isCredentialFailure(errorCode: string): boolean {
  return [
    "EMAIL_NOT_FOUND",
    "INVALID_PASSWORD",
    "INVALID_EMAIL",
  ].includes(errorCode);
}

function sendJson(
  response: ExpressResponse,
  status: number,
  body: Record<string, unknown>,
): void {
  response.set("Cache-Control", "no-store");
  response.status(status).json(body);
}

export const loginWithLockout = onRequest(
  { region: "us-central1", cors: true, timeoutSeconds: 30 },
  async (request, response) => {
    if (request.method !== "POST") {
      sendJson(response, 405, { error: "method-not-allowed" });
      return;
    }

    const email =
      typeof request.body?.email === "string"
        ? request.body.email.trim().toLowerCase()
        : "";
    const password =
      typeof request.body?.password === "string" ? request.body.password : "";

    if (email.length === 0 || password.length === 0) {
      sendJson(response, 400, { error: "invalid-request" });
      return;
    }

    const lockoutRef = firestore
      .collection("loginLockouts")
      .doc(lockoutDocumentId(email));
    const now = Date.now();
    const currentLockout = await firestore.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(lockoutRef);
      const lockout = snapshot.data() as LoginLockout | undefined;

      if (lockout?.lockedUntil && lockout.lockedUntil > now) {
        return lockout;
      }

      if (lockout?.lockedUntil && lockout.lockedUntil <= now) {
        transaction.delete(lockoutRef);
      }

      return undefined;
    });

    if (currentLockout?.lockedUntil && currentLockout.lockedUntil > now) {
      sendJson(response, 423, {
        error: "account-locked",
        retryAfterSeconds: Math.ceil(
          (currentLockout.lockedUntil - now) / 1000,
        ),
      });
      return;
    }

    let firebaseResponse: Response;
    try {
      firebaseResponse = await fetch(
        `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${firebaseWebApiKey.value()}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            email,
            password,
            returnSecureToken: true,
          }),
        },
      );
    } catch (error) {
      console.error("Firebase login request failed", error);
      sendJson(response, 503, { error: "authentication-unavailable" });
      return;
    }

    if (!firebaseResponse.ok) {
      const errorBody = (await firebaseResponse.json()) as {
        error?: { message?: string };
      };
      const errorCode = errorBody.error?.message ?? "AUTHENTICATION_FAILED";

      if (isCredentialFailure(errorCode)) {
        const lockout = await firestore.runTransaction(async (transaction) => {
          const snapshot = await transaction.get(lockoutRef);
          const current = (snapshot.data() as LoginLockout | undefined) ?? {};
          const failedAttempts = (current.failedAttempts ?? 0) + 1;
          const lockedUntil =
            failedAttempts >= maxFailedAttempts
              ? Date.now() + lockoutDurationMs
              : undefined;

          transaction.set(
            lockoutRef,
            {
              failedAttempts,
              ...(lockedUntil ? { lockedUntil } : {}),
              updatedAt: FieldValue.serverTimestamp(),
            },
            { merge: true },
          );

          return { failedAttempts, lockedUntil };
        });

        if (lockout.lockedUntil) {
          sendJson(response, 423, {
            error: "account-locked",
            retryAfterSeconds: Math.ceil(
              (lockout.lockedUntil - Date.now()) / 1000,
            ),
          });
          return;
        }
      }

      sendJson(response, 401, { error: "invalid-credentials" });
      return;
    }

    const login = (await firebaseResponse.json()) as FirebasePasswordLoginResponse;
    const customToken = await getAuth().createCustomToken(login.localId);
    await lockoutRef.delete();

    sendJson(response, 200, { customToken });
  },
);
