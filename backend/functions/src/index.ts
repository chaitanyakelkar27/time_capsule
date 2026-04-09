/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import { setGlobalOptions } from "firebase-functions";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

// Initialize Firebase Admin
admin.initializeApp();

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

/**
 * Check and unlock matured capsules (runs every hour)
 */
export const checkMaturedCapsules = onSchedule(
  { schedule: "every 1 hours", timeZone: "America/New_York" },
  async () => {
    logger.info("⏰ Checking matured capsules...");

    try {
      const now = admin.firestore.Timestamp.now();
      const db = admin.firestore();

      // Query locked capsules where unlock time has passed
      const snapshot = await db
        .collection("capsules")
        .where("isLocked", "==", true)
        .where("unlockType", "in", ["time", "both"])
        .where("unlockDate", "<=", now)
        .get();

      logger.info(`📊 Found ${snapshot.size} capsules to unlock`);

      if (snapshot.empty) {
        logger.info("✅ No capsules to unlock");
        return;
      }

      // Unlock each capsule
      const batch = db.batch();
      const notifications: Promise<void>[] = [];

      snapshot.docs.forEach((doc) => {
        const capsuleData = doc.data();

        // Update capsule status
        batch.update(doc.ref, {
          isLocked: false,
          status: "unlocked",
          unlockedAt: now,
          updatedAt: now,
        });

        // Prepare notification for recipient
        notifications.push(
          sendUnlockNotification(
            capsuleData.recipientId,
            capsuleData.title,
            capsuleData.senderName,
            doc.id
          )
        );
      });

      // Commit batch update
      await batch.commit();
      logger.info(`✅ Unlocked ${snapshot.size} capsules`);

      // Send notifications
      await Promise.all(notifications);
      logger.info(`📱 Sent ${notifications.length} notifications`);
    } catch (error) {
      logger.error("❌ Error checking matured capsules:", error);
    }
  }
);

/**
 * Send unlock notification to user
 * @param {string} userId - The ID of the user to notify
 * @param {string} capsuleTitle - The title of the capsule
 * @param {string} senderName - Name of the capsule sender
 * @param {string} capsuleId - The ID of the capsule
 * @return {Promise<void>}
 */
async function sendUnlockNotification(
  userId: string,
  capsuleTitle: string,
  senderName: string,
  capsuleId: string
): Promise<void> {
  try {
    const db = admin.firestore();
    const userDoc = await db.collection("users").doc(userId).get();

    if (!userDoc.exists) {
      logger.warn(`User ${userId} not found`);
      return;
    }

    const fcmToken = userDoc.data()?.fcmToken;

    if (!fcmToken) {
      logger.warn(`No FCM token for user ${userId}`);
      return;
    }

    // Send notification
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: "🎉 Capsule Unlocked!",
        body: `"${capsuleTitle}" from ${senderName} is ready to view!`,
      },
      data: {
        capsuleId: capsuleId,
        type: "unlock",
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "capsule_unlock",
          priority: "high",
          defaultSound: true,
          defaultVibrateTimings: true,
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    });

    logger.info(`📱 Notification sent to user ${userId}`);
  } catch (error) {
    logger.error(`❌ Error sending notification to ${userId}:`, error);
  }
}

/**
 * Trigger notification when capsule is unlocked
 */
export const onCapsuleUnlocked = onDocumentUpdated(
  "capsules/{capsuleId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    if (!before || !after) return;

    // Check if capsule was just unlocked
    if (before.isLocked && !after.isLocked) {
      logger.info(`🔓 Capsule ${event.params.capsuleId} was unlocked`);

      await sendUnlockNotification(
        after.recipientId,
        after.title,
        after.senderName,
        event.params.capsuleId
      );
    }
  }
);

/**
 * Add a contact by email for the current authenticated user.
 */
