# Lista de Verificación: Correcciones de Sincronización Firebase

## Fecha: 2026-02-10

Esta lista de verificación debe completarse antes de considerar las correcciones como validadas en producción.

---

## ✅ Pre-Verificación: Compilación

- [ ] `flutter analyze` no muestra errores
- [ ] `flutter build apk --debug` compila exitosamente
- [ ] `flutter run -d chrome` inicia sin errores

---

## 🧪 Test 1: Persistencia de firestoreId

### Objetivo
Verificar que el `firestoreId` se guarda correctamente en Hive después de sincronizar con Firebase.

### Pasos
1. [ ] Iniciar la app con Firebase configurado
2. [ ] Crear una nueva tarea: "Test FirestoreId"
3. [ ] Verificar en logs: `✅ Tarea sincronizada con Firebase (nueva) - ID: [algún ID]`
4. [ ] Abrir Firestore Console y verificar que la tarea existe
5. [ ] En la app, navegar a otra pantalla y regresar
6. [ ] Cerrar completamente la app
7. [ ] Reabrir la app
8. [ ] Abrir Hive Inspector (si disponible) o verificar en código
9. [ ] Verificar que la tarea tiene `firestoreId` NO vacío
10. [ ] Crear otra tarea: "Test No Duplicado"
11. [ ] Verificar en Firestore Console que NO hay duplicados
12. [ ] Editar la primera tarea
13. [ ] Verificar que se actualiza (no crea nueva) en Firestore

### Criterios de Éxito
- ✅ Cada tarea tiene un `firestoreId` único
- ✅ El `firestoreId` persiste después de reiniciar la app
- ✅ No hay tareas duplicadas en Firestore
- ✅ Las ediciones actualizan, no crean nuevas tareas

### Estado: ⬜ No verificado

---

## 🧪 Test 2: Backoff Exponencial en Sync Queue

### Objetivo
Verificar que la cola de sincronización implementa correctamente el backoff exponencial (2s, 4s, 8s).

### Pasos
1. [ ] Desconectar internet (modo avión o deshabilitar WiFi)
2. [ ] Crear 3 tareas: "Offline Task 1", "Offline Task 2", "Offline Task 3"
3. [ ] Verificar que se guardan localmente
4. [ ] Abrir terminal y ejecutar: `adb logcat | grep "SYNC QUEUE"` (Android) o revisar DevTools console (Web)
5. [ ] Reconectar internet
6. [ ] Observar logs automáticos o llamar manualmente a force sync
7. [ ] Verificar en logs:
   ```
   🔄 [SYNC QUEUE] Procesando 3 tareas pendientes
   ✅ [SYNC QUEUE] Tarea "Offline Task 1" sincronizada desde cola (intento 1)
   ✅ [SYNC QUEUE] Tarea "Offline Task 2" sincronizada desde cola (intento 1)
   ✅ [SYNC QUEUE] Tarea "Offline Task 3" sincronizada desde cola (intento 1)
   ✅ [SYNC QUEUE] 3 items procesados
   ```

### Test con Fallos (Opcional pero Recomendado)
8. [ ] Modificar temporalmente Firebase Rules para rechazar writes
9. [ ] Crear tarea: "Test Retry"
10. [ ] Observar primer intento (falla inmediatamente)
11. [ ] Verificar log: `❌ [SYNC QUEUE] Error al procesar item (intento 1/3)`
12. [ ] Intentar sync inmediatamente
13. [ ] Verificar log: `⏸️ [SYNC QUEUE] Item en backoff (intento 2/3), saltando`
14. [ ] Esperar 2 segundos
15. [ ] Intentar sync
16. [ ] Verificar log: `❌ [SYNC QUEUE] Error al procesar item (intento 2/3)`
17. [ ] Esperar 4 segundos
18. [ ] Intentar sync
19. [ ] Verificar log: `❌ [SYNC QUEUE] Error al procesar item (intento 3/3)`
20. [ ] Intentar sync una vez más
21. [ ] Verificar log: `❌ [SYNC QUEUE] Item excede max reintentos (3), eliminando`
22. [ ] Restaurar Firebase Rules

### Criterios de Éxito
- ✅ Tareas offline se sincronizan cuando hay conexión
- ✅ Backoff respeta delays: inmediato → 2s → 4s → 8s
- ✅ Items se eliminan después de 3 intentos fallidos
- ✅ Logs muestran `retryCount` correcto

### Estado: ⬜ No verificado

---

## 🧪 Test 3: cloudSyncEnabled Respetado

### Objetivo
Verificar que el sistema respeta la preferencia del usuario de deshabilitar cloud sync.

