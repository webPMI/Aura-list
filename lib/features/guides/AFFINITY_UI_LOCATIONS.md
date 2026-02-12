# Ubicaciones del Sistema de Afinidad en la UI

## Resumen Visual

El sistema de afinidad aparece en 3 ubicaciones principales de la aplicación:

## 1. Dashboard - UserCard

**Archivo**: `lib/widgets/dashboard/user_card.dart`

**Ubicación**:
- Card superior del dashboard
- Debajo del avatar del guía activo
- Lado derecho de la card

**Apariencia**:
```
┌─────────────────────────────────────────┐
│ [Avatar User]  Usuario              [?] │
│                Correo@email.com         │
│                                         │
│                    [Avatar Guía]        │
│                    ★★★☆☆              │  ← Estrellas de afinidad
│                                    [→]  │
└─────────────────────────────────────────┘
```

**Tamaño**: Small (8px por estrella)
**Interacción**: Tap en avatar → Abre diálogo de detalles completos

**Código**:
```dart
AffinityLevelIndicator(
  guide: guide,
  size: AffinityIndicatorSize.small,
  showLabel: false,
  showProgress: false,
)
```

---

## 2. Guide Selector Sheet

**Archivo**: `lib/features/guides/widgets/guide_selector_sheet.dart`

**Ubicación**:
- Bottom sheet al tocar "Elegir guía"
- En cada tile de guía
- Entre el título/descripción y el avatar

**Apariencia**:
```
┌─────────────────────────────────────────┐
│        Elige tu guía celestial      [ℹ] │
│─────────────────────────────────────────│
│ > Cónclave del Ímpetu              (3)  │
│─────────────────────────────────────────│
│  [Avatar]  Aethel                   [✓] │
│            El Primer Pulso • Prioridad  │
│            ★★★★☆  ← Estrellas           │
│            Guía de acción...            │
│─────────────────────────────────────────│
│  [Avatar]  Helioforja               [ ] │
│            Forjador del Alba • Esfuerzo │
│            ★★☆☆☆  ← Estrellas           │
│            Guía de disciplina...        │
└─────────────────────────────────────────┘
```

**Tamaño**: Small (14px por estrella)
**Interacción**: Visual solamente, no interactivo
**Código**:
```dart
AffinityLevelIndicator(
  guide: guide,
  size: AffinityIndicatorSize.small,
  showLabel: false,
  showProgress: false,
)
```

---

## 3. Affinity Details Dialog

**Archivo**: `lib/features/guides/widgets/affinity_level_indicator.dart`
**Función**: `showAffinityDetailsDialog(context, guide, affinity)`

**Ubicación**:
- Modal que aparece al tocar el avatar del guía en dashboard
- Pantalla completa con scroll

**Apariencia**:
```
┌─────────────────────────────────────────┐
│  ★ Afinidad con Aethel             [X]  │
│─────────────────────────────────────────│
│  ┌───────────────────────────────────┐  │
│  │ ★★★★☆              Vínculo       │  │
│  │ Un vínculo profundo se ha formado│  │
│  │                                   │  │
│  │ ✓ Tareas completadas: 52         │  │
│  │ 📅 Días juntos: 15                │  │
│  │                                   │  │
│  │ Siguiente nivel          76%     │  │
│  │ ████████████████░░░░░░           │  │ ← Barra progreso
│  │ Necesitas 100 tareas y 30 días   │  │
│  └───────────────────────────────────┘  │
│                                         │
│  Sistema de Desbloqueos                 │
│  ✓ Avatar Coloreado (Nivel 1)          │
│    El avatar del guía a color           │
│  ✓ Sentencia de Poder (Nivel 2)        │
│    Frase icónica en dashboard           │
│  ✓ Diálogos Especiales (Nivel 3)       │
│    Mensajes exclusivos                  │
│  ✓ Bendiciones Mejoradas (Nivel 4)     │  ← Nivel actual
│    Mayor frecuencia                     │
│  🔒 Ritual Diario (Nivel 5)             │  ← Bloqueado
│    Ritual de sincronización             │
│                                         │
│                              [Cerrar]   │
└─────────────────────────────────────────┘
```

**Tamaño**: Large (24px por estrella)
**Interacción**: Scroll, botón cerrar
**Código**:
```dart
AffinityLevelIndicator(
  guide: guide,
  size: AffinityIndicatorSize.large,
  showLabel: true,
  showProgress: true,
)
```

---

## 4. Level Up Notification

**Archivo**: `lib/widgets/task_tile.dart` (método `_incrementGuideAffinity`)

**Ubicación**:
- SnackBar que aparece al completar tarea
- Parte inferior de la pantalla
- Solo si el usuario sube de nivel

**Apariencia**:
```
                ┌─────────────────────────────────┐
                │ ★ ¡Aliado! Una relación de    │
                │   confianza mutua.             │  ← Fondo dorado
                └─────────────────────────────────┘
                        (Desaparece en 4s)
```

