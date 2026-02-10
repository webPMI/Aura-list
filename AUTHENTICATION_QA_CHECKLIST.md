# Checklist de QA - Sistema de Autenticacion AuraList

## Pre-requisitos
- [ ] Flutter SDK instalado y actualizado
- [ ] Firebase configurado correctamente
- [ ] Dependencias instaladas (`flutter pub get`)
- [ ] App compila sin errores (`flutter analyze`)

---

## 1. WelcomeScreen (Primera Apertura)

### Visualizacion
- [ ] Pantalla se muestra en el primer uso de la app
- [ ] Logo de AuraList visible y centrado
- [ ] Titulo "Bienvenido a AuraList" visible
- [ ] Descripcion de la app legible
- [ ] Tres caracteristicas principales mostradas con iconos
- [ ] Tres botones principales visibles:
  - [ ] "Crear cuenta" (FilledButton - color primario)
  - [ ] "Ya tengo cuenta" (OutlinedButton)
  - [ ] "Continuar sin cuenta" (TextButton gris)
- [ ] Texto legal de terminos visible en la parte inferior

### Funcionalidad
- [ ] Click en "Crear cuenta" navega a RegisterScreen
- [ ] Click en "Ya tengo cuenta" navega a LoginScreen
- [ ] Click en "Continuar sin cuenta" navega a MainScaffold
- [ ] Pantalla no se muestra en aperturas posteriores
- [ ] Scroll funciona si contenido es mas alto que la pantalla

### Responsive
- [ ] Se ve bien en movil (pantalla pequena)
- [ ] Se ve bien en tablet
- [ ] Se ve bien en desktop/web
- [ ] Padding horizontal se ajusta correctamente
- [ ] Elementos no se cortan en pantallas pequenas

---

## 2. LoginScreen

### Visualizacion
- [ ] Logo y titulo "AuraList" visibles
- [ ] Subtitulo "Inicia sesion para sincronizar tus tareas"
- [ ] Campo de email con icono de sobre
- [ ] Campo de contrasena con icono de candado
- [ ] Boton de toggle visibilidad de contrasena
- [ ] Boton "Olvidaste tu contrasena?" visible
- [ ] Boton principal "Iniciar sesion" (azul/primary)
- [ ] Divider con texto "o continua con"
- [ ] Boton de Google con logo
- [ ] Link "No tienes cuenta? Registrate"
- [ ] Link "Continuar sin cuenta" (gris)

### Validacion de Email
- [ ] Campo vacio → Error "El correo es obligatorio"
- [ ] Email sin @ → Error "Ingresa un correo electronico valido"
- [ ] Email "test@" → Error de formato invalido
- [ ] Email valido → No muestra error

### Validacion de Contrasena
- [ ] Campo vacio → Error "La contrasena es obligatoria"
- [ ] Menos de 6 caracteres → Error "Minimo 6 caracteres"
- [ ] 6+ caracteres → No muestra error

### Funcionalidad de Login con Email
- [ ] Credenciales invalidas → Error "Credenciales invalidas..."
- [ ] Credenciales validas → Navega a MainScaffold
- [ ] Boton se deshabilita durante carga
- [ ] Muestra CircularProgressIndicator durante carga
- [ ] Texto cambia a "Iniciando sesion..." durante carga
- [ ] Campos se deshabilitan durante carga

### Funcionalidad de Login con Google
- [ ] Click abre selector de cuenta de Google
- [ ] Seleccionar cuenta → Login exitoso → MainScaffold
- [ ] Cancelar selector → No muestra error, boton vuelve a normal
- [ ] Error de Google → Muestra mensaje de error apropiado
- [ ] Boton se deshabilita durante proceso

### Navegacion
- [ ] Click "Olvidaste tu contrasena?" → Abre ForgotPasswordDialog
- [ ] Click "Registrate" → Navega a RegisterScreen
- [ ] Click "Continuar sin cuenta" → MainScaffold (anonimo)
- [ ] Boton back del sistema vuelve a WelcomeScreen (si aplica)
- [ ] Enter en campo de contrasena → Submit form

