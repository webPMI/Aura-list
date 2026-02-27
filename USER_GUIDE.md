# Guía de Usuario de AuraList - Nuevas Funcionalidades

**Versión 2.0 - Actualización de Productividad**

¡Bienvenido a la nueva versión de AuraList! Esta guía te ayudará a aprovechar al máximo las tres nuevas funcionalidades diseñadas para mejorar tu productividad y organización.

---

## Tabla de Contenidos

1. [Posponer Tareas (Smart Snooze)](#1-posponer-tareas-smart-snooze)
2. [Plantillas de Tareas](#2-plantillas-de-tareas)
3. [Notificaciones de Fechas Límite](#3-notificaciones-de-fechas-límite)

---

## 1. Posponer Tareas (Smart Snooze)

### ¿Qué es posponer una tarea?

La función de posposición te permite ocultar temporalmente una tarea hasta una fecha y hora específica. Es perfecta para cuando quieres enfocarte en otras prioridades sin perder de vista tareas que harás más tarde.

### Cómo posponer una tarea

**Método 1: Menú rápido**
1. Mantén presionada cualquier tarea en tu lista
2. Selecciona "⏰ Edición rápida"
3. Toca "Posponer tarea"
4. Elige una de las opciones rápidas:
   - **Más tarde hoy** - 4 horas después
   - **Esta noche** - 8:00 PM del mismo día
   - **Mañana** - 9:00 AM del día siguiente
   - **Próximo lunes** - 9:00 AM del siguiente lunes
   - **Próxima semana** - 7 días después
   - **Elegir fecha...** - Selecciona fecha y hora personalizada

### Visualizar tareas pospuestas

Todas tus tareas pospuestas aparecen en un widget especial en el Dashboard:

```
┌──────────────────────────────────────┐
│  Tareas Pospuestas (5)               │
├──────────────────────────────────────┤
│  📅 Hoy                              │
│  ○ Revisar correos - 3:00 PM        │
│                                      │
│  📅 Mañana                           │
│  ○ Llamar al banco - 9:00 AM        │
│  ○ Reunión con equipo - 2:00 PM     │
└──────────────────────────────────────┘
```

Las tareas se agrupan por:
- **Hoy** - Tareas que reaparecerán hoy
- **Mañana** - Tareas para mañana
- **Esta semana** - Tareas en los próximos 7 días
- **Más tarde** - Tareas después de 7 días

### Cancelar una posposición

**Opción 1: Desde el widget de tareas pospuestas**
1. Toca la tarea pospuesta
2. Selecciona "Quitar posposición"
3. La tarea volverá a aparecer en tu lista principal

**Opción 2: Desde edición rápida**
1. Si la tarea está visible, mantén presionada
2. En edición rápida, toca "Quitar posposición"

### Comportamiento automático

- **Reaparición automática**: Cuando llega la fecha/hora programada, la tarea automáticamente vuelve a tu lista principal
- **Sincronización**: Las posposiciones se sincronizan con Firebase, por lo que funcionan en todos tus dispositivos

### Casos de uso comunes

✅ **Durante el día ocupado**: Pospón tareas no urgentes para "Esta noche" y enfócate en prioridades
✅ **Planificación semanal**: Pospón tareas del lunes para "Próximo lunes" durante la revisión dominical
✅ **Gestión de energía**: Pospón tareas exigentes para cuando tengas más energía
✅ **Evitar abrumación**: Si tienes muchas tareas, pospón algunas para distribuir la carga

---

## 2. Plantillas de Tareas

### ¿Qué son las plantillas?

Las plantillas son configuraciones guardadas de tareas que creas frecuentemente. En lugar de llenar todos los campos cada vez, aplica una plantilla y la tarea se crea instantáneamente con toda la información predefinida.

### Crear una plantilla desde cero

1. Abre el menú de navegación
2. Toca "Plantillas de Tareas"
3. Toca el botón flotante "+" (Nueva Plantilla)
4. Completa el formulario:
   - **Nombre de plantilla** *(requerido)* - Ej: "Compra semanal"
   - **Descripción** *(opcional)* - Ej: "Compra de supermercado semanal"
   - **Título de tarea** *(requerido)* - Ej: "Hacer compra del supermercado"
   - **Tipo de tarea** - Diaria, Semanal, Mensual, Anual, Única
   - **Categoría** - Personal, Trabajo, Hogar, Salud, Otros
   - **Prioridad** - Baja, Media, Alta
   - **Hora** *(opcional)* - Ej: 10:00 AM
   - **Motivación** *(opcional)* - Ej: "Para tener comida fresca toda la semana"
   - **Recompensa** *(opcional)* - Ej: "Cocinar mi platillo favorito"
   - **Impacto Financiero** *(opcional)* - Gasto/Ingreso estimado
5. Toca "Guardar Plantilla"

### Guardar una tarea completada como plantilla

Cuando completas una tarea útil, AuraList ocasionalmente te preguntará:

```
┌──────────────────────────────────────┐
│  ¿Guardar como plantilla?            │
│                                      │
│  Esta tarea parece útil. ¿Quieres   │
│  guardarla como plantilla para       │
│  reutilizarla?                       │
│                                      │
│  [Cancelar]  [Guardar como plantilla]│
└──────────────────────────────────────┘
```

1. Toca "Guardar como plantilla"
2. Ingresa el nombre de la plantilla
3. Opcionalmente, añade una descripción
4. Toca "Guardar"

**Nota**: Este diálogo aparece solo para tareas con información útil (motivación, recompensa, hora específica o impacto financiero) y solo aproximadamente 1 de cada 3 veces para no ser intrusivo.

### Usar una plantilla

**Desde el diálogo de crear tarea:**
1. Toca el botón "+" para crear una nueva tarea
2. En la parte superior del formulario, toca "Usar Plantilla"
3. Aparecerá una lista de tus plantillas:
   - Las plantillas ancladas aparecen primero (con ⭐)
   - Luego las más usadas
   - Finalmente las más recientes
4. Toca la plantilla que deseas usar
5. El formulario se llenará automáticamente
6. Modifica lo que necesites
7. Toca "Crear Tarea"

### Gestionar plantillas

**Anclar una plantilla favorita:**
- En la pantalla de Plantillas, toca el ícono de estrella (⭐) en una plantilla
- Las plantillas ancladas aparecen primero en todas las listas

**Editar una plantilla:**
1. En la pantalla de Plantillas, toca el ícono de lápiz (✏️)
2. Modifica los campos necesarios
3. Toca "Guardar Cambios"

**Eliminar una plantilla:**
1. En la pantalla de Plantillas, toca el ícono de basura (🗑️)
2. Confirma la eliminación

**Buscar plantillas:**
- Usa la barra de búsqueda en la parte superior
- Busca por nombre, descripción, título de tarea o categoría

### Contador de uso

Cada plantilla muestra cuántas veces se ha usado. Esto te ayuda a:
- Identificar tus plantillas más valiosas
- Decidir cuáles anclar
- Ver patrones en tus tareas repetitivas

### Casos de uso comunes

✅ **Rutinas de trabajo**: Plantillas para "Revisión matutina de emails", "Standup diario", "Reporte semanal"
✅ **Tareas del hogar**: "Limpieza profunda", "Compra semanal", "Pago de servicios"
✅ **Autocuidado**: "Sesión de ejercicio", "Meditación", "Revisar presupuesto"
✅ **Proyectos recurrentes**: "Preparar presentación", "Revisar métricas", "Actualizar documentación"

---

## 3. Notificaciones de Fechas Límite

### ¿Qué son las notificaciones de fecha límite?

AuraList ahora puede enviarte notificaciones locales cuando se acercan las fechas límite de tus tareas. El sistema usa 4 niveles de urgencia para ayudarte a priorizar.

### Activar las notificaciones

**Primera vez:**
1. Abre el menú de navegación
2. Toca "Configuración"
3. Toca "Notificaciones de Fechas Límite"
4. Activa el interruptor principal
5. AuraList pedirá permiso para enviar notificaciones
6. Toca "Permitir" en el diálogo del sistema

### Niveles de urgencia

Las notificaciones cambian según qué tan cerca está la fecha límite:

#### 📅 Normal (7 días antes)
```
Notificación:
📅 Fecha límite en 1 semana
Preparar presentación trimestral
Vence el 3 de marzo
```

#### ⏰ Alta (1 día antes)
```
Notificación:
⏰ Fecha límite mañana
Entregar reporte mensual
Vence mañana a las 5:00 PM
```

#### ⚠️ Urgente (día de vencimiento)
```
Notificación:
⚠️ ¡Fecha límite HOY!
Pagar tarjeta de crédito
Vence hoy a las 11:59 PM
```

#### 🚨 Crítico (vencido)
```
Notificación:
🚨 ¡Fecha límite vencida!
Renovar licencia de conducir
Venció hace 2 días
```

### Banner de tareas vencidas

Cuando tienes tareas vencidas, aparece un banner rojo en la parte superior del Dashboard:

```
┌──────────────────────────────────────┐
│  🚨  3 tareas vencidas               │
├──────────────────────────────────────┤
│  • Pagar seguro del auto             │
│  • Enviar factura a cliente          │
│  • Agendar cita médica               │
│  + 2 más...                          │
└──────────────────────────────────────┘
```

Toca el banner para ver la lista completa de tareas vencidas.

### Configurar horarios de silencio

Los horarios de silencio evitan que recibas notificaciones durante períodos específicos (por ejemplo, mientras duermes):

1. Ve a Configuración → Notificaciones
2. Toca "Horario de Silencio"
3. Configura:
   - **Hora de inicio** (predeterminado: 10:00 PM)
   - **Hora de fin** (predeterminado: 8:00 AM)
4. Toca "Guardar"

**Comportamiento:**
- Las notificaciones programadas durante el horario de silencio se posponen automáticamente hasta la hora de fin
- Por ejemplo: Si una notificación debería aparecer a las 11:00 PM, aparecerá a las 8:00 AM del día siguiente

### Personalizar la escalación

La escalación controla **cuándo** recibes notificaciones antes de la fecha límite:

1. Ve a Configuración → Notificaciones
2. Toca "Días de Escalación"
3. Selecciona los días que deseas ser notificado antes de la fecha límite:
   - ☐ 30 días antes
   - ☐ 14 días antes
   - ☑ 7 días antes *(predeterminado)*
   - ☐ 3 días antes
   - ☐ 2 días antes
   - ☑ 1 día antes *(predeterminado)*
   - ☑ Día de vencimiento *(predeterminado)*
4. Toca "Guardar"

**Ejemplo:**
Si seleccionas "7 días, 1 día, 0 días" y tienes una tarea que vence el 15 de marzo:
- 8 de marzo: 📅 Notificación "en 1 semana"
- 14 de marzo: ⏰ Notificación "mañana"
- 15 de marzo: ⚠️ Notificación "HOY"
- 16 de marzo (si no completada): 🚨 Notificación "vencida"

### Filtro de prioridad

Si solo quieres notificaciones para tareas importantes:

1. Ve a Configuración → Notificaciones
2. Activa "Solo alta prioridad"
3. Ahora solo recibirás notificaciones de tareas marcadas con prioridad "Alta"

### Sonido y vibración

Personaliza cómo se presentan las notificaciones:

1. Ve a Configuración → Notificaciones
2. **Sonido**: Activa/desactiva el sonido de notificación
3. **Vibración**: Activa/desactiva la vibración

### Compatibilidad con plataformas

Las notificaciones funcionan en:
- ✅ **Android** (API 26+, Android 8.0 o superior)
  - En Android 13+, necesitarás dar permiso explícito
  - Soporta notificaciones exactas (puntales)
- ✅ **iOS** (iOS 10+)
  - Las notificaciones aparecen en el Centro de Notificaciones
  - Soporta badges y sonidos
- ✅ **Windows** (Windows 10+)
  - Notificaciones nativas del sistema
  - Aparecen en el Centro de Acciones
- ✅ **Linux** y **macOS**
  - Notificaciones del sistema operativo

### Casos de uso comunes

✅ **Gestión de facturas**: Establece fechas límite para pagos y recibe notificaciones 7 días y 1 día antes
✅ **Proyectos laborales**: Deadlines de entregas con escalación 14→7→1 día
✅ **Eventos importantes**: Renovaciones, citas médicas, eventos con notificación el día de
✅ **Hábitos diarios**: Tareas diarias con notificaciones de "vencido" si las olvidas

### Privacidad

**Todas las notificaciones son locales:**
- No se envían datos a servidores externos
- No se comparte información con terceros
- Las notificaciones se procesan completamente en tu dispositivo
- Tus datos de tareas nunca salen de tu control

---

## Consejos de Productividad

### Combinar las tres funcionalidades

**Flujo de trabajo recomendado:**

1. **Crear con plantillas** → Usa plantillas para crear tareas recurrentes rápidamente
2. **Establecer fechas límite** → Añade fechas límite para tareas importantes
3. **Posponer si es necesario** → Si surge algo urgente, pospón tareas no críticas
4. **Recibir notificaciones** → Mantente al tanto de deadlines sin revisar constantemente la app

**Ejemplo de un día típico:**

```
8:00 AM - Revisas notificaciones: "⚠️ Entregar reporte HOY"
8:30 AM - Usas plantilla "Reporte semanal" para crear la tarea rápidamente
9:00 AM - Surge reunión urgente, pospones "Revisar emails" para "Esta noche"
2:00 PM - Completas el reporte antes del deadline
8:00 PM - La tarea pospuesta reaparece automáticamente
8:30 PM - Completas "Revisar emails"
9:00 PM - AuraList te pregunta si quieres guardar "Revisar emails" como plantilla
```

### Mejores prácticas

**Para posposición:**
- ❌ No pospongas indefinidamente - Usa fechas límite para tareas pospuestas
- ✅ Pospón estratégicamente según tu energía del día
- ✅ Revisa el widget de tareas pospuestas diariamente

**Para plantillas:**
- ❌ No crees plantillas para tareas únicas - Solo para recurrentes
- ✅ Revisa y actualiza plantillas regularmente
- ✅ Ancla tus 3-5 plantillas más usadas

**Para notificaciones:**
- ❌ No actives todas las escalaciones - Recibirás demasiadas notificaciones
- ✅ Empieza con escalación simple (7 días, 1 día, día de)
- ✅ Ajusta según tu ritmo de trabajo

---

## Preguntas Frecuentes

**P: ¿Las tareas pospuestas cuentan para mi racha?**
R: Sí, las tareas pospuestas siguen contando. Solo están temporalmente ocultas.

**P: ¿Puedo exportar mis plantillas?**
R: Actualmente no, pero se sincronización con Firebase automáticamente entre dispositivos.

**P: ¿Las notificaciones consumen batería?**
R: No. AuraList usa el sistema de notificaciones nativo que es muy eficiente.

**P: ¿Puedo posponer una tarea recurrente sin afectar las futuras recurrencias?**
R: Sí, posponer solo afecta la instancia actual de la tarea.

**P: ¿Las plantillas incluyen el impacto financiero?**
R: Sí, todos los campos de la tarea se guardan en la plantilla, incluyendo costos y beneficios.

**P: ¿Qué pasa si no doy permiso para notificaciones?**
R: La app funciona perfectamente sin notificaciones. Solo no recibirás recordatorios automáticos.

**P: ¿Las notificaciones funcionan sin internet?**
R: Sí, son completamente locales y no requieren conexión.

---

## Solución de Problemas

### Las notificaciones no aparecen

1. **Verifica permisos:**
   - Android: Configuración del sistema → Apps → AuraList → Notificaciones → Activado
   - iOS: Ajustes → Notificaciones → AuraList → Permitir Notificaciones

2. **Verifica configuración de la app:**
   - Ve a Configuración → Notificaciones
   - Asegúrate de que el interruptor principal esté activado
   - Verifica que no estés en horario de silencio

3. **Verifica que la tarea tenga fecha límite:**
   - Solo las tareas con fecha límite generan notificaciones
   - Edita la tarea y añade una fecha límite

### Las tareas pospuestas no reaparecen

1. **Espera a que pase el tiempo programado:**
   - Las tareas reaparecen automáticamente cuando llega la fecha/hora

2. **Refresca la app:**
   - Cierra y vuelve a abrir AuraList
   - O cambia de pantalla y regresa al Dashboard

3. **Verifica en el widget de pospuestas:**
   - La tarea debería estar en el widget "Tareas Pospuestas"

### Las plantillas no se sincronizan

1. **Verifica conexión a internet:**
   - Las plantillas requieren Firebase para sincronizar

2. **Verifica autenticación:**
   - Asegúrate de estar conectado con tu cuenta

3. **Sincronización manual:**
   - Cierra y vuelve a abrir la app para forzar sincronización

---

## Actualizaciones Futuras

Estamos trabajando en más funcionalidades:
- 🔜 Compartir plantillas con otros usuarios
- 🔜 Estadísticas de uso de plantillas
- 🔜 Posposición inteligente basada en patrones
- 🔜 Notificaciones basadas en ubicación
- 🔜 Integración con calendario

---

**¿Necesitas más ayuda?**

- Documentación técnica: Ver `FEATURES.md`
- Guía de testing: Ver `TESTING_GUIDE.md`
- Reportar problemas: [GitHub Issues](https://github.com/tu-usuario/auralist/issues)

---

*Guía de Usuario de AuraList v2.0*
*Última actualización: Febrero 2026*
