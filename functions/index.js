const { onValueCreated } = require("firebase-functions/v2/database");
const admin = require("firebase-admin");

admin.initializeApp();

// ✅ 1️⃣ CRITICAL WATER ALERTS (All Users)
// Sends to ALL users when water level is critical
// (VERY LOW, LOW, HIGH, VERY HIGH)
exports.waterLevelNotification = onValueCreated(
  "/devices/{deviceId}/logs/{logId}",
  async (event) => {
    const data = event.data.val();
    if (!data) return;

    const deviceId = event.params.deviceId;
    const levelDescription = (data.levelDescription || "").trim().toLowerCase();

    // 🏷️ Get device name
    const deviceSnap = await admin.database().ref(`devices/${deviceId}`).get();
    let deviceName = "Water Monitoring Device";
    if (deviceSnap.exists()) {
      const deviceData = deviceSnap.val();
      deviceName = deviceData.name || deviceData.deviceName || "Water Monitoring Device";
    }

    // ✅ Check if level is CRITICAL (only 4 levels trigger this)
    let body = "";
    
    if (levelDescription.includes("very low")) {
      body = "Water level is critically low.\nImmediate watering is recommended to protect your plants.";
    } else if (levelDescription.includes("low") && !levelDescription.includes("medium")) {
      body = "Water level is low.\nPlease monitor the condition to ensure healthy plant growth.";
    } else if (levelDescription.includes("very high")) {
      body = "Water level is critically high.\nExcess water may harm plant roots. Please take action.";
    } else if (levelDescription.includes("high") && !levelDescription.includes("medium")) {
      body = "Water level is high.\nEnsure proper drainage to avoid overwatering.";
    }

    // If not critical, exit
    if (!body) {
      console.log(`ℹ️ No critical alert needed. Level: ${levelDescription}`);
      return;
    }

    // 🔔 Get tokens for this device
    const tokensSnap = await admin.database().ref(`devices/${deviceId}/tokens`).get();
    if (!tokensSnap.exists()) {
      console.log("❌ No tokens found for device:", deviceId);
      return;
    }

    const tokensObj = tokensSnap.val();
    const tokens = Object.values(tokensObj);

    if (tokens.length === 0) {
      console.log("❌ Token list is empty");
      return;
    }

    // 📤 Send notification to ALL users
    const payload = {
      notification: {
        title: deviceName,
        body: body,
      },
      android: {
        notification: {
          channelId: "water_alerts",
          priority: "high",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
          },
        },
      },
    };

    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      ...payload,
    });

    console.log(
      `✅ Critical alert sent to ALL users | ` +
      `Device: ${deviceName} | Level: ${levelDescription} | ` +
      `Success: ${response.successCount} | Failed: ${response.failureCount}`
    );

    // 🧹 Remove invalid tokens
    const results = response.results;
    const uids = Object.keys(tokensObj);

    for (let i = 0; i < results.length; i++) {
      if (results[i].error) {
        const code = results[i].error.code;
        if (
          code === "messaging/registration-token-not-registered" ||
          code === "messaging/invalid-registration-token"
        ) {
          console.log(`🗑️ Removing invalid token for uid: ${uids[i]}`);
          await admin.database().ref(`devices/${deviceId}/tokens/${uids[i]}`).remove();
        }
      }
    }
  }
);

