<<<<<<< HEAD
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

const transporter = nodemailer.createTransporter({
  service: "gmail",
  auth: {
    user: "errouissi.wiem18@gmail.com",
    pass: "eoku svhn awsd ckcq",
  },
});

exports.sendMailOnReservation = functions.firestore
  .document("mailQueue/{docId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const docId = context.params.docId;

    const mailOptions = {
      from: "errouissi.wiem18@gmail.com",
      to: data.to,
      subject: data.subject,
      text: data.message,
    };

    try {
      await transporter.sendMail(mailOptions);
      console.log("✅ Mail envoyé à :", data.to);
      
      // ⚠️ IMPORTANT: Supprimer le document après envoi
      await admin.firestore().collection("mailQueue").doc(docId).delete();
      console.log("📁 Document mailQueue supprimé :", docId);
      
    } catch (error) {
      console.error("❌ Erreur lors de l'envoi :", error);
      
      // Optionnel: marquer comme échec pour retry plus tard
      await admin.firestore().collection("mailQueue").doc(docId).update({
        error: error.message,
        attempts: admin.firestore.FieldValue.increment(1)
      });
    }
  });
=======
import admin from "firebase-admin";
import fs from "fs";

// --- Initialisation Firebase ---
const serviceAccount = JSON.parse(fs.readFileSync("./serviceAccountKey.json", "utf8"));

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

// --- Fonction de surveillance Firestore ---
function startParkingWatcher() {
  const cache = new Map();
  console.log("👂 Watcher 'parkings' démarré.");

  db.collection("parkings").onSnapshot(
    (snapshot) => {
      snapshot.docChanges().forEach(async (change) => {
        const doc = change.doc;
        const data = doc.data() || {};
        const prevAvail = cache.get(doc.id)?.available_spots;
        const currAvail = data.available_spots ?? 0;

        cache.set(doc.id, { available_spots: currAvail });

        if (prevAvail === 0 && currAvail > 0) {
          console.log(`🚗 Place libérée détectée pour parking=${doc.id}`);

          const tokensSnap = await db.collection("fcm_tokens").get();
          const tokens = tokensSnap.docs.map((d) => d.data().token).filter(Boolean);

          if (tokens.length === 0) {
            console.log("⚠️ Aucun token FCM trouvé.");
            return;
          }

          const message = {
            notification: {
              title: "🚗 Place disponible !",
              body: `Une place vient de se libérer dans ${data.name || "le parking"}.`,
            },
            tokens,
          };

          try {
            const resp = await admin.messaging().sendEachForMulticast(message);
            console.log(`✅ Notifications envoyées : ${resp.successCount} succès / ${resp.failureCount} échecs`);
          } catch (err) {
            console.error("❌ Erreur d’envoi :", err);
          }
        }
      });
    },
    (err) => console.error("🔥 Erreur Firestore :", err)
  );
}

// --- Lancer le watcher au démarrage ---
startParkingWatcher();
>>>>>>> origin/Amendes
