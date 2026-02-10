# Lista de Verificación - Sincronización Firebase

## ✅ Pasos para Verificar que la Sincronización Funciona

### 1. Verificar Inicialización de Firebase

Ejecuta la app y busca estos logs en la consola:

```bash
flutter run -d windows  # o -d chrome, -d android, etc.
```

**Logs esperados:**

```
✅ Firebase inicializado correctamente
✅ No hay usuario autenticado, iniciando sesión anónima...
✅ Usuario anónimo creado correctamente
```

O si ya hay un usuario guardado:

```
✅ Firebase inicializado correctamente
✅ Usuario ya autenticado: [userId]
```

---

### 2. Crear una Tarea Nueva

1. Abre la aplicación
2. Haz clic en "Nueva Tarea"
3. Escribe un título (ej: "Test de sincronización")
4. Presiona "Agregar"

**Logs esperados:**

```
➕ [TASK] Guardando tarea localmente: "Test de sincronización"
👤 [TASK] Usuario autenticado: [userId], sincronizando...
🔄 [SYNC] Iniciando sincronización de tarea "Test de sincronización" para usuario [userId]
✅ Tarea sincronizada con Firebase (nueva)
```

---

### 3. Verificar en Firebase Console

1. Abre [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto "aura-list"
3. Ve a "Firestore Database"
4. Busca la colección: `users > {userId} > tasks`
5. Verifica que tu tarea esté presente con los datos correctos

**Estructura esperada:**

```
users/
  ├─ [userId]/
  │   ├─ tasks/
  │   │   ├─ [taskId]/
  │   │   │   ├─ title: "Test de sincronización"
  │   │   │   ├─ type: "daily"
  │   │   │   ├─ isCompleted: false
  │   │   │   ├─ priority: 1
  │   │   │   ├─ category: "Personal"
  │   │   │   ├─ createdAt: "2026-02-10T..."
  │   │   │   └─ ... otros campos
```

---

### 4. Probar Actualización de Tarea

1. Marca una tarea como completada (toggle checkbox)
2. Observa los logs

**Logs esperados:**

```
⏱️ [SYNC] Agregando tarea "[nombre]" a cola de sincronización (debounced)
🔄 [SYNC] Flushing 1 tareas y 0 notas pendientes
📦 [SYNC] Sincronizando lote: 1 tareas, 0 notas
✅ Batch sync completado: 1 tareas, 0 notas
```

3. Verifica en Firebase Console que el campo `isCompleted` cambió a `true`

---

### 5. Probar Sin Conexión (Offline)

1. Desconecta tu internet o desactiva Firebase:
   - En `main.dart`, cambia temporalmente:
   ```dart
   await Firebase.initializeApp(...);
   // a
   throw Exception('Test offline');
   ```

2. Crea una tarea nueva

**Logs esperados:**

```
❌ Error al inicializar Firebase: [error]
⚠️ La aplicación funcionará en modo local únicamente
➕ [TASK] Guardando tarea localmente: "[nombre]"
⚠️ [TASK] No hay usuario autenticado, tarea guardada solo localmente
```

3. Verifica que la tarea se guardó localmente (aparece en la UI)
4. Restaura la conexión
5. Fuerza sincronización:
   - Presiona el icono de nube en el AppBar (si hay tareas pendientes)
   - O cierra y reabre la app

**Logs esperados:**

```
✅ Firebase inicializado correctamente
✅ Usuario ya autenticado: [userId]
🔄 [SYNC] Procesando cola de sincronización...
✅ Tarea sincronizada con Firebase (nueva)
```

---

### 6. Probar Eliminación de Tarea

1. Elimina una tarea sincronizada
2. Observa los logs

**Logs esperados:**

```
[Logs de eliminación local]
🗑️ Tarea eliminada de Firebase
```

3. Verifica en Firebase Console que el documento fue eliminado

---

## ❌ Problemas Comunes y Soluciones

### Problema: "Usuario no autenticado"

**Síntoma:**
```
⚠️ [SYNC] Usuario no autenticado (userId vacío)
```

**Solución:**
- Verifica que `_initializeAuth()` se ejecute en `main.dart`
- Busca logs de "iniciando sesión anónima"
- Si no aparecen, revisa que Firebase se inicializó correctamente

---

### Problema: Reglas de Firestore niegan el acceso

**Síntoma:**
```
❌ [SYNC] Error al sincronizar tarea: FirebaseException [permission-denied]
```

**Solución:**
1. Verifica las reglas en Firebase Console > Firestore Database > Rules
2. Deben permitir acceso a usuarios autenticados:
   ```javascript
   allow read, write: if request.auth != null && request.auth.uid == userId;
   ```
3. Si las reglas están en modo `test mode`, cámbialas a las reglas de producción

---

### Problema: Firebase no inicializado

**Síntoma:**
```
⚠️ [SYNC] Firebase no disponible
```

**Solución:**
- Verifica que `firebase_options.dart` existe
- Ejecuta: `flutterfire configure`
- Asegúrate de que las credenciales son correctas

---

### Problema: Timeout en sincronización

**Síntoma:**
```
❌ [SYNC] Error al sincronizar tarea: TimeoutException
```

**Solución:**
- Verifica tu conexión a internet
- La tarea se agregó a la cola de sincronización
- Se reintentará automáticamente

---

## 🔍 Comandos de Diagnóstico

### Ver logs detallados:
```bash
flutter run --verbose
```

### Ver solo logs de sincronización:
```bash
flutter run | grep "\[SYNC\]"
```

### Verificar estado de Firebase:
```bash
firebase projects:list
firebase use aura-list
firebase firestore:indexes
```

### Verificar análisis estático:
```bash
flutter analyze
```

### Ejecutar tests:
```bash
flutter test
```

---

## ✅ Checklist de Verificación Final

- [ ] Firebase se inicializa correctamente
- [ ] Usuario anónimo se crea automáticamente
- [ ] Las tareas nuevas se sincronizan a Firestore
- [ ] Las actualizaciones se sincronizan (debounced)
- [ ] Las eliminaciones se reflejan en Firestore
- [ ] El modo offline guarda localmente
- [ ] La cola de sincronización procesa tareas pendientes
- [ ] Los logs muestran información clara
- [ ] No hay errores en `flutter analyze`
- [ ] Los tests pasan correctamente

---

## 📝 Notas

- Los logs usan emojis para facilitar la lectura:
  - ✅ = Operación exitosa
  - ⚠️ = Advertencia
  - ❌ = Error
  - 🔄 = Sincronización en progreso
  - ➕ = Agregar
  - 👤 = Usuario
  - ⏱️ = Debouncing
  - 📦 = Batch sync

- La sincronización es **asíncrona**, puede tardar unos segundos
- El debouncing agrupa cambios para reducir escrituras a Firestore
- Las tareas se guardan localmente primero (optimistic UI)

---

## 🎯 Resultado Esperado

Si todo funciona correctamente, deberías poder:

1. ✅ Crear tareas sin conexión
2. ✅ Ver tareas sincronizadas en Firestore
3. ✅ Actualizar tareas y ver los cambios reflejados
4. ✅ Eliminar tareas y verificar en la nube
5. ✅ Trabajar offline y sincronizar cuando vuelva la conexión
6. ✅ Ver logs claros de todas las operaciones

**¡La sincronización está funcionando! 🎉**