**Colores**:
- Background: `Colors.amber.shade700`
- Texto: `Colors.white`
- Icono: `Icons.stars`

**Duración**: 4 segundos
**Comportamiento**: Floating SnackBar

---

## Flujo de Interacción Completo

### Escenario 1: Usuario completa primera tarea con guía nuevo

1. **Usuario completa tarea** → TaskTile detecta
2. **Sistema incrementa contador** → De 0 a 1 tarea
3. **No hay subida de nivel** → Sin notificación (necesita 5 tareas)
4. **Estrellas en dashboard** → Siguen en ☆☆☆☆☆ (nivel 0)

### Escenario 2: Usuario alcanza nivel 1 (5 tareas + 1 día)

1. **Usuario completa 5ta tarea**
2. **Sistema detecta requisitos cumplidos**
3. **SnackBar aparece** → "¡Conocido! El guía comienza a conocerte"
4. **Estrellas actualizan** → ★☆☆☆☆ en dashboard y selector
5. **Avatar cambia** → Se colorea con tema del guía

### Escenario 3: Usuario verifica progreso

1. **Usuario toca avatar del guía** en dashboard
2. **Diálogo abre** con información completa
3. **Usuario ve**:
   - Nivel actual con estrellas
   - Tareas completadas: X
   - Días juntos: Y
   - Progreso a siguiente nivel: Z%
   - Lista de desbloqueos
4. **Usuario cierra** y continúa

---

## Tamaños y Configuraciones

### AffinityIndicatorSize.small
- **Icono**: 14px
- **Progreso**: 3px altura, 60px ancho
- **Uso**: Compacto, listas

### AffinityIndicatorSize.medium
- **Icono**: 18px
- **Progreso**: 4px altura, 100px ancho
- **Uso**: Dashboard, cards

### AffinityIndicatorSize.large
- **Icono**: 24px
- **Progreso**: 6px altura, 200px ancho
- **Uso**: Diálogos, detalles

---

## Estados Visuales

### Sin Guía Activo
```
Dashboard: Icono genérico (auto_awesome) sin estrellas
Selector: Todos los guías muestran su nivel
```

### Guía Activo - Nivel 0
```
Estrellas: ☆☆☆☆☆ (todas vacías)
Color: theme.colorScheme.outline (gris)
```

### Guía Activo - Nivel 3
```
Estrellas: ★★★☆☆ (3 llenas, 2 vacías)
Color: guideColor (acento del guía)
Barra: 60% (ejemplo)
```

### Guía Activo - Nivel 5 (Máximo)
```
Estrellas: ★★★★★ (todas llenas)
Color: guideColor brillante
Etiqueta: "Alma Gemela"
Mensaje: "Nivel máximo alcanzado" + icono trofeo
```

---

## Animaciones

### Al Subir de Nivel
```
Scale: 1.0 → 1.3 → 1.0
Duration: 600ms
Curve: easeOutBack → easeIn
```

### Barra de Progreso
```
Transition: Linear
Color: guideColor
Background: surfaceContainerHighest
```

### SnackBar
```
Entrada: Slide up + fade in
Salida: Fade out después de 4s
Behavior: Floating
```

---

## Colores del Guía

Cada guía tiene su color de acento que se usa en:
- Estrellas llenas
- Barra de progreso
- Border del diálogo
- Background del mensaje de nivel

**Obtención**:
```dart
final guideColor = parseHexColor(
  guide.themeAccentHex ?? guide.themePrimaryHex
) ?? Theme.of(context).colorScheme.primary;
```

---

## Accesibilidad

Todos los indicadores incluyen:
- **Semantics labels**: Descripción verbal del nivel
- **Tooltips**: Información al hover
- **Contrast**: Colores accesibles con el fondo
- **Tap targets**: Mínimo 48x48px para interacciones

---

## Notas de Implementación

1. **Todos los widgets son reactivos**: Usan `ConsumerWidget` o `Consumer`
2. **Loading states**: Manejo de async con `.when()`
3. **Error handling**: Fallback a valores por defecto
4. **Performance**: Solo se recalcula cuando cambia el estado
5. **Persistencia**: Automática en cada cambio

---

## Testing Checklist

- [ ] Estrellas aparecen en dashboard con guía activo
- [ ] Estrellas actualizan al completar tareas
- [ ] SnackBar aparece al subir de nivel
- [ ] Diálogo muestra información correcta
- [ ] Progreso calcula correctamente
- [ ] Persistencia funciona (cerrar/abrir app)
- [ ] Cambiar guía mantiene afinidades separadas
- [ ] Animación de nivel funciona
- [ ] Colores del guía se aplican correctamente
- [ ] Accesibilidad funciona (screen reader)