### Estados de Error
- [ ] Error de red → Mensaje apropiado
- [ ] Firebase no disponible → Mensaje apropiado
- [ ] Usuario no encontrado → Error "No existe una cuenta con este correo"
- [ ] Contrasena incorrecta → Error "Contrasena incorrecta"
- [ ] Cuenta deshabilitada → Error "Esta cuenta ha sido deshabilitada"

---

## 3. RegisterScreen

### Visualizacion
- [ ] AppBar con titulo "Crear cuenta" y boton back
- [ ] Titulo principal "Registrate en AuraList"
- [ ] Descripcion sobre sincronizacion
- [ ] Campo de email con icono
- [ ] Campo de contrasena con icono y toggle
- [ ] Indicador de fortaleza de contrasena
- [ ] Lista de requisitos con checks (6 chars, mayuscula, numero)
- [ ] Campo de confirmar contrasena con toggle
- [ ] Checkbox de terminos y condiciones
- [ ] Boton "Crear cuenta" (primary)
- [ ] Divider "o registrate con"
- [ ] Boton de Google
- [ ] Link "Ya tienes cuenta? Inicia sesion"

### Validacion de Email
- [ ] Campo vacio → Error obligatorio
- [ ] Email invalido → Error de formato
- [ ] Email valido → Sin error

### Validacion de Contrasena
- [ ] Campo vacio → Error obligatorio
- [ ] Menos de 6 caracteres → Error "Minimo 6 caracteres"
- [ ] Sin mayuscula → Error "Debe tener al menos una mayuscula"
- [ ] Sin numero → Error "Debe tener al menos un numero"
- [ ] Cumple todos los requisitos → Sin error

### Indicador de Fortaleza
- [ ] Contrasena vacia → No muestra indicador
- [ ] Contrasena muy debil (1 punto) → Barra roja + "Muy debil"
- [ ] Contrasena debil (2 puntos) → Barra naranja + "Debil"
- [ ] Contrasena buena (3 puntos) → Barra amarilla + "Buena"
- [ ] Contrasena fuerte (4+ puntos) → Barra verde + "Fuerte"
- [ ] Checks de requisitos actualizan en tiempo real
- [ ] Check verde cuando requisito cumplido
- [ ] Check gris cuando requisito no cumplido

### Validacion de Confirmacion
- [ ] Campo vacio → Error "Confirma tu contrasena"
- [ ] No coincide → Error "Las contrasenas no coinciden"
- [ ] Coincide → Sin error

### Checkbox de Terminos
- [ ] Sin marcar → Intento de submit muestra error
- [ ] Marcado → Permite submit
- [ ] Click funciona correctamente

### Funcionalidad de Registro
- [ ] Formulario invalido → No permite submit
- [ ] Sin aceptar terminos → Error "Debes aceptar los terminos..."
- [ ] Registro exitoso → Snackbar verde + Navega a MainScaffold
- [ ] Email ya en uso → Error "Este correo ya esta en uso"
- [ ] Error de red → Mensaje apropiado
- [ ] Durante carga → Boton deshabilita, muestra progress
- [ ] Durante carga → Campos se deshabilitan

### Registro con Google
- [ ] Sin aceptar terminos → Error
- [ ] Con terminos aceptados → Abre selector Google
- [ ] Seleccionar cuenta → Registro exitoso
- [ ] Cuenta Google ya usada → Error apropiado
- [ ] Cancelar → No muestra error

### Navegacion
- [ ] Click "Inicia sesion" → Vuelve a LoginScreen
- [ ] Boton back → Vuelve a pantalla anterior
- [ ] Enter en campo final → Submit form

---

## 4. ForgotPasswordDialog

### Visualizacion
- [ ] Dialogo centrado en pantalla
- [ ] Icono de candado con reset
- [ ] Titulo "Recuperar contrasena"
- [ ] Descripcion clara del proceso
- [ ] Campo de email
- [ ] Boton "Cancelar"
- [ ] Boton "Enviar" (primary)

### Validacion
- [ ] Campo vacio → Error al submit
- [ ] Email invalido → Error de formato
- [ ] Email valido → Permite submit

### Funcionalidad
- [ ] Email no registrado → Mensaje "No se pudo enviar..."
- [ ] Email registrado → Exito + mensaje verde
- [ ] Email enviado → Dialogo se cierra despues de 2 seg
- [ ] Durante envio → Boton muestra progress
- [ ] Durante envio → Campo se deshabilita
- [ ] Click "Cancelar" → Cierra dialogo

