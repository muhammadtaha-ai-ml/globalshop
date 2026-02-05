const { onValueCreated } = require("firebase-functions/v2/database");
const admin = require("firebase-admin");

admin.initializeApp();

exports.waterLevelNotification = onValueCreated(
  "/devices/{deviceId}/logs/{logId}",
  async (event) => {
    const data = event.data.val();
    if (!data) return;

    const deviceId = event.params.deviceId;
    const levelDescription = (data.levelDescription || "")
      .trim()
      .toLowerCase();

    let title = "🌱 Device";
    let body = "";

    // 🏷️ Get device name (VERY IMPORTANT – shown on top)
    const deviceSnap = await admin
      .database()
      .ref(`devices/${deviceId}`)
      .get();

    let deviceName = "Water Monitoring Device";
    if (deviceSnap.exists()) {
      const deviceData = deviceSnap.val();
      deviceName =
        deviceData.name ||
        deviceData.deviceName ||
        "Water Monitoring Device";
    }

    // ✅ TITLE = DEVICE NAME (Professional iOS style)
    title = deviceName;

    // ✅ BODY = CLEAN + PROFESSIONAL MESSAGE
    if (levelDescription.includes("very low")) {
      body =
        "Water level is critically low.\nImmediate watering is recommended to protect your plants.";
    } else if (levelDescription.includes("low")) {
      body =
        "Water level is low.\nPlease monitor the condition to ensure healthy plant growth.";
    } else if (levelDescription.includes("very high")) {
      body =
        "Water level is critically high.\nExcess water may harm plant roots. Please take action.";
    } else if (levelDescription.includes("high")) {
      body =
        "Water level is high.\nEnsure proper drainage to avoid overwatering.";
    } else {
      console.log(
        "No notification needed. levelDescription:",
        levelDescription
      );
      return;
    }

    // 🔔 Get tokens for this device
    const tokensSnap = await admin
      .database()
      .ref(`devices/${deviceId}/tokens`)
      .get();

    if (!tokensSnap.exists()) {
      console.log("No tokens found for device:", deviceId);
      return;
    }

    const tokensObj = tokensSnap.val();

    // ⚠️ OLD STRUCTURE SUPPORT (fallback)
    if (typeof tokensObj === "string") {
      const payload = {
        notification: {
          title,
          body,
        },
      };

      await admin.messaging().sendEachForMulticast({
        tokens: [tokensObj],
        ...payload,
      });

      console.log(
        `⚠️ Notification sent using OLD token structure for device: ${deviceId}`
      );
      return;
    }

    // ✅ NEW STRUCTURE (multiple users per device)
    const tokens = Object.values(tokensObj);

    if (tokens.length === 0) {
      console.log("Token list empty for device:", deviceId);
      return;
    }

    const payload = {
      notification: {
        title: title,
        body: body,
      },
      android: {
        notification: {
          channelId: "water_alerts",
          priority: "HIGH",
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
      `✅ Notification sent | Device: ${deviceName} | ` +
        `Success: ${response.successCount} | ` +
        `Failed: ${response.failureCount} | ` +
        `Users: ${tokens.length} | ` +
        `Level: ${levelDescription}`
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
          await admin
            .database()
            .ref(`devices/${deviceId}/tokens/${uids[i]}`)
            .remove();
        }
      }
    }
  }
);
