import { HttpsError, onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

admin.initializeApp();

const auth = admin.auth();
const db = admin.firestore();
const serverTimestamp = admin.firestore.FieldValue.serverTimestamp;
const supportedManagedRoles = new Set(["STUDENT", "TEACHER"]);

type ManagedRole = "STUDENT" | "TEACHER";

type CallerProfile = {
  role?: string;
  isActive?: boolean;
};

function asNonEmptyString(value: unknown, fieldName: string): string {
  if (typeof value != "string" || value.trim().length === 0) {
    throw new HttpsError(
      "invalid-argument",
      `${fieldName} is required.`,
    );
  }
  return value.trim();
}

function asOptionalInt(value: unknown): number | null {
  if (value === null || value === undefined || value === "") {
    return null;
  }

  if (typeof value === "number" && Number.isInteger(value)) {
    return value;
  }

  if (typeof value === "string") {
    const parsed = Number.parseInt(value, 10);
    if (!Number.isNaN(parsed)) {
      return parsed;
    }
  }

  throw new HttpsError("invalid-argument", "classGroupId must be an integer.");
}

function normalizeManagedRole(value: unknown): ManagedRole {
  const normalized = asNonEmptyString(value, "role").toUpperCase();
  if (!supportedManagedRoles.has(normalized)) {
    throw new HttpsError(
      "invalid-argument",
      "role must be STUDENT or TEACHER.",
    );
  }

  return normalized as ManagedRole;
}

async function assertAdminCaller(authUid: string | undefined): Promise<void> {
  if (!authUid) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }

  const profileSnapshot = await db.collection("users").doc(authUid).get();
  if (!profileSnapshot.exists) {
    throw new HttpsError(
      "permission-denied",
      "Admin profile not found.",
    );
  }

  const profile = profileSnapshot.data() as CallerProfile;
  if (profile.role !== "ADMIN" || profile.isActive !== true) {
    throw new HttpsError(
      "permission-denied",
      "Only active administrators can manage accounts.",
    );
  }
}

async function nextSequence(fieldName: string): Promise<number> {
  const counterRef = db.collection("metadata").doc("counters");
  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(counterRef);
    const currentValue = Number(snapshot.get(fieldName) ?? 0);
    const nextValue = currentValue + 1;
    transaction.set(
      counterRef,
      {
        [fieldName]: nextValue,
        updatedAt: serverTimestamp(),
      },
      { merge: true },
    );
    return nextValue;
  });
}

async function resolveClassGroup(classGroupId: number | null) {
  if (classGroupId === null) {
    return null;
  }

  const snapshot = await db
    .collection("class_groups")
    .where("id", "==", classGroupId)
    .limit(1)
    .get();

  if (snapshot.empty) {
    throw new HttpsError(
      "not-found",
      `Class group ${classGroupId} was not found.`,
    );
  }

  const group = snapshot.docs[0].data();
  return {
    id: classGroupId,
    name: String(group.name ?? "").trim(),
  };
}

async function ensureEmailAvailable(email: string): Promise<void> {
  try {
    await auth.getUserByEmail(email);
    throw new HttpsError(
      "already-exists",
      "A Firebase account with this email already exists.",
    );
  } catch (error) {
    if (
      error instanceof HttpsError ||
      !(error instanceof Error) ||
      !("code" in error) ||
      error.code !== "auth/user-not-found"
    ) {
      throw error;
    }
  }
}

export const createManagedUser = onCall(async (request) => {
  await assertAdminCaller(request.auth?.uid);

  const email = asNonEmptyString(request.data.email, "email").toLowerCase();
  const password = asNonEmptyString(request.data.password, "password");
  if (password.length < 6) {
    throw new HttpsError(
      "invalid-argument",
      "password must be at least 6 characters long.",
    );
  }

  const firstName = asNonEmptyString(request.data.firstName, "firstName");
  const lastName = asNonEmptyString(request.data.lastName, "lastName");
  const role = normalizeManagedRole(request.data.role);
  const classGroupId = asOptionalInt(request.data.classGroupId);
  const classGroup = await resolveClassGroup(classGroupId);

  await ensureEmailAvailable(email);

  const userRecord = await auth.createUser({
    email,
    password,
    displayName: `${firstName} ${lastName}`.trim(),
    disabled: false,
  });

  try {
    const numericId = await nextSequence("nextUserId");
    await auth.setCustomUserClaims(userRecord.uid, { role });

    await db.collection("users").doc(userRecord.uid).set({
      id: numericId,
      uid: userRecord.uid,
      email,
      firstName,
      lastName,
      role,
      isActive: true,
      classGroupId: classGroup?.id ?? null,
      classGroupName: classGroup?.name ?? null,
      subjectIds: [],
      subjects: [],
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });

    return {
      uid: userRecord.uid,
      id: numericId,
      role,
    };
  } catch (error) {
    await auth.deleteUser(userRecord.uid);
    throw error;
  }
});

export const updateManagedUser = onCall(async (request) => {
  await assertAdminCaller(request.auth?.uid);

  const uid = asNonEmptyString(request.data.uid, "uid");
  const email = asNonEmptyString(request.data.email, "email").toLowerCase();
  const firstName = asNonEmptyString(request.data.firstName, "firstName");
  const lastName = asNonEmptyString(request.data.lastName, "lastName");
  const role = normalizeManagedRole(request.data.role);
  const isActive = request.data.isActive === true;
  const classGroupId = asOptionalInt(request.data.classGroupId);
  const classGroup = await resolveClassGroup(classGroupId);

  const profileRef = db.collection("users").doc(uid);
  const profileSnapshot = await profileRef.get();
  if (!profileSnapshot.exists) {
    throw new HttpsError("not-found", "User profile not found.");
  }

  const existingProfile = profileSnapshot.data() as CallerProfile;
  if (existingProfile.role === "ADMIN") {
    throw new HttpsError(
      "permission-denied",
      "Admin accounts must be managed outside this callable.",
    );
  }

  await auth.updateUser(uid, {
    email,
    displayName: `${firstName} ${lastName}`.trim(),
    disabled: !isActive,
  });
  await auth.setCustomUserClaims(uid, { role });

  await profileRef.update({
    email,
    firstName,
    lastName,
    role,
    isActive,
    classGroupId: classGroup?.id ?? null,
    classGroupName: classGroup?.name ?? null,
    updatedAt: serverTimestamp(),
  });

  return { uid, role, isActive };
});

export const deleteManagedUser = onCall(async (request) => {
  await assertAdminCaller(request.auth?.uid);

  const uid = asNonEmptyString(request.data.uid, "uid");
  const profileRef = db.collection("users").doc(uid);
  const profileSnapshot = await profileRef.get();
  if (!profileSnapshot.exists) {
    throw new HttpsError("not-found", "User profile not found.");
  }

  const existingProfile = profileSnapshot.data() as CallerProfile;
  if (existingProfile.role === "ADMIN") {
    throw new HttpsError(
      "permission-denied",
      "Admin accounts cannot be deleted from this callable.",
    );
  }

  try {
    await auth.deleteUser(uid);
  } catch (error) {
    if (
      !(error instanceof Error) ||
      !("code" in error) ||
      error.code !== "auth/user-not-found"
    ) {
      throw error;
    }
  }

  await profileRef.delete();
  return { uid };
});