### Pasos
1. [ ] Ir a Configuración/Perfil en la app
2. [ ] Deshabilitar "Sincronización en la nube"
3. [ ] Verificar que la opción se guarda
4. [ ] Crear nueva tarea: "Local Only Task"
5. [ ] Verificar en logs: `⚠️ [SYNC] Cloud sync deshabilitado, tarea guardada solo localmente`
6. [ ] Abrir Firestore Console
7. [ ] Verificar que la tarea NO aparece en Firestore
8. [ ] Editar la tarea
9. [ ] Verificar nuevamente que NO se sincroniza
10. [ ] Habilitar "Sincronización en la nube"
11. [ ] Crear nueva tarea: "Cloud Enabled Task"
12. [ ] Verificar que SÍ se sincroniza a Firestore
13. [ ] Verificar que la tarea "Local Only Task" se sincroniza automáticamente

### Criterios de Éxito
- ✅ Cuando sync está deshabilitado, NO se llama a Firebase
- ✅ La app funciona completamente offline
- ✅ Al habilitar sync, tareas pendientes se sincronizan
- ✅ La preferencia persiste después de reiniciar la app

### Estado: ⬜ No verificado

---

## 🧪 Test 4: Manejo de userId Vacío

### Objetivo
Verificar que tareas creadas sin usuario autenticado se sincronizan correctamente después del login.

### Pasos (Requiere modificación temporal del código)
1. [ ] Modificar `AuthService.signInAnonymously()` para retornar `null` temporalmente
2. [ ] Reiniciar la app
3. [ ] Verificar que NO hay usuario autenticado
4. [ ] Crear tarea: "No Auth Task"
5. [ ] Verificar en logs: `⚠️ [TaskProvider] Usuario no autenticado, tarea se sincronizará cuando haya auth`
6. [ ] Verificar que la tarea se guarda localmente en Hive
7. [ ] Verificar que NO está en Firestore (no hay userId)
8. [ ] Restaurar `AuthService.signInAnonymously()` al código original
9. [ ] Reiniciar la app
10. [ ] Esperar a que auth se complete
11. [ ] Observar logs de sync automático
12. [ ] Verificar que "No Auth Task" ahora tiene `firestoreId`
13. [ ] Verificar en Firestore que la tarea existe

### Criterios de Éxito
- ✅ Tareas creadas sin auth se guardan localmente
- ✅ No causan crashes ni errores
- ✅ Se sincronizan automáticamente al obtener auth
- ✅ No se pierden datos

### Estado: ⬜ No verificado

---

## 🧪 Test 5: Timestamps Correctos

### Objetivo
Verificar que todas las tareas tienen `createdAt` y `lastUpdatedAt` correctamente establecidos.

### Pasos
1. [ ] Crear nueva tarea: "Timestamp Test"
2. [ ] Abrir Hive Inspector o agregar breakpoint
3. [ ] Verificar que la tarea tiene:
   - `createdAt`: timestamp actual
   - `lastUpdatedAt`: mismo valor que `createdAt`
4. [ ] Esperar 5 segundos
5. [ ] Editar la tarea (cambiar título o completarla)
6. [ ] Verificar que:
   - `createdAt`: NO cambió
   - `lastUpdatedAt`: timestamp más reciente que `createdAt`
7. [ ] Abrir Firestore Console
8. [ ] Verificar que el documento tiene ambos campos:
   ```json
   {
     "createdAt": "2026-02-10T...",
     "lastUpdatedAt": "2026-02-10T...",
     ...
   }
   ```
9. [ ] Crear tarea en dispositivo A
10. [ ] Editar la misma tarea en dispositivo B
11. [ ] Sincronizar dispositivo A
12. [ ] Verificar que gana la versión más reciente (por `lastUpdatedAt`)

### Criterios de Éxito
- ✅ Todas las tareas nuevas tienen ambos timestamps
- ✅ `lastUpdatedAt` se actualiza en cada edición
- ✅ Firebase recibe los timestamps correctos
- ✅ Comparaciones de timestamps funcionan para resolver conflictos

### Estado: ⬜ No verificado

---

## 🧪 Test 6: Migración de Datos Existentes

### Objetivo
Verificar que tareas existentes sin `lastUpdatedAt` se migran correctamente.

### Pasos (Requiere datos pre-existentes)
1. [ ] Tener tareas creadas con versión anterior (sin `lastUpdatedAt`)
2. [ ] Actualizar a nueva versión
3. [ ] Iniciar la app
4. [ ] Verificar en logs: `Migraciones completadas`
5. [ ] Abrir Hive Inspector
6. [ ] Verificar que TODAS las tareas ahora tienen `lastUpdatedAt`
7. [ ] Verificar que tareas sin ese campo ahora tienen `lastUpdatedAt = createdAt`

### Criterios de Éxito
- ✅ Todas las tareas tienen `lastUpdatedAt` después de migración
- ✅ No hay crashes durante migración
- ✅ La migración es idempotente (ejecutar varias veces no causa problemas)

