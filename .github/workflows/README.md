# GitHub Actions CI/CD

Automatización de builds y deploys para AuraList.

## Workflows Disponibles

### 1. Build & Test (`build-test.yml`)

**Trigger:** Push o PR a `main` o `develop`

**Tareas:**
1. **Analyze**: Análisis estático + tests unitarios
2. **Build Android**: APKs release
3. **Build Web**: PWA optimizada
4. **Build Windows**: Ejecutable release

**Artifacts generados:**
- `android-apks`: APKs por arquitectura
- `web-build`: Build web completo
- `windows-build`: Build Windows comprimido

**Duración aproximada:** 10-15 minutos

---

### 2. Deploy Web (`deploy-web.yml`)

**Trigger:**
- Push a `main` que modifique código
- Manual dispatch (botón en GitHub Actions)

**Tareas:**
1. Build web optimizado
2. Deploy a Firebase Hosting
3. Comenta URL de deployment en commit

**Requisitos:**
- Secret: `FIREBASE_SERVICE_ACCOUNT_AURA_LIST`

**Duración aproximada:** 3-5 minutos

---

## Configuración Inicial

### 1. Activar GitHub Actions

En tu repositorio GitHub:
1. Ve a "Settings" → "Actions" → "General"
2. Marca "Allow all actions and reusable workflows"
3. Guardar

### 2. Configurar Firebase Deploy

Para que funcione `deploy-web.yml`:

#### Opción A: Automática con Firebase CLI
```bash
# En tu máquina local
firebase init hosting:github
```

Esto:
- Genera el service account
- Agrega el secret a GitHub automáticamente
- Configura el workflow

#### Opción B: Manual

1. **Crear Service Account en Firebase:**
   - Firebase Console → Project Settings → Service Accounts
   - "Generate new private key"
   - Descargar JSON

2. **Agregar Secret a GitHub:**
   - GitHub repo → Settings → Secrets and variables → Actions
   - "New repository secret"
   - Name: `FIREBASE_SERVICE_ACCOUNT_AURA_LIST`
   - Value: Contenido completo del JSON

---

## Uso

### Ver Runs

1. Ve a "Actions" tab en GitHub
2. Selecciona un workflow
3. Ver jobs y logs

### Descargar Artifacts

Después de un build exitoso:
1. Ir al run específico
2. Sección "Artifacts" al final
3. Descargar zip

### Trigger Manual

Para `deploy-web.yml`:
1. Actions → Deploy Web to Firebase
2. "Run workflow"
3. Seleccionar branch
4. "Run workflow"

---

## Estado de Badges

Agrega a tu `README.md`:

```markdown
![Build & Test](https://github.com/TU_USUARIO/TU_REPO/workflows/Build%20%26%20Test/badge.svg)
![Deploy Web](https://github.com/TU_USUARIO/TU_REPO/workflows/Deploy%20Web%20to%20Firebase/badge.svg)
```

---

## Optimizaciones

### Cache

Los workflows ya incluyen cache para:
- Flutter SDK
- Dependencies (pub cache)
- Gradle (Android)

### Paralelización

Los builds se ejecutan en paralelo después del análisis.

### Artifacts Retention

- **Default**: 30 días
- Modificar en `retention-days` si necesario

---

## Monitoreo

### Notificaciones

GitHub envía notificaciones automáticas si:
- Un workflow falla
- Un PR tiene checks pendientes

Configurar en:
- GitHub → Settings → Notifications

### Logs

Ver logs detallados:
1. Click en el job fallido
2. Expandir steps
3. Ver output completo

---

## Troubleshooting

### Error: "No space left on device"

Agregar antes de build:
```yaml
- name: Free Disk Space
  run: |
    sudo rm -rf /usr/share/dotnet
    sudo rm -rf /opt/ghc
    sudo rm -rf "/usr/local/share/boost"
```

### Error: "Flutter command not found"

Verificar que `subosito/flutter-action` esté usando versión correcta:
```yaml
uses: subosito/flutter-action@v2
```

### Firebase Deploy Falla

1. Verificar que el secret esté configurado
2. Verificar project ID en workflow
3. Verificar permisos del service account

### Tests Fallan

Ejecutar localmente primero:
```bash
flutter test
flutter analyze
```

---

## Workflows Futuros (Opcional)

### Release Automation
```yaml
name: Release

on:
  push:
    tags:
      - 'v*'
```

### PR Preview
```yaml
name: PR Preview

on:
  pull_request:
    types: [opened, synchronize]
```

Despliega a Firebase preview channel para cada PR.

---

## Costos

**GitHub Actions:**
- Repositorios públicos: **Gratis ilimitado**
- Repositorios privados: 2000 minutos/mes gratis

**Firebase Hosting:**
- Plan Spark (gratis): 10 GB storage, 360 MB/día transfer
- Suficiente para desarrollo

---

## Mejores Prácticas

1. **Commits pequeños**: Workflows más rápidos
2. **Branch protection**: Require checks antes de merge
3. **Semantic versioning**: Usa tags para releases
4. **Changelog**: Mantener actualizado para releases

---

## Referencias

- [GitHub Actions Docs](https://docs.github.com/actions)
- [Flutter CI/CD](https://docs.flutter.dev/deployment/cd)
- [Firebase GitHub Action](https://github.com/FirebaseExtended/action-hosting-deploy)
