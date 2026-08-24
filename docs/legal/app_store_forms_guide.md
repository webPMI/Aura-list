# Guía de Formularios de Tiendas de Aplicaciones - AuraList

**Fecha:** 24 de agosto de 2026  
**Aplicación:** AuraList  
**Categoría:** Productivity/Finance

---

## 📱 Google Play Console

### 1. Data Safety Form

#### Información General
**Ubicación:** Play Console → App content → Data safety  
**Obligatorio:** Sí, para todas las apps  
**Actualización:** Requerida cuando cambian las prácticas de datos

#### Tipos de Datos a Declarar

**Datos que AuraList recopila:**

##### ✅ Datos Personales
- **Email**
  - Propósito: Vinculación de cuenta opcional
  - Es opcional: Sí
  - Se comparte: No
  - Se requiere para la funcionalidad: No (modo offline disponible)

- **Nombre de perfil**
  - Propósito: Google Sign-In opcional
  - Es opcional: Sí
  - Se comparte: No
  - Se requiere para la funcionalidad: No

##### ✅ Datos Financieros
- **Información de transacciones**
  - Propósito: Gestión de finanzas personales
  - Es opcional: Sí (feature opcional)
  - Se comparte: No
  - Se requiere para la funcionalidad: No

- **Información de presupuestos**
  - Propósito: Control de gastos
  - Es opcional: Sí (feature opcional)
  - Se comparte: No
  - Se requiere para la funcionalidad: No

##### ✅ Datos de App
- **Acciones de usuario** (tareas creadas, completadas)
  - Propósito: Funcionalidad principal de la app
  - Es opcional: No
  - Se comparte: No
  - Se requiere para la funcionalidad: Sí

- **Información de dispositivo** (tipo de dispositivo, OS)
  - Propósito: Compatibilidad y debugging
  - Es opcional: No
  - Se comparte: No
  - Se requiere para la funcionalidad: Sí

#### Datos que NO se recopilan
- ❌ Ubicación
- ❌ Contactos
- ❌ Historial de navegación
- ❌ Datos biométricos
- ❌ Mensajes
- ❌ Fotos/videos
- ❌ Audio

#### Prácticas de Seguridad

**Encriptación:**
- ✅ Encriptación en tránsito (HTTPS/TLS)
- ✅ Encriptación en reposo (Hive local + Firebase)
- ✅ Encriptación de datos financieros

**Control de Acceso:**
- ✅ Autenticación requerida para datos en la nube
- ✅ Reglas de seguridad de Firestore
- ✅ No acceso por parte de terceros

#### Compartir de Datos

**Terceros:**
- ❌ No se comparten datos con terceros para marketing
- ❌ No se venden datos personales
- ✅ Firebase (Google) solo para almacenamiento en la nube
  - Propósito: Sincronización opcional
  - Encriptado: Sí
  - Cumple con GDPR: Sí

#### SDKs y Bibliotecas de Terceros

**Declarar los siguientes SDKs:**

1. **Firebase Core**
   - Propósito: Funcionalidad de Firebase
   - Datos: Identificador de app, datos de diagnóstico
   - Uso: Servicios de Firebase

2. **Firebase Auth**
   - Propósito: Autenticación
   - Datos: Email, tokens de autenticación
   - Uso: Gestión de usuarios

3. **Cloud Firestore**
   - Propósito: Base de datos en la nube
   - Datos: Datos de usuario (tareas, finanzas)
   - Uso: Sincronización

4. **Google Sign-In**
   - Propósito: Autenticación social
   - Datos: Nombre, email (sí se autoriza)
   - Uso: Vinculación de cuenta

5. **Flutter Local Notifications**
   - Propósito: Notificaciones push
   - Datos: Ninguno (local)
   - Uso: Recordatorios

#### Respuestas Específicas

**¿Su app recopila o comparte datos de usuario?**
- ✅ Sí

