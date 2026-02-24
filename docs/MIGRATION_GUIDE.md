# Guía de Migración - Sistema de Finanzas

Esta guía describe los cambios necesarios para actualizar a la versión 2.0.0 de AuraList que incluye el sistema de finanzas completo.

## Resumen de Cambios

- Nuevos modelos de datos financieros con Hive TypeIds 14-29
- Extensión del modelo Task con campos financieros (HiveFields 16-23)
- Nuevos servicios de integración tarea-finanzas
- Nuevos providers de Riverpod para gestión financiera

## TypeIds de Hive

Los siguientes TypeIds han sido asignados para el sistema de finanzas:

| TypeId | Modelo/Enum | Descripción |
|--------|-------------|-------------|
| 14 | FinanceCategoryType | Enum: income, expense |
| 15 | FinanceCategory | Categorías de transacciones |
| 16 | Transaction | Transacciones individuales |
| 17 | RecurringTransaction | Transacciones recurrentes |
| 18 | Budget | Presupuestos por categoría |
| 19 | CashFlowProjection | Proyecciones de flujo de efectivo |
| 20 | FinanceAlert | Alertas financieras |
| 22 | RecurrenceFrequency | Enum: daily, weekly, monthly, yearly |
| 23 | BudgetPeriod | Enum: daily, weekly, monthly, quarterly, yearly |
| 24 | TaskFinanceLinkType | Enum: tipos de vinculación tarea-finanzas |
| 25 | AlertType | Enum: tipos de alertas |
| 26 | AlertSeverity | Enum: info, warning, critical |
| 27 | RiskLevel | Enum: low, medium, high, critical |
| 28 | FinancialImpactType | Enum: cost, saving, income |
| 29 | TaskFinanceLink | Vinculación tarea-transacción |

**Nota**: TypeId 21 está reservado para uso futuro.

## Cambios en el Modelo Task

El modelo `Task` (typeId: 0) ha sido extendido con los siguientes campos financieros:

### Nuevos HiveFields

```dart
@HiveField(16)
double? financialCost;              // Costo de realizar la tarea

@HiveField(17)
double? financialBenefit;           // Beneficio de completar la tarea

@HiveField(18)
String? linkedTransactionId;        // ID de transacción generada

@HiveField(19)
String? financialImpactType;        // 'immediate', 'deferred', 'recurring'

@HiveField(20, defaultValue: false)
bool autoGenerateTransaction;       // Si crear transacción automáticamente

@HiveField(21)
String? financialCategoryId;        // Categoría financiera a usar

@HiveField(22)
String? linkedRecurringTransactionId; // ID de transacción recurrente

@HiveField(23)
String? financialNote;              // Nota sobre el impacto financiero
```

### Nuevas Propiedades Calculadas

```dart
bool get hasFinancialImpact => financialCost != null || financialBenefit != null;

double? get netFinancialImpact {
  if (financialCost == null && financialBenefit == null) return null;
  return (financialBenefit ?? 0.0) - (financialCost ?? 0.0);
}

double? get financialROI {
  if (financialCost == null || financialCost == 0 || financialBenefit == null) {
    return null;
  }
  return ((financialBenefit! - financialCost!) / financialCost!) * 100;
}
```

## Compatibilidad con Versiones Anteriores

### Datos Existentes

**Todos los datos existentes permanecen intactos**. Los nuevos campos son opcionales (nullable) y tienen valores por defecto cuando es necesario.

- Las tareas existentes sin campos financieros seguirán funcionando normalmente
- No se requiere migración de datos de Hive
- Los datos en Firestore se actualizarán automáticamente con los nuevos campos en la próxima sincronización

### Migración Automática

El sistema maneja automáticamente:

1. **Hive**: Los campos nuevos son nullable, por lo que tareas existentes funcionan sin cambios
2. **Firestore**: Al leer documentos antiguos, los campos faltantes se manejan con valores por defecto
3. **UI**: Los componentes verifican si los campos financieros existen antes de mostrarlos

## Pasos de Actualización

### 1. Actualizar Dependencias

```bash
cd /path/to/auralist
flutter pub get
```

### 2. Regenerar Adaptadores de Hive

**IMPORTANTE**: Este paso es obligatorio para que Hive reconozca los nuevos modelos.

```bash
dart run build_runner build --delete-conflicting-outputs
```

Esto generará los archivos `.g.dart` necesarios para todos los modelos nuevos y actualizados.

### 3. Verificar la Actualización

Ejecuta la aplicación para verificar que todo funciona correctamente:

```bash
flutter run
```

### 4. Limpiar Caché (Opcional)

Si experimentas problemas después de actualizar, limpia la caché y reconstruye:

