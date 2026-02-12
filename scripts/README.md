# Scripts de Build y Deploy - AuraList

Estos scripts automatizan las tareas comunes de build, deploy y versionado.

## Disponibles

### Build Completo

**Windows:**
```bash
.\scripts\build_all.bat
```

**Linux/Mac:**
```bash
chmod +x scripts/build_all.sh
./scripts/build_all.sh
```

Construye:
- Android APKs (split por ABI)
- Android App Bundle (para Play Store)
- Web (PWA con offline-first)
- Windows (solo en Windows)
- iOS (solo en macOS)

---

### Deploy Web

**Windows:**
```bash
.\scripts\deploy_web.bat
```

**Linux/Mac:**
```bash
chmod +x scripts/deploy_web.sh
./scripts/deploy_web.sh
```

Despliega la app web a Firebase Hosting:
- Construye versión release optimizada
- Despliega a https://aura-list.web.app

**Requisitos:**
- Firebase CLI instalado: `npm install -g firebase-tools`
- Autenticado: `firebase login`

---

### Incrementar Versión

**Windows:**
```bash
.\scripts\version_bump.bat
```

**Linux/Mac:**
```bash
chmod +x scripts/version_bump.sh
./scripts/version_bump.sh
```

Incrementa el build number automáticamente:
- `1.0.0+1` → `1.0.0+2`
- Actualiza `pubspec.yaml`
- Solicita confirmación antes de cambiar

---

## Uso Típico

### Desarrollo Local
```bash
# Build rápido para probar
flutter run -d chrome           # Web
flutter run -d windows          # Windows
flutter run                     # Android (dispositivo conectado)
```

### Pre-Release
```bash
# 1. Incrementar versión
.\scripts\version_bump.bat

# 2. Build completo
.\scripts\build_all.bat

# 3. Probar builds
# Android: Instalar APK en dispositivo
# Web: Probar en build/web/
# Windows: Ejecutar build/windows/x64/runner/Release/checklist_app.exe
```

### Release Web
```bash
# Deploy a producción
.\scripts\deploy_web.bat

# Verificar en
# https://aura-list.web.app
```

---

## Notas

### Permisos (Linux/Mac)
Dar permisos de ejecución la primera vez:
```bash
chmod +x scripts/*.sh
```

### Dependencias
- **Flutter SDK**: Todas las plataformas
- **Android Studio**: Para builds Android
- **Xcode**: Para builds iOS (solo Mac)
- **Visual Studio 2022**: Para builds Windows
- **Firebase CLI**: Para deploys web

### Verificar Entorno
```bash
flutter doctor -v
```

---

## Troubleshooting

### Error: "Flutter not found"
Asegurarse de que Flutter esté en el PATH:
```bash
where flutter      # Windows
which flutter      # Linux/Mac
```

### Error: "Firebase not found"
Instalar Firebase CLI:
```bash
npm install -g firebase-tools
firebase login
```

### Error de Build Android
```bash
# Limpiar y reconstruir
flutter clean
flutter pub get
cd android
./gradlew clean     # Linux/Mac
gradlew.bat clean   # Windows
cd ..
flutter build apk
```

### Error de Build Windows
Verificar que Visual Studio esté instalado con "Desktop development with C++":
```bash
flutter doctor -v
```

---

## Scripts Avanzados (Futuros)

Próximamente:
- `test_all.sh` - Ejecutar todos los tests
- `analyze.sh` - Análisis estático de código
- `release.sh` - Crear release completo con changelog
- `build_msix.bat` - Generar paquete MSIX para Microsoft Store