**¿Su app comparte datos de usuario con terceros?**
- ❌ No (excepto Firebase para funcionalidad)

**¿Su app usa datos de usuario para tracking?**
- ❌ No

**¿Su app permite a los usuarios controlar su información?**
- ✅ Sí (exportación, eliminación, configuración)

---

### 2. Financial Features Declaration

#### Información General
**Ubicación:** Play Console → Policy → Financial features  
**Obligatorio:** DEPENDE - Solo si Google considera la app como "financiera"  
**Actualización:** Requerida cuando cambian las features financieras

**IMPORTANTE:** Dado que AuraList solo permite registro manual de gastos e ingresos (no procesa transacciones reales), puede NO requerir este formulario. Google Play puede considerar esta app como "Productivity" en lugar de "Finance".

**Recomendación:** Intentar publicar sin este formulario primero. Si Google lo solicita, completarlo con las respuestas a continuación.

#### Preguntas y Respuestas (Solo si Google lo solicita)

**¿Su app ofrece o promueve productos o servicios financieros?**
- ❌ No (herramientas de productividad con registro manual opcional)

**¿Qué tipo de features financieros ofrece?**
- ✅ Registro manual de gastos e ingresos personales
- ✅ Presupuestación personal básica
- ✅ Seguimiento de gastos para organización personal
- ❌ Gestión de transacciones reales
- ❌ Procesamiento de pagos
- ❌ Préstamos
- ❌ Inversiones
- ❌ Seguros
- ❌ Banca
- ❌ Criptomonedas
- ❌ Transferencias de dinero

**¿Su app ofrece préstamos?**
- ❌ No

**¿Su app es una institución financiera regulada?**
- ❌ No

**¿Su app conecta usuarios con prestamistas de terceros?**
- ❌ No

**¿Su app ofrece servicios de asesoramiento financiero?**
- ❌ No (herramientas de registro personal únicamente)

#### Información Adicional

**Disclaimer requerido en el listing:**
```
Esta aplicación proporciona herramientas de gestión financiera 
para fines informativos únicamente. No constituye asesoramiento 
financiero profesional ni está afiliada con instituciones financieras 
reguladas.
```

**Categoría recomendada:**
- **Productivity** (categoría principal)
- **Finance** (categoría secundaria, si aplica)

---

### 3. Content Rating

#### Información General
**Ubicación:** Play Console → Content rating  
**Obligatorio:** Sí  
**Actualización:** Requerido cuando cambia el contenido

#### Preguntas de Rating

**Violencia:**
- ❌ No contiene violencia

**Contenido sexual:**
- ❌ No contiene contenido sexual

**Lenguaje:**
- ❌ No contiene lenguaje ofensivo

**Sustancias controladas:**
- ❌ No hace referencia a drogas/alcohol

**Compras dentro de la app:**
- ❌ No hay compras dentro de la app

**Apuestas:**
- ❌ No hay apuestas

**Usuarios interactivos:**
- ❌ No hay interacción entre usuarios

**Información personal:**
- ✅ Permite a los usuarios proporcionar información personal
  - Email (opcional)
  - Datos financieros (opcional)

**Datos financieros:**
- ✅ Permite a los usuarios proporcionar datos financieros
  - Transacciones personales
  - Presupuestos

**Rating recomendado:**
- **Everyone** (T) - apropiado para todos

---

## 🍎 Apple App Store Connect

### 1. App Privacy Details

#### Información General
**Ubicación:** App Store Connect → My Apps → [App] → App Information → App Privacy  
**Obligatorio:** Sí, para todas las apps y updates  
**Actualización:** Requerida cuando cambian las prácticas de datos

#### Pregunta 1: ¿Recopila datos?

**Respuesta:** ✅ Sí, recopilamos datos

#### Tipos de Datos a Declarar

