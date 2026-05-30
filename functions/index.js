const { onValueCreated } = require("firebase-functions/v2/database");
const admin = require("firebase-admin");

admin.initializeApp();

// ─────────────────────────────────────────────────────────────
// 1️⃣  CRITICAL WATER ALERTS  (sent to ALL users of this device)
// Triggers on: VERY LOW, LOW, HIGH, VERY HIGH
// 💰 FREE — no minInstances, dedup via processedLogs
// ─────────────────────────────────────────────────────────────
exports.waterLevelNotification = onValueCreated(
  "/devices/{deviceId}/logs/{logId}",
  async (event) => {
    const data = event.data.val();
    if (!data) return null;

    const deviceId = event.params.deviceId;
    const logId    = event.params.logId;

    // ✅ DEDUP CHECK — ek hi log pe 2 baar notification na jaye
    const processedRef = admin.database()
      .ref(`processedLogs/${deviceId}/critical/${logId}`);
    const already = await processedRef.get();
    if (already.exists()) {
      console.log(`⏭️ [Critical] Already processed: ${logId}`);
      return null;
    }
    // Mark as processed immediately (TTL via separate cleanup if needed)
    await processedRef.set(true);

    const sensorType = (data.sensorType || "").toLowerCase();
    if (!sensorType.includes("water")) {
      console.log(`ℹ️ Skipping — sensorType: "${sensorType}"`);
      return null;
    }

    const levelDescription = (data.levelDescription || "").trim().toLowerCase();

    // ─── Get device name ───────────────────────────────────────
    const deviceSnap = await admin.database().ref(`devices/${deviceId}`).get();
    let deviceName = "Water Monitoring Device";
    if (deviceSnap.exists()) {
      const d = deviceSnap.val();
      deviceName = d.deviceName || d.name || "Water Monitoring Device";
    }

    // ─── Alert message ────────────────────────────────────────
    let body = "";
    if (levelDescription.includes("very low")) {
      body = "⚠️ Water level is VERY LOW.\nImmediate watering recommended to protect your plants.";
    } else if (levelDescription.includes("very high")) {
      body = "🚨 Water level is VERY HIGH.\nExcess water may harm plant roots. Please take action.";
    } else if (levelDescription.includes("medium low") || levelDescription.includes("medium high")) {
      console.log(`ℹ️ Level "${levelDescription}" — no critical alert.`);
      return null;
    } else if (levelDescription.includes("low")) {
      body = "💧 Water level is LOW.\nPlease monitor and consider watering soon.";
    } else if (levelDescription.includes("high")) {
      body = "💦 Water level is HIGH.\nEnsure proper drainage to avoid overwatering.";
    } else {
      console.log(`ℹ️ Level "${levelDescription}" — no critical alert.`);
      return null;
    }

    // ─── Get tokens ───────────────────────────────────────────
    const tokensSnap = await admin
      .database().ref(`devices/${deviceId}/tokens`).get();

    if (!tokensSnap.exists()) {
      console.log(`❌ No tokens for device: ${deviceId}`);
      return null;
    }

    const tokensObj = tokensSnap.val();
    const uids   = Object.keys(tokensObj);
    const tokens = Object.values(tokensObj).filter(Boolean);

    if (tokens.length === 0) { console.log("❌ Empty token list"); return null; }

    console.log(`📤 Sending to ${tokens.length} user(s) | Level: ${levelDescription}`);

    const payload = {
      tokens,
      notification: { title: `🌿 ${deviceName}`, body },
      android: {
        priority: "high",
        notification: { channelId: "water_alerts", priority: "max", sound: "default" },
      },
      apns: { payload: { aps: { sound: "default", badge: 1 } } },
    };

    const response = await admin.messaging().sendEachForMulticast(payload);
    console.log(`✅ Sent | Success: ${response.successCount} | Failed: ${response.failureCount}`);

    await _cleanInvalidTokens(response.responses, uids, deviceId);
    return null;
  }
);

