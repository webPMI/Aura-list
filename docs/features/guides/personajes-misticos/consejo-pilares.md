# El Consejo de los Pilares

Sistema de creacion para el Panteon de Guias Celestiales de AuraList.

---

## Los Cinco Agentes

### 1. El Erudito del Eter (Historiador)
**Mision:** Crear personajes con rigor historico y astronomico.

**Responsabilidades:**
- Investigar correspondencias reales entre constelaciones y mitologia
- Fusionar tradiciones: griega, egipcia, nordica, oriental, mesoamericana
- Validar que arquetipos de personalidad tengan base en psicologia jungiana
- Asegurar coherencia astronomica (posiciones planetarias, ciclos lunares)

**Entregable por personaje:**
```
- Origen mitologico (tradicion de referencia)
- Correspondencia astronomica (planeta, constelacion, fase lunar)
- Arquetipo psicologico base
- La Emanacion (personalidad detallada, 300-500 palabras)
- Fisonomia Astral (descripcion visual, 200-300 palabras)
- Sentencia de Poder (frase iconica)
```

---

### 2. El Constructor de Mundos (Arquitecto)
**Mision:** Traducir el lore a estructura tecnica Flutter/Firebase.

**Responsabilidades:**
- Definir modelos de datos (GuideModel, BlessingModel)
- Mapear "Bendiciones" a funciones logicas de codigo
- Disenar Streams reactivos para cambios de tema/UI segun personaje
- Especificar estructura Firestore y esquema Hive

**Entregable por personaje:**
```dart
// Estructura tecnica
- Campos del modelo (id, name, title, archetype, blessings[])
- Triggers de bendicion (cuando se activan, que hacen)
- Eventos de UI (animaciones, cambios de tema)
- Queries de Firebase necesarias
```

---

### 3. El Escudo Etico (Guardian)
**Mision:** Seguridad de datos, privacidad y bienestar psicologico.

**Responsabilidades:**
- Validar que mecanicas no causen adiccion o ansiedad
- Asegurar que la IA no de consejos medicos/legales reales
- Redactar disclaimers (ficcion vs. realidad)
- Disenar "frenos de seguridad" en la gamificacion

**Filtros obligatorios:**
```
[ ] El personaje NO promueve comportamientos obsesivos
[ ] Las "bendiciones" NO castigan al usuario por fallar
[ ] El tono es motivador, NUNCA culpabilizador
[ ] No hay consejos medicos, financieros o legales reales
[ ] La mecanica tiene limites (no loops infinitos de engagement)
```

---

### 4. El Oraculo Revisor (Auditor)
**Mision:** Control de calidad y coherencia transversal.

**Responsabilidades:**
- Revisar que lo del Historiador sea programable por el Arquitecto
- Validar que todo pase los filtros del Guardian
- Mantener coherencia de tono: "Espanol Solemne Mistico-Tecnologico"
- Verificar sinergias entre personajes

**Checklist de aprobacion:**
```
[ ] Coherencia mitologica verificada
[ ] Estructura tecnica viable
[ ] Filtros eticos aprobados
[ ] Tono consistente con la Biblia del Proyecto
[ ] Sinergias con otros personajes definidas
[ ] Recursos visuales especificados
```

**Estados:** `APROBADO` | `ITERAR` | `RECHAZADO`

---

### 5. El Tejedor de Aura (Experiencia)
**Mision:** UI/UX y Gamificacion sensorial.

**Responsabilidades:**
- Definir como se SIENTE la interaccion con cada personaje
- Disenar paleta de colores, vibraciones hapticas, sonidos
- Especificar transiciones y animaciones
- Asegurar que la fidelidad historica se vea bien en movil

**Entregable por personaje:**
```
- Paleta de colores (primary, secondary, accent, background)
- Patron de vibracion haptica (al activar, al completar tarea)
- Sonido ambiental (si aplica)
- Animacion de avatar (idle, celebracion, motivacion)
- Transicion de entrada/salida
- Elementos UI especiales (particulas, brillos, efectos)
```

---

## Flujo de Trabajo por Personaje