export const addContactByEmail = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }

  const emailValue = request.data?.email;
  if (typeof emailValue !== "string") {
    throw new HttpsError("invalid-argument", "Email is required.");
  }

  const email = emailValue.trim().toLowerCase();
  if (!email || !email.includes("@")) {
    throw new HttpsError("invalid-argument", "Invalid email format.");
  }

  const ownerId = request.auth.uid;
  const ownerEmail = request.auth.token.email;
  if (typeof ownerEmail === "string" && ownerEmail.toLowerCase() === email) {
    throw new HttpsError(
      "failed-precondition",
      "You cannot add yourself as a contact."
    );
  }

  let targetUser: admin.auth.UserRecord;
  try {
    targetUser = await admin.auth().getUserByEmail(email);
  } catch (error) {
    logger.warn("addContactByEmail target lookup failed", { ownerId, email });
    throw new HttpsError("not-found", "No user found for that email.");
  }

  if (targetUser.uid === ownerId) {
    throw new HttpsError(
      "failed-precondition",
      "You cannot add yourself as a contact."
    );
  }

  const db = admin.firestore();
  const targetRef = db.collection("users").doc(targetUser.uid);
  const targetSnap = await targetRef.get();

  let displayName = targetUser.displayName?.trim() || "";
  let contactEmail = (targetUser.email ?? email).toLowerCase();

  if (targetSnap.exists) {
    const targetData = targetSnap.data();
    if (typeof targetData?.displayName === "string" &&
      targetData.displayName.trim()) {
      displayName = targetData.displayName.trim();
    }
    if (typeof targetData?.email === "string" && targetData.email.trim()) {
      contactEmail = targetData.email.trim().toLowerCase();
    }
  } else {
    if (!displayName) {
      displayName = contactEmail.split("@")[0] || "User";
    }

    await targetRef.set({
      userId: targetUser.uid,
      email: contactEmail,
      displayName,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  }

  if (!displayName) {
    displayName = contactEmail.split("@")[0] || "User";
  }

  await db
    .collection("users")
    .doc(ownerId)
    .collection("contacts")
    .doc(targetUser.uid)
    .set({
      userId: targetUser.uid,
      displayName,
      email: contactEmail,
      addedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

  logger.info("Contact added", { ownerId, contactUserId: targetUser.uid });

  return {
    userId: targetUser.uid,
    displayName,
    email: contactEmail,
  };
});

/**
 * Check location-based unlock
 */
export const checkLocationUnlock = onCall(async (request) => {
  const { capsuleId, userLatitude, userLongitude } = request.data;

  if (!capsuleId || userLatitude === undefined ||
    userLongitude === undefined) {
    throw new Error("Missing required parameters");
  }

  try {
    const db = admin.firestore();
    const capsuleDoc = await db.collection("capsules").doc(capsuleId).get();

    if (!capsuleDoc.exists) {
      throw new Error("Capsule not found");
    }

    const capsule = capsuleDoc.data();

    if (!capsule) {
      throw new Error("Capsule data is empty");
    }

    // Check if capsule is location-locked
    if (!capsule.isLocationLocked || capsule.unlockType === "time") {
      throw new Error("Capsule is not location-locked");
    }

    // Check if already unlocked
    if (!capsule.isLocked) {
      return { unlocked: true, distance: 0, alreadyUnlocked: true };
    }

    // Calculate distance using Haversine formula
    const distance = calculateDistance(
      userLatitude,
      userLongitude,
      capsule.unlockLocation.latitude,
      capsule.unlockLocation.longitude
    );

    logger.info(`📍 Distance to unlock location: ${distance}m`);

    // Check if within unlock radius
    const unlockRadius = capsule.unlockRadius || 100; // default 100m

    if (distance <= unlockRadius) {
      // Unlock the capsule
      await capsuleDoc.ref.update({
        isLocked: false,
        status: "unlocked",
        unlockedAt: admin.firestore.Timestamp.now(),
        updatedAt: admin.firestore.Timestamp.now(),
      });

      logger.info(`✅ Capsule ${capsuleId} unlocked by location`);

      return { unlocked: true, distance, alreadyUnlocked: false };
    }

    return { unlocked: false, distance, required: unlockRadius };
  } catch (error) {
    logger.error("❌ Error checking location unlock:", error);
    throw error;
  }
});

/**
 * Calculate distance between two coordinates using Haversine formula
 * @param {number} lat1 - Latitude of first point
 * @param {number} lon1 - Longitude of first point
 * @param {number} lat2 - Latitude of second point
 * @param {number} lon2 - Longitude of second point
 * @return {number} Distance in meters
 */
function calculateDistance(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371000; // Earth's radius in meters
  const φ1 = (lat1 * Math.PI) / 180;
  const φ2 = (lat2 * Math.PI) / 180;
  const Δφ = ((lat2 - lat1) * Math.PI) / 180;
  const Δλ = ((lon2 - lon1) * Math.PI) / 180;

  const a =
    Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
    Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) * Math.sin(Δλ / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c; // Distance in meters
}

// export const helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
