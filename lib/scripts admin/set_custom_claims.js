const admin = require('firebase-admin');

// Inicializa Firebase Admin usando el archivo de clave de servicio.
// Asegúrate de que el archivo "serviceAccountKey.json" esté en el mismo directorio que este script.
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

/**
 * Asigna un rol personalizado a un usuario de Firebase.
 *
 * @param {string} email - Correo electrónico del usuario.
 * @param {string} role - Rol a asignar (por ejemplo, 'admin', 'seller', etc.).
 */
async function setUserRole(email, role) {
  try {
    // Obtiene el registro del usuario por correo electrónico.
    const userRecord = await admin.auth().getUserByEmail(email);
    // Asigna los custom claims con el rol especificado.
    await admin.auth().setCustomUserClaims(userRecord.uid, { role });
    console.log(`Se asignó el rol "${role}" al usuario ${email}`);
    console.log(`Recuerda que el usuario debe reiniciar sesión para actualizar su token y que se reflejen los nuevos claims.`);
  } catch (error) {
    console.error(`Error asignando rol a ${email}:`, error);
  }
}

/**
 * Función principal para asignar roles de ejemplo.
 */
async function main() {
  // Ejemplo: Asignar rol 'admin' al usuario yemsy26@gmail.com
  await setUserRole("yemsy26@gmail.com", "admin");
  // Ejemplo: Asignar rol 'seller' al usuario todologofenix056@gmail.com
  await setUserRole("todologofenix056@gmail.com", "seller");
   await setUserRole("luismiguel@gmail.com", "seller");
}

main().then(() => process.exit());