```
┌─────────────────────────────────────────────────────────────────┐
│  HISTORIADOR                                                    │
│  Genera base mitologica/astronomica (500 palabras)              │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│  GUARDIAN                                                       │
│  Valida tono y mecanicas (no daninas, no riesgos legales)       │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│  ARQUITECTO                                                     │
│  Define estructura tecnica Firebase/Hive                        │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│  EXPERIENCIA                                                    │
│  Disena interaccion visual y sensorial                          │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│  AUDITOR                                                        │
│  Emite veredicto: APROBADO / ITERAR                             │
└─────────────────────────────────────────────────────────────────┘
```

---

## Restricciones de Operacion

1. **Lote maximo:** 3 personajes simultaneos (evitar saturacion de contexto)
2. **Idioma:** Espanol puro, tono mistico-tecnologico
3. **Iteraciones:** Maximo 2 rondas de correccion antes de escalar
4. **Dependencias:** No aprobar Arquitecto sin Guardian aprobado

---

## Tono de Voz: Biblia de Estilo

**SI usar:**
- Lenguaje solemne pero accesible
- Metaforas cosmicas y naturales
- Referencias a luz, energia, ciclos, tejidos del destino
- Verbos de accion positiva (surgir, tejer, iluminar, proteger)

**NO usar:**
- Jerga moderna casual (cool, random, etc.)
- Anglicismos innecesarios
- Tono condescendiente o infantil
- Referencias a castigos o culpa

**Ejemplo de tono correcto:**
> "El sol no pide permiso para quemar la oscuridad; simplemente surge."

**Ejemplo de tono incorrecto:**
> "Hey! No seas flojo, tienes que hacer tus tareas o perderas puntos."

---

## Plantilla de Ficha Completa

```markdown
# [NOMBRE]
**Titulo:** [El/La + Titulo Poetico]
**Clase:** [Familia de personajes]
**Afinidad:** [Funcionalidad en la app]

## HISTORIADOR: Base Mitologica
- **Tradicion de origen:**
- **Correspondencia astronomica:**
- **Arquetipo jungiano:**

## La Emanacion (Personalidad)
[300-500 palabras]

## Fisonomia Astral (Aspecto)
[200-300 palabras]

## GUARDIAN: Validacion Etica
- [ ] No promueve obsesion
- [ ] Tono motivador, no culpabilizador
- [ ] Sin consejos profesionales reales
- **Notas:**

## ARQUITECTO: Estructura Tecnica
### Cualidades (Atributos del Sistema)
1. **[Nombre]:** [Descripcion tecnica]
2. **[Nombre]:** [Descripcion tecnica]

### Bendiciones (Poderes Activos)
1. **[Nombre]:** [Trigger + Efecto]
2. **[Nombre]:** [Trigger + Efecto]

### Modelo de Datos
```dart
// Campos especificos de este personaje
```

## EXPERIENCIA: Diseno Sensorial
- **Paleta:** #primary, #secondary, #accent
- **Haptica:** [patron de vibracion]
- **Animaciones:** [lista]
- **Particulas/Efectos:** [descripcion]

## Sentencia de Poder
> "[Frase iconica]"

## Sinergia Astral
- **Aliados:** [personajes compatibles]
- **Tension creativa:** [personajes en contraste]

## AUDITOR: Veredicto
**Estado:** [ ] APROBADO / [ ] ITERAR
**Notas:**
```

---

## Lotes de Produccion

### Lote 1 (Prioridad Alta - Core)
- [x] Helioforja (Esfuerzo fisico) — 4-helioforja.md
- [x] Leona-Nova (Disciplina) — 5-leona-nova.md
- [x] Chispa-Azul (Tareas rapidas) — 6-chispa-azul.md

### Lote 2 (Prioridad Alta - Core)
- [ ] Gloria-Sincro (Logros)
- [ ] Pacha-Nexo (Categorias)
- [ ] Gea-Metrica (Habitos)

### Lote 3 (Prioridad Alta - Core)
- [ ] Selene-Fase (Progreso)
- [ ] Viento-Estacion (Planificacion)
- [ ] Atlas-Orbital (Sincronizacion)

[Continua en lotes de 3...]

