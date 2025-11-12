const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { getFirestore } = require("firebase-admin/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

exports.notifyParking = onDocumentUpdated("parkings/{parkingId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();

  if (!before || !after) return;
  if (before.available_spots === after.available_spots) return;

  // Déclenchement quand 0 -> >0
  if (before.available_spots === 0 && after.available_spots > 0) {
    const parkingId = event.params.parkingId;
    console.log(`🚗 Place libérée détectée pour parking=${parkingId}`);

    const db = getFirestore();
    const tokensSnap = await db.collection("fcm_tokens").get();
    const tokens = tokensSnap.docs.map((d) => d.data().token).filter(Boolean);

    console.log(`📩 Envoi de notification à ${tokens.length} utilisateurs...`);

    if (tokens.length === 0) {
      console.log("⚠️ Aucun token FCM trouvé.");
      return;
    }

    const message = {
      notification: {
        title: "Place disponible 🚗",
        body: "Une nouvelle place vient de se libérer dans votre parking préféré !",
      },
      tokens,
    };

    try {
      const response = await getMessaging().sendEachForMulticast(message);
      console.log(`✅ Notifications envoyées : ${response.successCount} succès / ${response.failureCount} échecs`);
    } catch (error) {
      console.error("❌ Erreur d’envoi :", error);
    }
  }
});