### Verificacion de Email
- [ ] Email llega a bandeja de entrada
- [ ] Link del email funciona
- [ ] Puede restablecer contrasena
- [ ] Nueva contrasena funciona para login

---

## 5. LinkAccountDialog (Vincular Cuenta)

### Visualizacion
- [ ] BottomSheet con esquinas redondeadas
- [ ] Drag handle en la parte superior
- [ ] Icono de link con fondo de color
- [ ] Titulo "Vincular Cuenta"
- [ ] Descripcion de beneficios
- [ ] Vista inicial con dos opciones:
  - [ ] Boton de Google
  - [ ] Boton de Email/Password
- [ ] Vista de formulario (al elegir email):
  - [ ] Boton "Volver"
  - [ ] Campo de email
  - [ ] Campo de contrasena con helper text
  - [ ] Campo de confirmar contrasena
  - [ ] Boton "Vincular Cuenta"

### Solo para Usuarios Anonimos
- [ ] Usuario anonimo → Muestra opcion de vincular en perfil
- [ ] Usuario vinculado → Oculta opcion de vincular
- [ ] Usuario no autenticado → No aplica

### Vinculacion con Email/Password
- [ ] Validacion de email funciona
- [ ] Validacion de contrasena (6 chars, mayuscula, numero)
- [ ] Validacion de confirmacion funciona
- [ ] Vinculacion exitosa → Mensaje verde + Cierra dialogo
- [ ] Email ya en uso → Error "Este correo ya esta en uso"
- [ ] Durante proceso → Loading indicators
- [ ] Datos locales se mantienen despues de vincular

### Vinculacion con Google
- [ ] Click abre selector de Google
- [ ] Seleccionar cuenta → Vinculacion exitosa
- [ ] Cuenta ya en uso → Error especifico
- [ ] Cancelar → No muestra error, vuelve a normal
- [ ] Exito → Mensaje verde + Cierra dialogo
- [ ] Datos locales se mantienen

### Navegacion
- [ ] Click "Volver" → Vuelve a vista de opciones
- [ ] Click afuera del dialogo → Cierra dialogo
- [ ] Arrastrar hacia abajo → Cierra dialogo

---

## 6. PasswordStrengthIndicator (Widget)

### Visualizacion
- [ ] No se muestra si password esta vacio
- [ ] Barra de progreso con colores apropiados
- [ ] Texto descriptivo de fortaleza a la derecha
- [ ] Lista de requisitos con checks debajo

### Fortaleza
- [ ] 1 punto → Barra roja (25%) + "Muy debil"
- [ ] 2 puntos → Barra naranja (50%) + "Debil"
- [ ] 3 puntos → Barra amarilla (75%) + "Buena"
- [ ] 4+ puntos → Barra verde (100%) + "Fuerte"

### Requisitos
- [ ] "Al menos 6 caracteres" → Check verde cuando cumple
- [ ] "Al menos una mayuscula" → Check verde cuando cumple
- [ ] "Al menos un numero" → Check verde cuando cumple
- [ ] Checks grises cuando no cumple
- [ ] Actualiza en tiempo real al escribir

---

## 7. ProfileScreen (Integracion)

### Usuario Anonimo
- [ ] Avatar con icono de persona sin relleno
- [ ] Texto "Cuenta anonima"
- [ ] Subtexto "Tus datos solo estan en este dispositivo"
- [ ] Boton "Vincular cuenta" visible y funcional

### Usuario Vinculado
- [ ] Avatar con icono de persona con relleno
- [ ] Muestra email o "Usuario vinculado"
- [ ] Subtexto "Vinculada con [email/Google]"
- [ ] Boton "Vincular cuenta" NO visible

### Funcionalidad
- [ ] Click "Vincular cuenta" → Abre LinkAccountDialog
- [ ] Despues de vincular → UI actualiza automaticamente
- [ ] Email vinculado se muestra correctamente
- [ ] Proveedor se muestra correctamente (email/google)

---

## 8. AppRouter y Navegacion General

### Primera Apertura
- [ ] App muestra WelcomeScreen
- [ ] Estado se guarda en SharedPreferences
- [ ] No se vuelve a mostrar en aperturas posteriores