### Estado: ⬜ No verificado

---

## 🧪 Test 7: Escenario Completo End-to-End

### Objetivo
Verificar el flujo completo de sincronización en un escenario real.

### Pasos
1. [ ] Dispositivo A: Crear tarea "Task A1"
2. [ ] Verificar que se sincroniza a Firebase
3. [ ] Dispositivo B: Iniciar app
4. [ ] Verificar que "Task A1" se descarga
5. [ ] Dispositivo B (offline): Crear tarea "Task B1"
6. [ ] Dispositivo B (offline): Editar "Task A1"
7. [ ] Dispositivo A (online): Editar "Task A1" (conflicto potencial)
8. [ ] Dispositivo B: Reconectar
9. [ ] Verificar resolución de conflicto (última modificación gana)
10. [ ] Verificar que "Task B1" se sincroniza
11. [ ] Ambos dispositivos: Verificar que tienen las mismas tareas
12. [ ] Dispositivo A: Completar "Task A1"
13. [ ] Dispositivo B: Verificar que se refleja el cambio
14. [ ] Dispositivo B: Eliminar "Task B1"
15. [ ] Dispositivo A: Verificar que desaparece "Task B1"

### Criterios de Éxito
- ✅ Sync bidireccional funciona correctamente
- ✅ Conflictos se resuelven sin pérdida de datos
- ✅ Cambios se propagan entre dispositivos
- ✅ No hay duplicados ni tareas huérfanas

### Estado: ⬜ No verificado

---

## 🐛 Test 8: Manejo de Errores

### Objetivo
Verificar que el sistema maneja errores de red y Firebase correctamente.

### Pasos
1. [ ] Desconectar internet en medio de sync
2. [ ] Verificar que el error se captura sin crash
3. [ ] Verificar que la tarea va a sync queue
4. [ ] Intentar sync con Firebase Rules inválidas
5. [ ] Verificar que el error se maneja gracefully
6. [ ] Llenar sync queue con 50+ items
7. [ ] Verificar que no hay problemas de performance
8. [ ] Desconectar por 8+ días
9. [ ] Reconectar
10. [ ] Verificar que items muy viejos se eliminan de queue

### Criterios de Éxito
- ✅ No crashes por errores de red
- ✅ Errores se registran en logs
- ✅ Usuario recibe feedback apropiado
- ✅ Sync queue no crece indefinidamente

### Estado: ⬜ No verificado

---

## 📊 Resumen de Verificación

| Test | Estado | Observaciones |
|------|--------|---------------|
| 1. Persistencia firestoreId | ⬜ | |
| 2. Backoff exponencial | ⬜ | |
| 3. cloudSyncEnabled | ⬜ | |
| 4. userId vacío | ⬜ | |
| 5. Timestamps | ⬜ | |
| 6. Migración datos | ⬜ | |
| 7. End-to-End | ⬜ | |
| 8. Manejo errores | ⬜ | |

---

## ✅ Criterios de Aceptación Final

Para considerar las correcciones como exitosas, TODOS los siguientes criterios deben cumplirse:

- [ ] Todos los tests (1-8) pasan exitosamente
- [ ] No hay crashes relacionados con sync en 7 días de uso
- [ ] Sync queue no crece más de 100 items en uso normal
- [ ] `firestoreId` persiste en 100% de los casos
- [ ] cloudSyncEnabled se respeta en 100% de las operaciones
- [ ] 0 tareas duplicadas en Firestore
- [ ] 0 tareas huérfanas (sin path de sincronización)
- [ ] Logs de sync son claros y útiles para debugging
- [ ] Performance no se degrada con sync habilitado
- [ ] App funciona perfectamente en modo offline

---

## 🚨 Problemas Conocidos a Monitorear

### Issue #1: Resolución de conflictos no implementada completamente
- **Estado**: Parcialmente implementado
- **Impacto**: Si dos dispositivos editan la misma tarea offline simultáneamente, puede haber inconsistencias
- **Mitigación**: Implementar en próxima fase
- **Workaround**: Last-write-wins basado en `lastUpdatedAt`

### Issue #2: Sync queue puede crecer en casos extremos
- **Estado**: Mitigado (items > 7 días se eliminan)
- **Impacto**: Si usuario está offline por mucho tiempo, queue puede crecer
- **Mitigación**: Límite de 7 días implementado
- **Workaround**: Usuario puede forzar limpiar queue en configuración

---

## 📝 Notas del Verificador

```
Fecha: ___________
Verificado por: ___________

Observaciones:


Issues encontrados:


Acciones requeridas:


```

---

## ✅ Aprobación Final

- [ ] Todos los tests pasan
- [ ] Documentación actualizada
- [ ] Código revisado por peer
- [ ] Performance validada
- [ ] Listo para deployment

**Aprobado por**: ___________
**Fecha**: ___________
