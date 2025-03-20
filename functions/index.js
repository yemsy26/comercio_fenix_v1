const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.reduceProductStock = functions.https.onRequest(async (req, res) => {
  // Solo permitir solicitudes POST.
  if (req.method !== "POST") {
    return res.status(405).send("Method Not Allowed");
  }

  // Verificar el encabezado de autorización
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(403).send("Unauthorized: No token provided");
  }

  const idToken = authHeader.split("Bearer ")[1];

  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const role = decodedToken.role;
    // Permitir solo si el rol es admin o seller
    if (role !== "admin" && role !== "seller") {
      return res.status(403).send("Insufficient permissions");
    }
  } catch (error) {
    console.error("Error verifying token:", error);
    return res.status(403).send("Unauthorized: " + error.message);
  }

  // Extrae los datos de la solicitud.
  const { productId, quantity } = req.body;
  if (!productId || typeof quantity !== "number") {
    return res.status(400).send("Bad Request: Missing productId or quantity");
  }

  try {
    // Accede a Firestore para actualizar el stock.
    const productRef = admin.firestore().collection("products").doc(productId);
    await admin.firestore().runTransaction(async (transaction) => {
      const productDoc = await transaction.get(productRef);
      if (!productDoc.exists) {
        throw new Error("Producto no encontrado");
      }
      const currentStock = productDoc.data().stock;
      if (currentStock < quantity) {
        throw new Error("Stock insuficiente");
      }
      transaction.update(productRef, { stock: currentStock - quantity });
    });
    return res.status(200).send(`Stock actualizado correctamente para el producto ${productId}`);
  } catch (error) {
    console.error("Error updating stock:", error);
    return res.status(500).send("Error al actualizar el stock: " + error.message);
  }
});