##### Contact Info
- **Email Address**
  - Propósito: Vinculación de cuenta opcional
  - ¿Se usa para tracking? ❌ No
  - ¿Se vincula al usuario? ✅ Sí
  - ¿Se usa para terceros? ❌ No

##### Health and Fitness
- ❌ No se recopilan datos de salud

##### Financial Info
- **Payment Info** (NO - no se procesan pagos)
- **Other Financial Info**
  - Propósito: Gestión de finanzas personales
  - ¿Se usa para tracking? ❌ No
  - ¿Se vincula al usuario? ✅ Sí
  - ¿Se usa para terceros? ❌ No

##### Location
- ❌ No se recopila ubicación

##### Contacts
- ❌ No se recopilan contactos

##### User Content
- **Other User Content**
  - Propósito: Tareas, notas, datos creados por usuario
  - ¿Se usa para tracking? ❌ No
  - ¿Se vincula al usuario? ✅ Sí
  - ¿Se usa para terceros? ❌ No

##### Browsing History
- ❌ No se recopila historial de navegación

##### Search History
- ❌ No se recopila historial de búsqueda

##### Identifiers
- **Device ID**
  - Propósito: Funcionalidad técnica y debugging
  - ¿Se usa para tracking? ❌ No
  - ¿Se vincula al usuario? ❌ No
  - ¿Se usa para terceros? ❌ No

##### Purchases
- ❌ No hay compras dentro de la app

##### Usage Data
- **Product Interaction**
  - Propósito: Mejora de la app y debugging
  - ¿Se usa para tracking? ❌ No
  - ¿Se vincula al usuario? ❌ No
  - ¿Se usa para terceros? ❌ No

##### Diagnostics
- **Crash Data**
  - Propósito: Estabilidad de la app
  - ¿Se usa para tracking? ❌ No
  - ¿Se vincula al usuario? ❌ No
  - ¿Se usa para terceros? ❌ No

- **Performance Data**
  - Propósito: Optimización de la app
  - ¿Se usa para tracking? ❌ No
  - ¿Se vincula al usuario? ❌ No
  - ¿Se usa para terceros? ❌ No

##### Other Data
- ❌ No se recopilan otros tipos de datos

#### Pregunta 2: ¿Vincula datos al usuario?

**Respuesta:** ✅ Sí, algunos datos están vinculados al usuario

- Email, datos financieros, contenido de usuario

#### Pregunta 3: ¿Usa datos para tracking?

**Respuesta:** ❌ No, no usamos datos para tracking

- No seguimos a usuarios entre apps o sitios web
- No usamos datos para publicidad

#### Pregunta 4: ¿Comparte datos con terceros?

**Respuesta:** ❌ No, no compartimos datos con terceros

- Excepto Firebase para funcionalidad de sincronización
- Firebase cumple con todas las regulaciones aplicables

---

### 2. Privacy Policy URL

#### Información General
**Ubicación:** App Store Connect → My Apps → [App] → App Information  
**Obligatorio:** Sí  
**Requisitos:** URL pública y accesible

#### Configuración

**URL recomendada:**
```
https://auralist.com/privacy
```

**Alternativas:**
- GitHub Pages: `https://inkenzo.github.io/auralist/privacy`
- Otro hosting estático

**Requisitos:**
- [ ] URL pública y accesible
- [ ] Contenido completo de política de privacidad
- [ ] Información de contacto
- [ ] Fecha de última actualización
- [ ] Compatible con móviles

---

### 3. User Privacy Choices URL (Opcional pero Recomendado)

#### Información General
**Ubicación:** App Store Connect → My Apps → [App] → App Information  
**Obligatorio:** No, pero recomendado para CCPA/GDPR

#### Configuración

**URL recomendada:**
```
https://auralist.com/privacy-choices
```

**Contenido:**
- Formulario para solicitar acceso a datos
- Formulario para solicitar eliminación de datos
- Formulario para opt-out de sharing
- Información de contacto legal

---

### 4. Age Rating

