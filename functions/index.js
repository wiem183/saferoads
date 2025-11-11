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