// ✅ 2️⃣ SCHEDULED TIME NOTIFICATIONS (Specific User Only)
// Sends ONLY to users who scheduled this time
// Works for ALL 7 levels (including critical ones)
// Users with scheduled time get THIS notification IN ADDITION to critical alert
exports.scheduledReadingNotification = onValueCreated(
  "/devices/{deviceId}/logs/{logId}",
  async (event) => {
    const data = event.data.val();
    if (!data) return;

    const deviceId = event.params.deviceId;
    const logTime = data.time;
    const waterLevel = data.waterLevel || 0;
    const levelDescription = data.levelDescription || "Unknown";

    if (!logTime) {
      console.log("⚠️ No time field in log");
      return;
    }

    // Extract HH:MM from log time
    const timeMatch = logTime.match(/(\d{2}):(\d{2})/);
    if (!timeMatch) {
      console.log("⚠️ Could not parse time from:", logTime);
      return;
    }

    const logTimeFormatted = `${timeMatch[1]}:${timeMatch[2]}`;

    // 🏷️ Get device name
    const deviceSnap = await admin.database().ref(`devices/${deviceId}`).get();
    let deviceName = "Water Monitoring Device";
    if (deviceSnap.exists()) {
      const deviceData = deviceSnap.val();
      deviceName = deviceData.name || deviceData.deviceName || "Water Monitoring Device";
    }

    // 🔍 Check if this time is scheduled
    const scheduleSnap = await admin
      .database()
      .ref(`devices/${deviceId}/schedules/senseTimes`)
      .get();

    if (!scheduleSnap.exists()) {
      console.log(`ℹ️ No schedules set for device: ${deviceId}`);
      return;
    }

    const scheduledTimes = scheduleSnap.val();
    let scheduledTimesList = [];

    if (Array.isArray(scheduledTimes)) {
      scheduledTimesList = scheduledTimes.filter((t) => t != null);
    } else if (typeof scheduledTimes === "object") {
      scheduledTimesList = Object.values(scheduledTimes).filter((t) => t != null);
    }

    const isScheduledTime = scheduledTimesList.includes(logTimeFormatted);

    if (!isScheduledTime) {
      console.log(`ℹ️ Time ${logTimeFormatted} not scheduled. Scheduled: ${scheduledTimesList.join(", ")}`);
      return;
    }

    console.log(`⏰ Scheduled reading at ${logTimeFormatted} | Level: ${levelDescription}`);

    // 🎨 Create notification message for ALL 7 levels
    let notificationBody = "";
    const levelUpper = levelDescription.toUpperCase();

    if (levelUpper.includes("VERY LOW")) {
      notificationBody = 
        `⏰ Your scheduled time: ${logTimeFormatted}\n` +
        `💧 Water Level: ${waterLevel}% - VERY LOW\n` +
        `⚠️ Critical! Plants need water urgently.`;
    }
    else if (levelUpper.includes("MEDIUM LOW")) {
      notificationBody = 
        `⏰ Your scheduled time: ${logTimeFormatted}\n` +
        `💧 Water Level: ${waterLevel}% - MEDIUM LOW\n` +
        `📊 Below optimal. Consider watering soon.`;
    }
    else if (levelUpper.includes("LOW")) {
      notificationBody = 
        `⏰ Your scheduled time: ${logTimeFormatted}\n` +
        `💧 Water Level: ${waterLevel}% - LOW\n` +
        `⚡ Water level is low. Please check plants.`;
    }
    else if (levelUpper.includes("VERY HIGH")) {
      notificationBody = 
        `⏰ Your scheduled time: ${logTimeFormatted}\n` +
        `💧 Water Level: ${waterLevel}% - VERY HIGH\n` +
        `🚨 Excessive water! Risk of root damage.`;
    }
    else if (levelUpper.includes("MEDIUM HIGH")) {
      notificationBody = 
        `⏰ Your scheduled time: ${logTimeFormatted}\n` +
        `💧 Water Level: ${waterLevel}% - MEDIUM HIGH\n` +
        `📈 Above optimal. Monitor for overwatering.`;
    }
    else if (levelUpper.includes("HIGH")) {
      notificationBody = 
        `⏰ Your scheduled time: ${logTimeFormatted}\n` +
        `💧 Water Level: ${waterLevel}% - HIGH\n` +
        `💦 Water level is high. Ensure proper drainage.`;
    }
    else if (levelUpper.includes("MEDIUM")) {
      notificationBody = 
        `⏰ Your scheduled time: ${logTimeFormatted}\n` +
        `💧 Water Level: ${waterLevel}% - MEDIUM\n` +
        `✅ Optimal level. Plants are healthy.`;
    }
    else {
      // Fallback
      notificationBody = 
        `⏰ Your scheduled time: ${logTimeFormatted}\n` +
        `💧 Water Level: ${waterLevel}% - ${levelDescription}\n` +
        `📊 Sensor reading received.`;
    }

    // 🔍 Find users who scheduled this time
    const usersSnap = await admin.database().ref("users").get();
    if (!usersSnap.exists()) {
      console.log("❌ No users found");
      return;
    }

    const notificationsToSend = [];

    for (const uid in usersSnap.val()) {
      const userTimesSnap = await admin
        .database()
        .ref(`users/${uid}/devices/${deviceId}/schedules/senseTimes`)
        .get();

      if (!userTimesSnap.exists()) continue;

      const userTimes = userTimesSnap.val();
      let userTimesList = [];

      if (Array.isArray(userTimes)) {
        userTimesList = userTimes.filter((t) => t != null);
      } else if (typeof userTimes === "object") {
        userTimesList = Object.values(userTimes).filter((t) => t != null);
      }

      if (userTimesList.includes(logTimeFormatted)) {
        const tokenSnap = await admin
          .database()
          .ref(`devices/${deviceId}/tokens/${uid}`)
          .get();

        if (tokenSnap.exists()) {
          notificationsToSend.push({
            uid,
            token: tokenSnap.val(),
          });
        }
      }
    }

    if (notificationsToSend.length === 0) {
      console.log(`ℹ️ No users to notify for time ${logTimeFormatted}`);
      return;
    }

    // 📤 Send scheduled notifications to matched users
    const tokens = notificationsToSend.map((n) => n.token);
    const payload = {
      notification: {
        title: `⏰ ${deviceName}`,
        body: notificationBody,
      },
      android: {
        notification: {
          channelId: "water_alerts",
          priority: "high",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
          },
        },
      },
    };

    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      ...payload,
    });

    console.log(
      `✅ Scheduled notifications sent to SPECIFIC users | ` +
      `Device: ${deviceName} | Time: ${logTimeFormatted} | ` +
      `Level: ${levelDescription} | ` +
      `Success: ${response.successCount} | Failed: ${response.failureCount} | ` +
      `Users: ${notificationsToSend.length}`
    );

    // 🧹 Remove invalid tokens
    const results = response.results;
    for (let i = 0; i < results.length; i++) {
      if (results[i].error) {
        const code = results[i].error.code;
        if (
          code === "messaging/registration-token-not-registered" ||
          code === "messaging/invalid-registration-token"
        ) {
          const uid = notificationsToSend[i].uid;
          console.log(`🗑️ Removing invalid token for uid: ${uid}`);
          await admin.database().ref(`devices/${deviceId}/tokens/${uid}`).remove();
        }
      }
    }
  }
);