### Aperturas Posteriores
- [ ] Usuario con sesion → MainScaffold directamente
- [ ] Usuario sin sesion → MainScaffold (anonimo) directamente

### Resetear Onboarding (Testing)
- [ ] Llamar `resetWelcome()` → Siguiente apertura muestra WelcomeScreen
- [ ] Funciona correctamente para testing

---

## 9. Temas (Light/Dark Mode)

### Light Mode
- [ ] Todos los colores son legibles
- [ ] Contraste suficiente en todos los textos
- [ ] Botones destacan apropiadamente
- [ ] Errores en rojo son visibles
- [ ] Exitos en verde son visibles

### Dark Mode
- [ ] Todos los colores son legibles
- [ ] Contraste suficiente en todos los textos
- [ ] Botones destacan apropiadamente
- [ ] Errores en rojo son visibles
- [ ] Exitos en verde son visibles
- [ ] Fondos no son completamente negros (Material 3)

### Transicion
- [ ] Cambiar tema actualiza todas las pantallas
- [ ] No hay parpadeos o glitches
- [ ] Colores se mantienen consistentes

---

## 10. Responsive Design

### Mobile (< 600px)
- [ ] Todos los elementos visibles sin scroll horizontal
- [ ] Padding apropiado en los bordes
- [ ] Botones ocupan ancho completo
- [ ] Textos se ajustan sin cortarse
- [ ] Formularios se ven bien

### Tablet (600px - 840px)
- [ ] Contenido centrado con maxWidth
- [ ] Padding lateral aumenta
- [ ] Elementos no se estiran demasiado
- [ ] Layout se mantiene legible

### Desktop (> 840px)
- [ ] Formularios tienen ancho maximo (no ocupan todo)
- [ ] Centrado vertical y horizontal apropiado
- [ ] Botones tienen tamano razonable
- [ ] No se ve "perdido" en pantalla grande

---

## 11. Accesibilidad

### Navegacion con Teclado
- [ ] Tab navega entre campos en orden logico
- [ ] Enter en ultimo campo → Submit form
- [ ] Escape cierra dialogos
- [ ] Focus visible en elementos activos

### Lectores de Pantalla
- [ ] Labels descriptivos en todos los campos
- [ ] Botones tienen texto descriptivo
- [ ] Errores son anunciados
- [ ] Cambios de estado son comunicados

### Tamano de Texto
- [ ] App funciona con texto grande del sistema
- [ ] Textos no se cortan
- [ ] Layout se ajusta apropiadamente

---

## 12. Performance

### Tiempo de Carga
- [ ] WelcomeScreen carga en < 1 segundo
- [ ] Navegacion entre pantallas es instantanea
- [ ] No hay lag al escribir en campos

### Animaciones
- [ ] Transiciones son fluidas (60 FPS)
- [ ] No hay stuttering
- [ ] Progress indicators se animan suavemente

### Memoria
- [ ] No hay memory leaks
- [ ] App no crashea con uso prolongado
- [ ] Imagenes de Google cargan o muestran fallback

---

## 13. Offline/Online

### Sin Internet
- [ ] App funciona en modo local
- [ ] Login anonimo funciona
- [ ] Mensajes claros si Firebase no esta disponible
- [ ] No crashea por falta de conexion

### Con Internet
- [ ] Firebase Auth funciona correctamente
- [ ] Google Sign-In funciona
- [ ] Emails de recuperacion se envian
- [ ] Sincronizacion funciona

### Cambio de Estado
- [ ] Perder conexion durante operacion → Error apropiado
- [ ] Recuperar conexion → App funciona normal
- [ ] No hay estados inconsistentes

---

## 14. Seguridad

### Contrasenas
- [ ] Nunca se muestran por defecto
- [ ] Toggle show/hide funciona
- [ ] No se guardan en logs
- [ ] Validacion en cliente y servidor

### Tokens
- [ ] Firebase Auth maneja tokens correctamente
- [ ] Refresh tokens funcionan
- [ ] Sesiones persisten apropiadamente

### Datos Sensibles
- [ ] Emails no se muestran en logs de produccion
- [ ] Datos de usuario protegidos
- [ ] Firestore rules configuradas correctamente