#### Información General
**Ubicación:** App Store Connect → My Apps → [App] → Pricing and Availability  
**Obligatorio:** Sí

#### Preguntas de Rating

**Violencia:**
- ❌ No contiene violencia

**Contenido sexual:**
- ❌ No contiene contenido sexual

**Lenguaje:**
- ❌ No contiene lenguaje ofensivo

**Sustancias controladas:**
- ❌ No hace referencia a drogas/alcohol

**Contenido adulto:**
- ❌ No contiene contenido adulto

**Apuestas:**
- ❌ No hay apuestas

**Compras dentro de la app:**
- ❌ No hay compras dentro de la app

**Rating recomendado:**
- **4+** (Everyone) - apropiado para todos

---

## 🔒 SDKs de Terceros - Privacy Manifests

### SDKs que Requieren Privacy Manifest

#### Firebase SDKs
**Requerido:** Sí  
**Documentación:** https://firebase.google.com/docs/ios/privacy-manifest

**Implementación:**
1. Descargar privacy manifests de Firebase
2. Agregar al proyecto Xcode
3. Configurar en `Info.plist`

#### Google Sign-In
**Requerido:** Sí  
**Documentación:** https://developers.google.com/identity/sign-in/ios/privacy-manifest

**Implementación:**
1. Descargar privacy manifest de Google Sign-In
2. Agregar al proyecto Xcode
3. Configurar en `Info.plist`

### Implementación de Privacy Manifests

**Archivo:** `PrivacyInfo.xcprivacy`

**Estructura:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array>
        <!-- Datos recopilados -->
    </array>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <!-- APIs accedidas -->
    </array>
</dict>
</plist>
```

---

## 📋 Checklist de Implementación

### Google Play Console
- [ ] Data Safety Form completado
- [ ] Content Rating completado
- [ ] Política de privacidad vinculada
- [ ] SDKs declarados correctamente
- [ ] Categoría de app verificada (Productivity, no Finance)
- [ ] Financial Features Declaration (solo si Google lo solicita)

### Apple App Store Connect
- [ ] App Privacy Details completado
- [ ] Privacy Policy URL configurada
- [ ] User Privacy Choices URL configurada (opcional)
- [ ] Age Rating completado
- [ ] Privacy manifests implementados
- [ ] SDK signatures implementados

### General
- [ ] Política de privacidad actualizada
- [ ] Términos de servicio actualizados
- [ ] Disclaimer financiero agregado
- [ ] Enlaces visibles en la app
- [ ] Formularios de contacto legales

---

## 🚨 Errores Comunes a Evitar

### Google Play
- ❌ No declarar todos los tipos de datos
- ❌ No actualizar cuando cambian las prácticas
- ❌ Olvidar declarar SDKs de terceros
- ❌ No especificar si la recopilación es opcional
- ❌ No completar Financial Features Declaration

### Apple App Store
- ❌ No responder todas las preguntas de privacidad
- ❌ No configurar Privacy Policy URL
- ❌ No implementar privacy manifests para SDKs requeridos
- ❌ No actualizar cuando cambian las prácticas
- ❌ Declarar datos que no se recopilan

---

## 📞 Soporte y Recursos

### Google Play
- **Data Safety Help:** https://support.google.com/googleplay/android-developer/answer/10787469
- **Financial Features Policy:** https://support.google.com/googleplay/android-developer/answer/9876821
- **Developer Policy Center:** https://play.google.com/about/developer-content-policy/

### Apple App Store
- **App Privacy Details:** https://developer.apple.com/app-store/app-privacy-details/
- **User Privacy and Data Use:** https://developer.apple.com/app-store/user-privacy-and-data-use/
- **App Review Guidelines:** https://developer.apple.com/app-store/review/guidelines/

---

**Importante:** La información en este documento debe actualizarse regularmente para reflejar cambios en las políticas de las tiendas y en las prácticas de datos de AuraList.