// Politica de Privacidad de AuraList
// Version 1.0 - Febrero 2025
// Cumplimiento: GDPR, LGPD, CCPA

const String privacyPolicyEs = '''
# Politica de Privacidad de AuraList

**Ultima actualizacion: Febrero 2025**

En AuraList, tu privacidad es fundamental. Esta politica explica como recopilamos, usamos y protegemos tu informacion.

## 1. Informacion que Recopilamos

### 1.1 Datos Proporcionados Directamente

**Contenido creado por ti:**
- Tareas y sus detalles (titulo, fecha, prioridad, categoria)
- Notas y su contenido
- Recompensas y motivaciones personalizadas
- Preferencias de la aplicacion

**Informacion de cuenta (solo si vinculas tu cuenta):**
- Correo electronico
- Nombre de perfil (si usas Google Sign-In)

### 1.2 Datos Recopilados Automaticamente

**Datos tecnicos minimos:**
- Identificador anonimo de sesion
- Tipo de dispositivo y sistema operativo (para compatibilidad)
- Fecha y hora de sincronizacion

**Lo que NO recopilamos:**
- Ubicacion geografica
- Contactos de tu telefono
- Historial de navegacion
- Datos de otras aplicaciones

## 2. Como Usamos tu Informacion

Usamos tus datos exclusivamente para:

- **Proporcionar el servicio:** Almacenar y sincronizar tus tareas y notas
- **Mejorar la experiencia:** Calcular estadisticas de progreso y rachas
- **Sincronizacion:** Mantener tus datos actualizados entre dispositivos (opcional)
- **Soporte:** Resolver problemas tecnicos si nos contactas

**Nunca usamos tus datos para:**
- Publicidad dirigida
- Venta a terceros
- Perfilado de comportamiento
- Marketing sin tu consentimiento

## 3. Almacenamiento y Seguridad

### 3.1 Almacenamiento Local
Tus datos se guardan en tu dispositivo usando Hive, una base de datos local segura. Estos datos:
- Permanecen en tu dispositivo
- No requieren internet
- Se eliminan al desinstalar la app

### 3.2 Almacenamiento en la Nube (Opcional)
Si activas la sincronizacion, tus datos se almacenan en Firebase (Google Cloud):
- Datos encriptados en transito (HTTPS/TLS)
- Datos encriptados en reposo
- Acceso restringido solo a tu cuenta
- Servidores ubicados en regiones de Google Cloud

### 3.3 Medidas de Seguridad
- Autenticacion requerida para acceso a datos en la nube
- Reglas de seguridad de Firestore para proteger datos
- No almacenamos contrasenas en texto plano

## 4. Tus Derechos (GDPR/LGPD/CCPA)

Tienes los siguientes derechos sobre tus datos:

### 4.1 Derecho de Acceso
Puedes ver todos tus datos dentro de la aplicacion en cualquier momento.

### 4.2 Derecho de Rectificacion
Puedes editar o corregir cualquier tarea, nota o dato personal directamente en la app.

### 4.3 Derecho de Supresion ("Derecho al Olvido")
Puedes eliminar:
- Tareas y notas individuales
- Toda tu cuenta y datos asociados
La eliminacion es permanente e irreversible.

### 4.4 Derecho de Portabilidad
Puedes exportar todos tus datos en formato JSON desde la configuracion de la app.

### 4.5 Derecho de Oposicion
Puedes:
- Desactivar la sincronizacion en la nube
- Revocar todos los consentimientos
- Usar la app en modo completamente offline

### 4.6 Derecho a Retirar el Consentimiento
Puedes retirar tu consentimiento en cualquier momento desde la configuracion de la app, sin afectar la legalidad del procesamiento previo.

## 5. Retencion de Datos

### 5.1 Datos Locales
Permanecen hasta que los elimines o desinstales la app.

### 5.2 Datos en la Nube
- Datos activos: Hasta que elimines tu cuenta
- Datos eliminados: Se borran inmediatamente de nuestros sistemas activos
- Copias de seguridad: Pueden persistir hasta 30 dias en backups automaticos

### 5.3 Datos Anonimos
Podemos retener datos agregados y anonimizados para analisis estadistico.

## 6. Cookies y Tecnologias Similares

AuraList no usa cookies de seguimiento. Solo usamos almacenamiento local para:
- Tus preferencias de tema (claro/oscuro)
- Estado de aceptacion de terminos
- Cache de datos para funcionamiento offline

## 7. Transferencias Internacionales

Si usas sincronizacion en la nube, tus datos pueden almacenarse en servidores de Google Cloud ubicados en diferentes paises. Google cumple con:
- Clausulas Contractuales Tipo de la UE
- Privacy Shield (donde aplique)
- Certificaciones SOC 2 y ISO 27001

## 8. Menores de Edad

AuraList no esta dirigido a menores de 13 anos. Si eres padre/tutor y descubres que un menor ha proporcionado datos personales sin consentimiento, contactanos para eliminarlos.

## 9. Cambios a esta Politica

Podemos actualizar esta politica ocasionalmente. Te notificaremos de cambios significativos a traves de:
- Notificacion en la aplicacion
- Actualizacion de la fecha "Ultima actualizacion"

Te recomendamos revisar esta politica periodicamente.

## 10. Servicios de Terceros

### 10.1 Firebase (Google)
Usamos Firebase para autenticacion y almacenamiento en la nube. Su politica de privacidad esta disponible en: https://firebase.google.com/support/privacy

### 10.2 Google Sign-In
Si vinculas tu cuenta con Google, aplicara tambien la politica de privacidad de Google.

## 11. Contacto

Para ejercer tus derechos o consultas sobre privacidad:
- Email: servicioweb.pmi@gmail.com
- Creador: ink.enzo
- Tiempo de respuesta: Maximo 30 dias

## 12. Base Legal del Procesamiento

Procesamos tus datos basandonos en:
- **Ejecucion del contrato:** Para proporcionar el servicio que solicitas
- **Consentimiento:** Para sincronizacion en la nube y notificaciones
- **Intereses legitimos:** Para mejorar y asegurar el servicio

---

Al usar AuraList, confirmas que has leido y comprendido esta Politica de Privacidad.
''';

/// Key privacy points for quick display
const String privacySummaryEs = '''
- Tus datos de tareas y notas son privados y te pertenecen
- No vendemos ni compartimos tu informacion con terceros
- La sincronizacion en la nube es opcional
- Puedes exportar o eliminar todos tus datos en cualquier momento
- Cumplimos con GDPR, LGPD y CCPA
''';

/// Rights summary for consent dialog
const String rightsListEs = '''
Tienes derecho a:
- Acceder a todos tus datos
- Corregir informacion incorrecta
- Eliminar tu cuenta y datos
- Exportar tus datos
- Revocar consentimientos
- Oponerte al procesamiento
''';