// ─────────────────────────────────────────────────────────────
// 2️⃣  SCHEDULED TIME NOTIFICATIONS  (sent to specific users)
// 💰 FREE — no minInstances, dedup via processedLogs
// ─────────────────────────────────────────────────────────────
exports.scheduledReadingNotification = onValueCreated(
  "/devices/{deviceId}/logs/{logId}",
  async (event) => {
    const data = event.data.val();
    if (!data) return null;

    const deviceId = event.params.deviceId;
    const logId    = event.params.logId;

    // ✅ DEDUP CHECK
    const processedRef = admin.database()
      .ref(`processedLogs/${deviceId}/scheduled/${logId}`);
    const already = await processedRef.get();
    if (already.exists()) {
      console.log(`⏭️ [Scheduled] Already processed: ${logId}`);
      return null;
    }
    await processedRef.set(true);

    const sensorType = (data.sensorType || "").toLowerCase();
    if (!sensorType.includes("water")) {
      console.log(`ℹ️ Scheduled: Skipping — sensorType: "${sensorType}"`);
      return null;
    }

    const logTime        = data.time;
    const waterLevel     = data.waterLevel || 0;
    const levelDescription = data.levelDescription || "Unknown";

    if (!logTime) { console.log("⚠️ No time field"); return null; }

    const logTimeFormatted = _parseTime(logTime);
    if (!logTimeFormatted) { console.log(`⚠️ Cannot parse time: ${logTime}`); return null; }

    // ─── Device name ──────────────────────────────────────────
    const deviceSnap = await admin.database().ref(`devices/${deviceId}`).get();
    let deviceName = "Water Monitoring Device";
    if (deviceSnap.exists()) {
      const d = deviceSnap.val();
      deviceName = d.deviceName || d.name || "Water Monitoring Device";
    }

    // ─── Global schedule check ────────────────────────────────
    const scheduleSnap = await admin
      .database().ref(`devices/${deviceId}/schedules/senseTimes`).get();
    if (!scheduleSnap.exists()) {
      console.log(`ℹ️ No schedules for device: ${deviceId}`);
      return null;
    }

    const scheduledTimes  = _toArray(scheduleSnap.val());
    if (!scheduledTimes.includes(logTimeFormatted)) {
      console.log(`ℹ️ Time ${logTimeFormatted} not in schedule`);
      return null;
    }

    console.log(`⏰ Matched scheduled time: ${logTimeFormatted}`);
    const notificationBody = _buildScheduledBody(logTimeFormatted, waterLevel, levelDescription);

    // ─── Per-user check ───────────────────────────────────────
    const usersSnap = await admin.database().ref("users").get();
    if (!usersSnap.exists()) { console.log("❌ No users"); return null; }

    const notificationsToSend = [];
    for (const uid in usersSnap.val()) {
      const userTimesSnap = await admin
        .database()
        .ref(`users/${uid}/devices/${deviceId}/schedules/senseTimes`)
        .get();
      if (!userTimesSnap.exists()) continue;

      const userTimes = _toArray(userTimesSnap.val());
      if (!userTimes.includes(logTimeFormatted)) continue;

      const tokenSnap = await admin
        .database().ref(`devices/${deviceId}/tokens/${uid}`).get();
      if (tokenSnap.exists() && tokenSnap.val()) {
        notificationsToSend.push({ uid, token: tokenSnap.val() });
      }
    }

    if (notificationsToSend.length === 0) {
      console.log(`ℹ️ No users for time ${logTimeFormatted}`);
      return null;
    }

    const tokens = notificationsToSend.map((n) => n.token);
    const payload = {
      tokens,
      notification: { title: `⏰ ${deviceName}`, body: notificationBody },
      android: {
        priority: "high",
        notification: { channelId: "water_alerts", priority: "max", sound: "default" },
      },
      apns: { payload: { aps: { sound: "default", badge: 1 } } },
    };

    const response = await admin.messaging().sendEachForMulticast(payload);
    console.log(`✅ Scheduled sent | Success: ${response.successCount} | Failed: ${response.failureCount}`);

    const uids = notificationsToSend.map((n) => n.uid);
    await _cleanInvalidTokens(response.responses, uids, deviceId);
    return null;
  }
);