---

## 15. Edge Cases

### Inputs Extremos
- [ ] Email muy largo → Maneja correctamente
- [ ] Contrasena muy larga → Maneja correctamente
- [ ] Caracteres especiales en email → Valida bien
- [ ] Emojis en contrasena → Maneja correctamente

### Estados Inesperados
- [ ] Firebase Auth no inicializado → No crashea
- [ ] Usuario eliminado externamente → Maneja bien
- [ ] Cuenta deshabilitada → Error apropiado
- [ ] Multiple clicks rapidos en botones → No duplica acciones

### Navegacion Compleja
- [ ] Back button del sistema → Funciona correctamente
- [ ] Navegar mientras carga → No causa errores
- [ ] Cerrar app durante operacion → Retoma bien

---

## 16. Mensajes de Error (Traduccion)

Verificar que estos errores de Firebase esten traducidos:

- [ ] `user-not-found` → "No existe una cuenta con este correo"
- [ ] `wrong-password` → "Contrasena incorrecta"
- [ ] `email-already-in-use` → "Este correo ya esta en uso"
- [ ] `weak-password` → "La contrasena es muy debil"
- [ ] `invalid-email` → "Correo electronico invalido"
- [ ] `user-disabled` → "Esta cuenta ha sido deshabilitada"
- [ ] `operation-not-allowed` → Mensaje apropiado
- [ ] `network-request-failed` → "Sin conexion a Internet"

---

## 17. Integracion con el Resto de la App

### Despues de Login/Registro
- [ ] Navega correctamente a MainScaffold
- [ ] Usuario autenticado correctamente
- [ ] Datos del usuario disponibles
- [ ] Sincronizacion inicia si esta habilitada

### Flujo de Vinculacion
- [ ] Datos locales se mantienen
- [ ] Sincronizacion se activa despues de vincular
- [ ] UI actualiza para reflejar cuenta vinculada
- [ ] Firestore recibe datos correctamente

### Cierre de Sesion
- [ ] Sign out funciona desde perfil
- [ ] Limpia datos apropiadamente
- [ ] Vuelve a pantalla apropiada
- [ ] Nuevo login funciona despues de sign out

---

## 18. Testing Final

### Flujo Completo 1: Nuevo Usuario
1. [ ] Abrir app → Ver WelcomeScreen
2. [ ] Click "Crear cuenta"
3. [ ] Completar formulario de registro
4. [ ] Verificar cuenta creada
5. [ ] Usar app normalmente
6. [ ] Cerrar y reabrir app
7. [ ] Verificar sesion persiste

### Flujo Completo 2: Usuario con Cuenta
1. [ ] Abrir app → Ver WelcomeScreen
2. [ ] Click "Ya tengo cuenta"
3. [ ] Ingresar credenciales existentes
4. [ ] Login exitoso
5. [ ] Usar app normalmente
6. [ ] Cerrar y reabrir app
7. [ ] Verificar sesion persiste

### Flujo Completo 3: Usuario Anonimo que Vincula
1. [ ] Abrir app → "Continuar sin cuenta"
2. [ ] Usar app, crear algunas tareas
3. [ ] Ir a Perfil
4. [ ] Click "Vincular cuenta"
5. [ ] Vincular con email o Google
6. [ ] Verificar tareas se mantienen
7. [ ] Cerrar y reabrir app
8. [ ] Verificar sesion y datos persisten

### Flujo Completo 4: Recuperacion de Contrasena
1. [ ] Ir a LoginScreen
2. [ ] Click "Olvidaste tu contrasena?"
3. [ ] Ingresar email registrado
4. [ ] Verificar email recibido
5. [ ] Click en link del email
6. [ ] Restablecer contrasena
7. [ ] Login con nueva contrasena
8. [ ] Verificar acceso exitoso

---

## Firma de QA

**Probado por**: _______________
**Fecha**: _______________
**Version**: _______________
**Plataforma(s)**: _______________
**Errores encontrados**: _______________
**Estado**: [ ] Aprobado [ ] Requiere cambios

---

## Notas Adicionales

Usa esta seccion para notas sobre bugs encontrados, mejoras sugeridas, o comportamientos inesperados:

```
[Escribe tus notas aqui]
```