```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Cambios en Firebase (Firestore)

### Nuevas Colecciones

El sistema creará automáticamente las siguientes subcolecciones bajo `users/{userId}/`:

- `finance_categories/`: Categorías de finanzas
- `transactions/`: Transacciones individuales
- `recurring_transactions/`: Transacciones recurrentes
- `budgets/`: Presupuestos
- `cash_flow_projections/`: Proyecciones de flujo de efectivo
- `finance_alerts/`: Alertas financieras
- `task_finance_links/`: Vínculos tarea-finanzas

### Actualización de Documentos Existentes

Los documentos de tareas (`tasks/`) se actualizarán automáticamente:

- Al leer una tarea antigua, los campos financieros serán null
- Al actualizar una tarea, se incluirán los campos financieros si fueron modificados
- No se modifican tareas existentes a menos que el usuario las edite

### Seguridad de Firebase (Firestore Rules)

Si personalizaste las reglas de Firestore, asegúrate de permitir acceso a las nuevas colecciones:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      // Permitir acceso a todas las subcolecciones del usuario
      match /{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

## Impacto en el Rendimiento

### Hive (Local)

- Impacto mínimo: Los nuevos campos en Task son opcionales y no afectan queries existentes
- Las nuevas colecciones (transactions, budgets, etc.) están separadas

### Firestore (Cloud)

- Sincronización incremental: Solo se sincronizan datos nuevos o modificados
- Las consultas existentes no se ven afectadas
- Las nuevas consultas financieras son independientes

### Tamaño de la Base de Datos

- **Hive**: Incremento aproximado de 10-20% si usas todas las características financieras
- **Firestore**: Depende del uso, pero típicamente 5-10 documentos nuevos por mes por usuario activo

## Características Nuevas Disponibles

Después de la migración, tendrás acceso a:

1. **Transacciones**: Registro de ingresos y gastos
2. **Categorías**: Clasificación personalizable de transacciones
3. **Transacciones Recurrentes**: Generación automática de transacciones periódicas
4. **Presupuestos**: Límites de gasto con alertas automáticas
5. **Proyecciones**: Previsiones de flujo de efectivo
6. **Alertas**: Notificaciones inteligentes sobre finanzas
7. **Vinculación con Tareas**: Asociar costos/beneficios a tareas

## Uso Opcional

**El sistema de finanzas es completamente opcional**:

- No es necesario usar las características financieras
- La aplicación funciona exactamente igual sin usar finanzas
- Los usuarios pueden empezar a usar finanzas cuando lo deseen
- No hay configuración obligatoria

## Solución de Problemas

### Error: "No adapter found for Task"

**Causa**: Los adaptadores de Hive no fueron regenerados.

**Solución**:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Error: "Bad state: field does not exist"

**Causa**: Intentando acceder a un campo financiero en una tarea antigua.

**Solución**: Usa el operador null-safe (`?.`) o verifica que el campo no sea null:

```dart
// Incorrecto
final cost = task.financialCost.toStringAsFixed(2); // Error si es null

// Correcto
final cost = task.financialCost?.toStringAsFixed(2) ?? 'N/A';
```

### Datos Duplicados en Firestore

**Causa**: La sincronización puede crear duplicados si la migración se ejecuta múltiples veces.

**Solución**:
1. Los duplicados se resolverán automáticamente por timestamp
2. Si persiste, desinstala la app y reinstala para limpiar datos locales

### Sincronización Lenta Después de Actualizar

**Causa**: Primera sincronización completa de datos nuevos.

**Solución**: Es normal. La primera sincronización puede tardar más, luego será incremental.

## Rollback (Deshacer Actualización)

Si necesitas volver a la versión anterior:

### Método 1: Checkout de Git

```bash
git checkout v1.9.0  # O el commit anterior
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### Método 2: Desinstalar y Reinstalar

1. Desinstala la aplicación
2. Checkout a la versión anterior en git
3. Reinstala la aplicación

**Advertencia**: Los datos financieros creados en v2.0.0 no serán accesibles en versiones anteriores, pero las tareas existentes seguirán funcionando.

## Verificación Post-Migración

### Checklist de Verificación

- [ ] La aplicación arranca sin errores
- [ ] Las tareas existentes se muestran correctamente
- [ ] Puedo crear nuevas tareas
- [ ] Puedo completar tareas existentes
- [ ] La sincronización con Firebase funciona (si está habilitada)
- [ ] Puedo acceder a la sección de Finanzas
- [ ] Puedo crear transacciones (si uso finanzas)

### Comandos de Verificación

```bash
# Verificar que los adaptadores fueron generados
ls lib/**/*.g.dart | grep -E "(transaction|budget|finance)"

# Verificar compilación
flutter analyze

# Ejecutar tests
flutter test

# Verificar que la app funciona
flutter run -d chrome  # O el dispositivo que prefieras
```

## Soporte

Si encuentras problemas durante la migración:

1. Revisa esta guía completa
2. Verifica los logs en consola para errores específicos
3. Consulta la documentación completa en `docs/finance-system.md`
4. Abre un issue en GitHub con detalles del error

## Próximos Pasos

Después de migrar exitosamente:

1. Lee la documentación completa: `docs/finance-system.md`
2. Explora las características financieras en la UI
3. Configura categorías y presupuestos personalizados
4. Vincula tareas con impacto financiero
5. Revisa las proyecciones y alertas

---

**Versión de este documento**: 2.0.0
**Última actualización**: Febrero 2026
**Compatibilidad**: AuraList 1.9.x → 2.0.0
