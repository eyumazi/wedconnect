"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.loginWithLockout = void 0;
const node_crypto_1 = require("node:crypto");
const app_1 = require("firebase-admin/app");
const auth_1 = require("firebase-admin/auth");
const firestore_1 = require("firebase-admin/firestore");
const params_1 = require("firebase-functions/params");
const https_1 = require("firebase-functions/v2/https");
const firebaseWebApiKey = (0, params_1.defineString)("FIREBASE_WEB_API_KEY");
const maxFailedAttempts = 5;
const lockoutDurationMs = 15 * 60 * 1000;
if ((0, app_1.getApps)().length === 0) {
    (0, app_1.initializeApp)();
}
const firestore = (0, firestore_1.getFirestore)();
function lockoutDocumentId(email) {
    return (0, node_crypto_1.createHash)("sha256").update(email).digest("hex");
}
function isCredentialFailure(errorCode) {
    return [
        "EMAIL_NOT_FOUND",
        "INVALID_PASSWORD",
        "INVALID_EMAIL",
    ].includes(errorCode);
}
function sendJson(response, status, body) {
    response.set("Cache-Control", "no-store");
    response.status(status).json(body);
}
exports.loginWithLockout = (0, https_1.onRequest)({ region: "us-central1", cors: true, timeoutSeconds: 30 }, async (request, response) => {
    if (request.method !== "POST") {
        sendJson(response, 405, { error: "method-not-allowed" });
        return;
    }
    const email = typeof request.body?.email === "string"
        ? request.body.email.trim().toLowerCase()
        : "";
    const password = typeof request.body?.password === "string" ? request.body.password : "";
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
        const lockout = snapshot.data();
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
            retryAfterSeconds: Math.ceil((currentLockout.lockedUntil - now) / 1000),
        });
        return;
    }
    let firebaseResponse;
    try {
        firebaseResponse = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${firebaseWebApiKey.value()}`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
                email,
                password,
                returnSecureToken: true,
            }),
        });
    }
    catch (error) {
        console.error("Firebase login request failed", error);
        sendJson(response, 503, { error: "authentication-unavailable" });
        return;
    }
    if (!firebaseResponse.ok) {
        const errorBody = (await firebaseResponse.json());
        const errorCode = errorBody.error?.message ?? "AUTHENTICATION_FAILED";
        if (isCredentialFailure(errorCode)) {
            const lockout = await firestore.runTransaction(async (transaction) => {
                const snapshot = await transaction.get(lockoutRef);
                const current = snapshot.data() ?? {};
                const failedAttempts = (current.failedAttempts ?? 0) + 1;
                const lockedUntil = failedAttempts >= maxFailedAttempts
                    ? Date.now() + lockoutDurationMs
                    : undefined;
                transaction.set(lockoutRef, {
                    failedAttempts,
                    ...(lockedUntil ? { lockedUntil } : {}),
                    updatedAt: firestore_1.FieldValue.serverTimestamp(),
                }, { merge: true });
                return { failedAttempts, lockedUntil };
            });
            if (lockout.lockedUntil) {
                sendJson(response, 423, {
                    error: "account-locked",
                    retryAfterSeconds: Math.ceil((lockout.lockedUntil - Date.now()) / 1000),
                });
                return;
            }
        }
        sendJson(response, 401, { error: "invalid-credentials" });
        return;
    }
    const login = (await firebaseResponse.json());
    const customToken = await (0, auth_1.getAuth)().createCustomToken(login.localId);
    await lockoutRef.delete();
    sendJson(response, 200, { customToken });
});
