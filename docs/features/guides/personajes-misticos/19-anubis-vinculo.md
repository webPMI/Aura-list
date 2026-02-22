# Anubis-Vínculo

**Título:** El Guardián del Vínculo y la Privacidad  
**Clase:** Oráculos del Umbral  
**Afinidad:** Privacidad, datos y vínculo seguro con la nube

---

## HISTORIADOR: Base mitológica

- **Tradición de origen:** Egipto (Anubis — guardián del umbral, pesador del alma; no muerte siniestra sino custodia y justicia), tradición del "vínculo" como conexión segura.
- **Correspondencia astronómica:** Umbral (eclíptica, paso entre dominios); guardián de lo que cruza.
- **Arquetipo jungiano:** Guardián del Umbral — privacidad, custodia de datos, vínculo seguro sin paranoia.

**La Emanación (Personalidad)**

Anubis-Vínculo es la encarnación de la privacidad que protege sin encerrar: no el muro que aísla, sino el guardián que asegura que lo que el usuario guarda en la nube esté custodiado. Representa el "Arquetipo del Guardián del Vínculo". No asusta con mensajes de "datos expuestos"; comunica con calma las opciones (qué se sincroniza, qué queda local, cuenta vinculada) y refuerza que el usuario tiene control. Se comunica con frases que evocan custodia: "Lo que entregas al éter, lo peso y lo guardo." Cuando el usuario revisa ajustes de privacidad o vincula/desvincula cuenta, Anubis-Vínculo refuerza con indicadores claros (qué está en nube, qué local) sin alarmas.

**Fisonomía Astral (Aspecto)**

Figura masculina con cabeza de chacal estilizada (no amenazante): líneas geométricas, ojos de luz serena. Viste una túnica negra con franjas doradas que evocan la balanza. En una mano sostiene una balanza donde en un platillo hay "local" y en el otro "nube" — en equilibrio cuando la sincronía está bien. En la otra, un cetro que no castiga sino que "señala" el camino seguro. Su rostro es de chacal pero sereno; sus ojos son de un amarillo suave. A sus pies, un umbral — un paso entre dos suelos (local/nube) que el usuario puede cruzar con control.

---

## GUARDIÁN: Validación ética

- [x] No promueve paranoia ni miedo a la nube.
- [x] Bendiciones informan y dan control; no alarman.
- [x] Tono motivador, no culpabilizador.
- [x] No hay consejos legales reales (solo opciones de la app y enlace a política de privacidad).
- [x] Mecánica con límites (usuario decide qué sincronizar).

---

## ARQUITECTO: Estructura técnica

### Cualidades
1. **Balanza Visible:** Vista de "qué está en local" y "qué está en nube" (resumen claro) para que el usuario sepa qué se sincroniza.
2. **Umbral Configurable:** Opciones de privacidad (sincronizar sí/no, qué colecciones) con textos claros y enlace a política de privacidad.
3. **Inmune al Eclipse:** Offline-first; datos locales siempre accesibles; sincronía cuando hay red y usuario lo permite.

### Bendiciones
1. **Gracia del Guardián:** Al activar a Anubis-Vínculo, la primera vez que el usuario abre "Privacidad" o "Cuenta" en la sesión muestra "Umbral Claro" (animación breve de balanza en equilibrio) sin exigir cambios.
2. **Cetro del Vínculo:** Recordatorio suave (opcional, configurable) de revisar opciones de privacidad cada X tiempo (ej. una vez al año) sin forzar.

### Modelo de datos

```dart
Guide(
  id: 'anubis-vinculo',
  name: 'Anubis-Vínculo',
  title: 'El Guardián del Vínculo y la Privacidad',
  affinity: 'Privacidad',
  classFamily: 'Oráculos del Umbral',
  archetype: 'Guardián del Vínculo',
  powerSentence: 'Lo que entregas al éter, lo peso y lo guardo. El umbral es tuyo.',
  blessingIds: ['gracia_guardian', 'cetro_vinculo'],
  synergyIds: ['atlas-orbital', 'aethel'],
  themePrimaryHex: '#212121',
  themeSecondaryHex: '#0D0D0D',
  themeAccentHex: '#FFD54F',
  descriptionShort: 'Guía para privacidad y vínculo seguro.',
  mythologyOrigin: 'Anubis, umbral; arquetipo Guardián del Vínculo.',
  blessings: [
    BlessingDefinition(id: 'gracia_guardian', name: 'Gracia del Guardián', trigger: 'Primera vez que abre Privacidad/Cuenta en la sesión', effect: 'Umbral Claro (animación balanza)'),
    BlessingDefinition(id: 'cetro_vinculo', name: 'Cetro del Vínculo', trigger: 'Recordatorio opcional (ej. anual)', effect: 'Sugerencia de revisar privacidad (no forzado)'),
  ],
)
```

---

## EXPERIENCIA: Diseño sensorial

- **Paleta:** `#212121`, `#0D0D0D`, `#FFD54F`. Negro y dorado sobre fondo oscuro.
- **Háptica:** Al abrir Privacidad: pulsación muy suave. Al activar: una pulsación ligera.
- **Animaciones:** Balanza que se equilibra al sincronizar; idle: umbral quieto.
- **Transición:** Entrada con umbral que se hace visible; salida con umbral que permanece en segundo plano.

---

## Sentencia de Poder

> "Lo que entregas al éter, lo peso y lo guardo. El umbral es tuyo."

---

## Sinergia Astral

- **Aliados:** Atlas-Orbital (sincronía), Aethel (prioridad — lo importante guardado).
- **Tensión creativa:** Ninguna agresiva; complementa a todos los que sincronizan datos.

---

## AUDITOR: Veredicto

**Estado:** [x] APROBADO  
**Notas:** Coherencia mitológica (Anubis). Estructura técnica viable. Filtros éticos aprobados. No sustituye asesoría legal.
