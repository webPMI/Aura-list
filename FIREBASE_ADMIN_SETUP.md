# Firebase Admin Setup Guide

Este documento explica cómo configurar el sistema de administración y la sección pública de Firebase para AuraList.

## 📋 Contenido

1. [Desplegar Reglas de Seguridad](#desplegar-reglas-de-seguridad)
2. [Crear el Primer Usuario Admin](#crear-el-primer-usuario-admin)
3. [Estructura de la Base de Datos Pública](#estructura-de-la-base-de-datos-pública)
4. [Migrar Datos a Firestore](#migrar-datos-a-firestore)

---

## 🔒 Desplegar Reglas de Seguridad

Las reglas de Firestore han sido actualizadas para soportar:
- Colecciones públicas de solo lectura (guides, wellness)
- Sistema de roles admin
- Colecciones de finanzas por usuario

### Paso 1: Desplegar las reglas

```bash
# Asegúrate de tener Firebase CLI instalado
npm install -g firebase-tools

# Autenticarse (si no lo has hecho)
firebase login

# Desplegar solo las reglas de Firestore
firebase deploy --only firestore:rules
```

### Paso 2: Verificar el despliegue

1. Ve a [Firebase Console](https://console.firebase.google.com)
2. Selecciona tu proyecto
3. Ve a **Firestore Database** → **Rules**
4. Verifica que las reglas se hayan actualizado correctamente

---

## 👤 Crear el Primer Usuario Admin

Ya que el sistema requiere que un admin cree a otros admins, necesitas crear el primer admin manualmente.

### Opción 1: Usando Firebase Console (Recomendado)

1. **Obtén tu User ID:**
   - Inicia sesión en la app AuraList
   - Ve a Perfil o Configuración
   - Copia tu User ID (UID de Firebase Auth)

   O desde Firebase Console:
   - Ve a **Authentication** → **Users**
   - Copia el UID del usuario que será admin

2. **Crear documento admin en Firestore:**
   - Ve a **Firestore Database**
   - Haz clic en "Start collection"
   - Collection ID: `admins`
   - Document ID: **Pega aquí tu User ID**
   - Campos:
     ```
     email: "tu-email@example.com"
     addedAt: (timestamp) <ahora>
     role: "super_admin"
     addedBy: "manual_setup"
     ```
   - Haz clic en "Save"

3. **Verificar acceso admin:**
   - Cierra y reabre la app
   - Deberías tener permisos de admin ahora

### Opción 2: Usando Firebase CLI

Crea un script temporal para añadir el admin:

```javascript
// add-admin.js
const admin = require('firebase-admin');
const serviceAccount = require('./path/to/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function addAdmin() {
  const uid = 'TU_USER_ID_AQUI'; // Reemplaza con tu UID
  const email = 'tu-email@example.com'; // Tu email

  await db.collection('admins').doc(uid).set({
    email: email,
    addedAt: admin.firestore.FieldValue.serverTimestamp(),
    role: 'super_admin',
    addedBy: 'manual_setup'
  });

  console.log(`Admin ${email} añadido correctamente`);
  process.exit(0);
}

addAdmin().catch(console.error);
```

Ejecutar:
```bash
node add-admin.js
```

### Opción 3: Usando REST API

```bash
# Obtén un ID token de tu sesión
# Luego ejecuta:

curl -X POST \
  'https://firestore.googleapis.com/v1/projects/TU_PROJECT_ID/databases/(default)/documents/admins/TU_USER_ID' \
  -H 'Authorization: Bearer TU_ID_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "fields": {
      "email": {"stringValue": "tu-email@example.com"},
      "role": {"stringValue": "super_admin"},
      "addedBy": {"stringValue": "manual_setup"}
    }
  }'
```

---

## 🗂️ Estructura de la Base de Datos Pública

### Colecciones Públicas

```
/public/
  /guides/{guideId}
    - id: string
    - name: string
    - title: string
    - affinity: string
    - classFamily: string
    - archetype: string
    - powerSentence: string
    - blessingIds: array
    - synergyIds: array
    - themePrimaryHex: string
    - themeSecondaryHex: string
    - themeAccentHex: string
    - descriptionShort: string
    - mythologyOrigin: string
    - blessings: array
    - createdAt: timestamp
    - updatedAt: timestamp
    - version: number

  /wellness/{categoryId}/{suggestionId}
    - id: string
    - title: string
    - description: string
    - category: string
    - motivation: string
    - icon: string
    - durationMinutes: number
    - bestTimeOfDay: string
    - benefits: array
    - recommendations: array
    - createdAt: timestamp
    - updatedAt: timestamp

  /wellness/categories/{categoryId}
    - id: string
    - name: string
    - description: string
    - icon: string
    - color: string
    - count: number

  /resources/
    - prompts, tips, updates, etc.
```

### Permisos

- **Lectura:** Todos los usuarios autenticados
- **Escritura:** Solo usuarios admin (en la colección `/admins`)

---

## 🚀 Migrar Datos a Firestore

Los datos de guías y wellness actualmente están hardcodeados en el código. Necesitan migrarse a Firestore.

### Script de Migración para Guías

Crea `scripts/migrate-guides.js`:

```javascript
const admin = require('firebase-admin');
const serviceAccount = require('../path/to/serviceAccountKey.json');
const { kGuideCatalog } = require('../lib/features/guides/data/guide_catalog.dart');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function migrateGuides() {
  const batch = db.batch();

  kGuideCatalog.forEach(guide => {
    const ref = db.collection('public').doc('guides').collection('guides').doc(guide.id);
    batch.set(ref, {
      ...guide,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      version: 1
    });
  });

  await batch.commit();
  console.log(`Migrados ${kGuideCatalog.length} guías a Firestore`);
}

migrateGuides().catch(console.error);
```

### Script de Migración para Wellness

Similar al anterior, pero usando `wellness_catalog.dart`.

### Migración Manual (Firebase Console)

1. Ve a **Firestore Database**
2. Crea la colección `public`
3. Dentro de `public`, crea subcolección `guides`
4. Para cada guía, crea un documento con el ID del guía
5. Añade los campos necesarios

---

## 🔐 Roles de Admin

### Roles Disponibles

- **super_admin:** Puede hacer todo, incluido añadir/quitar admins
- **editor:** Puede editar contenido público
- **viewer:** Solo puede ver (uso futuro)

### Añadir Nuevos Admins (Como Admin Existente)

Una vez que eres admin, puedes añadir otros desde la app o mediante código:

```dart
// Ejemplo de código para añadir admin (implementar en UI admin)
Future<void> addAdmin(String userId, String email) async {
  await FirebaseFirestore.instance
    .collection('admins')
    .doc(userId)
    .set({
      'email': email,
      'role': 'editor',
      'addedAt': FieldValue.serverTimestamp(),
      'addedBy': currentUser.uid,
    });
}
```

### Verificar si Usuario es Admin

```dart
Future<bool> isUserAdmin(String userId) async {
  final doc = await FirebaseFirestore.instance
    .collection('admins')
    .doc(userId)
    .get();
  return doc.exists;
}
```

---

## ✅ Checklist de Configuración

- [ ] Desplegadas las reglas de Firestore actualizadas
- [ ] Creado el primer usuario admin en `/admins/{userId}`
- [ ] Verificado que el admin puede acceder a colecciones públicas
- [ ] Migrados los guías a `/public/guides/`
- [ ] Migradas las sugerencias de wellness a `/public/wellness/`
- [ ] Probado que usuarios normales pueden leer pero no escribir
- [ ] Probado que admins pueden escribir en colecciones públicas

---

## 🐛 Troubleshooting

### Error: "Permission denied" al leer colecciones públicas

**Problema:** El usuario no está autenticado o las reglas no se desplegaron.

**Solución:**
1. Verifica que el usuario esté autenticado en Firebase
2. Redeploy las reglas: `firebase deploy --only firestore:rules`
3. Espera 1-2 minutos para que las reglas se propaguen

### Error: Admin no puede escribir en colecciones públicas

**Problema:** El documento del admin no existe o está mal configurado.

**Solución:**
1. Verifica que el documento exista en `/admins/{userId}`
2. Verifica que el userId coincida con el Firebase Auth UID
3. Verifica que el documento tenga al menos el campo `email`

### Error: "Document not found" al leer guías

**Problema:** Los datos no se han migrado aún.

**Solución:**
1. Ejecuta el script de migración
2. O añade los documentos manualmente en Firebase Console
3. Mientras tanto, la app seguirá usando los datos hardcodeados

---

## 📚 Próximos Pasos

1. **Implementar UI de Admin** en la app para gestionar contenido público
2. **Migrar datos** desde código a Firestore
3. **Añadir más admins** según sea necesario
4. **Monitorear uso** de Firestore para optimizar costos

---

**Última actualización:** 2026-02-22
**Versión:** 1.0