// ─────────────────────────────────────────────────────────────
// 3️⃣  CLEANUP — Delete processedLogs older than 10 minutes
//     Runs every hour — keeps DB clean, stays in free tier
// ─────────────────────────────────────────────────────────────
exports.cleanupProcessedLogs = require("firebase-functions/v2/scheduler")
  .onSchedule("every 60 minutes", async () => {
    const cutoff = Date.now() - 10 * 60 * 1000; // 10 minutes ago
    const snap = await admin.database().ref("processedLogs").get();
    if (!snap.exists()) return;

    const updates = {};
    snap.forEach((deviceSnap) => {
      ["critical", "scheduled"].forEach((type) => {
        const typeSnap = deviceSnap.child(type);
        typeSnap.forEach((logSnap) => {
          // logId from Firebase push key contains timestamp
          const pushTimestamp = _pushKeyToTimestamp(logSnap.key);
          if (pushTimestamp && pushTimestamp < cutoff) {
            updates[`processedLogs/${deviceSnap.key}/${type}/${logSnap.key}`] = null;
          }
        });
      });
    });

    if (Object.keys(updates).length > 0) {
      await admin.database().ref().update(updates);
      console.log(`🗑️ Cleaned ${Object.keys(updates).length} old processedLogs entries`);
    }
  });

// ─────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────

function _pushKeyToTimestamp(pushKey) {
  // Firebase push keys encode timestamp in first 8 chars
  const PUSH_CHARS = "-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz";
  if (!pushKey || pushKey.length < 8) return null;
  let timestamp = 0;
  for (let i = 0; i < 8; i++) {
    timestamp = timestamp * 64 + PUSH_CHARS.indexOf(pushKey[i]);
  }
  return timestamp;
}

function _parseTime(timeStr) {
  if (!timeStr) return null;
  const str = timeStr.toString().trim();

  const match24 = str.match(/^(\d{1,2}):(\d{2})/);
  if (match24) return `${match24[1].padStart(2, "0")}:${match24[2]}`;

  const match12 = str.match(/(\d{1,2}):(\d{2})\s*(AM|PM)/i);
  if (match12) {
    let h = parseInt(match12[1]);
    const m = match12[2];
    const period = match12[3].toUpperCase();
    if (period === "PM" && h !== 12) h += 12;
    if (period === "AM" && h === 12) h = 0;
    return `${h.toString().padStart(2, "0")}:${m}`;
  }
  return null;
}

function _toArray(val) {
  if (!val) return [];
  if (Array.isArray(val)) return val.filter((t) => t != null);
  if (typeof val === "object") return Object.values(val).filter((t) => t != null);
  return [];
}

function _buildScheduledBody(time, level, description) {
  const desc = description.toUpperCase();
  let emoji = "💧", status = description;

  if (desc.includes("VERY LOW"))        { emoji = "🔴"; status = "VERY LOW — Plants need water urgently!"; }
  else if (desc.includes("MEDIUM LOW")) { emoji = "🟠"; status = "MEDIUM LOW — Below optimal, consider watering."; }
  else if (desc.includes("LOW"))        { emoji = "🟠"; status = "LOW — Water level is low."; }
  else if (desc.includes("VERY HIGH"))  { emoji = "🔴"; status = "VERY HIGH — Risk of root damage!"; }
  else if (desc.includes("MEDIUM HIGH")){ emoji = "🟡"; status = "MEDIUM HIGH — Monitor for overwatering."; }
  else if (desc.includes("HIGH"))       { emoji = "🟡"; status = "HIGH — Ensure proper drainage."; }
  else if (desc.includes("MEDIUM"))     { emoji = "🟢"; status = "MEDIUM — Optimal level. Plants are healthy!"; }

  return `⏰ Scheduled reading at ${time}\n${emoji} Water Level: ${level}% — ${status}`;
}

async function _cleanInvalidTokens(responses, uids, deviceId) {
  for (let i = 0; i < responses.length; i++) {
    if (responses[i].error) {
      const code = responses[i].error.code;
      if (
        code === "messaging/registration-token-not-registered" ||
        code === "messaging/invalid-registration-token" ||
        code === "messaging/invalid-argument"
      ) {
        const uid = uids[i];
        if (uid) {
          await admin.database()
            .ref(`devices/${deviceId}/tokens/${uid}`).remove();
          console.log(`🗑️ Removed invalid token: ${uid}`);
        }
      }
    }
  }
}