import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:flutter_quill/flutter_quill.dart'; // Temporarily disabled
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/app_router.dart';
import 'providers/theme_provider.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/logger_service.dart';
import 'features/guides/services/avatar_preload_service.dart';
import 'widgets/global_error_listener.dart';
import 'providers/notification_provider.dart';
import 'features/finance/providers/finance_provider.dart';
import 'services/encryption/encryption_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final logger = LoggerService();

  // Initialize Firebase
  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
    logger.info('Main', 'Firebase inicializado correctamente');
  } catch (e) {
    logger.error('Main', 'Error al inicializar Firebase', error: e);
    logger.warning('Main', 'La aplicación funcionará en modo local únicamente');
  }

  // Initialize Hive for web and theme storage
  await Hive.initFlutter();

  // Initialize date formatting for Spanish
  await initializeDateFormatting('es', null);

  // Initialize End-to-End Encryption Service
  await EncryptionService().initialize();

  runApp(
    ProviderScope(
      child: ChecklistApp(firebaseInitialized: firebaseInitialized),
    ),
  );
}

class ChecklistApp extends ConsumerStatefulWidget {
  final bool firebaseInitialized;

  const ChecklistApp({super.key, required this.firebaseInitialized});

  @override
  ConsumerState<ChecklistApp> createState() => _ChecklistAppState();
}

class _ChecklistAppState extends ConsumerState<ChecklistApp> {
  bool _authInitialized = false;
  final _logger = LoggerService();

  @override
  void initState() {
    super.initState();
    // Always attempt auth initialization after first frame
    // The AuthService will handle Firebase availability internally
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAuth();
      _preloadAvatars();
      _initializeNotifications();
    });
  }

  /// Preload available guide avatars for better performance
  Future<void> _preloadAvatars() async {
    try {
      await AvatarPreloadService.instance.preloadAvailableAvatars(context);
      final stats = AvatarPreloadService.instance.getStats();
      _logger.info(
        'AvatarPreload',
        'Avatares precargados: ${stats.preloaded} de ${stats.total}',
      );
    } catch (e) {
      _logger.error('AvatarPreload', 'Error al precargar avatares', error: e);
      // Non-critical - app continues without preload optimization
    }
  }

  /// Initialize notification system and start deadline watcher
  void _initializeNotifications() {
    try {
      // Read the TaskDeadlineWatcher to start watching for deadline changes
      // This will automatically schedule/cancel notifications as tasks change
      ref.read(taskDeadlineWatcherProvider);
      _logger.info('NotificationInit', 'Task deadline watcher iniciado');
    } catch (e) {
      _logger.error(
        'NotificationInit',
        'Error al inicializar watcher de notificaciones',
        error: e,
      );
      // Non-critical - app continues without notification watching
    }
  }

  /// Inicializa la autenticación de Firebase al iniciar la app.
  ///
  /// Este método es llamado una sola vez tras el primer frame de la UI.
  ///Su flujo es:
  /// 1. Verificar que Firebase esté disponible
  /// 2. Si hay usuario existente → realizar sync inicial
  /// 3. Si no hay usuario → crear usuario anónimo automáticamente
  ///
  /// Casos manejados:
  /// - Firebase disponible + usuario existente → sync completo
  /// - Firebase disponible + sin usuario → crear anónimo + sync
  /// - Firebase NO disponible → app en modo local (sin auth)
  /// - Error al crear anónimo → fallback a modo local
  ///
  /// NOTA: NO marca welcome como visto aquí. El WelcomeScreen decide eso
  /// basándose en shouldShowWelcomeProvider. Esto permite que el usuario
  /// nueva vez vea la pantalla de bienvenida con las opciones.
  ///
  /// PREVIOUSLY (antes de la corrección): Este método NO creaba usuario
  /// anónimo, por lo que usuarios primera vez quedaban sin sesión Firebase.
  /// Esto causaba fallos en vincular cuenta y en alcune operaciones.
  Future<void> _initializeAuth() async {
    if (_authInitialized) return;
    _authInitialized = true;

    try {
      final authService = ref.read(authServiceProvider);

      // Refresh Firebase availability check in case it wasn't ready during provider creation
      if (widget.firebaseInitialized) {
        authService.refreshFirebaseAvailability();
      }

      // Check if Firebase is actually available
      if (!authService.isFirebaseAvailable) {
        _logger.info(
          'AuthInit',
          'Firebase Auth no disponible - app funcionará en modo local',
        );
        return;
      }

      var currentUser = authService.currentUser;
      if (currentUser != null) {
        _logger.info(
          'AuthInit',
          'Usuario ya autenticado: ${currentUser.uid}',
          metadata: {
            'isAnonymous': currentUser.isAnonymous,
            'email': currentUser.email,
          },
        );
        // Perform sync for existing user
        _performInitialSync(currentUser.uid);
      } else {
        // No hay usuario → crear uno anónimo automáticamente
        _logger.info(
          'AuthInit',
          'No hay usuario. Creando sesión anónima para primer uso...',
        );
        try {
          final credential = await authService.signInAnonymously();
          if (credential != null && credential.user != null) {
            _logger.info(
              'AuthInit',
              'Usuario anónimo creado: ${credential.user!.uid}',
            );
            // NO marcar welcome como visto aquí — dejar que el WelcomeScreen
            // decida si mostrarse basándose en el provider de onboarding
            // Perform initial sync for the new anonymous user
            _performInitialSync(credential.user!.uid);
          } else {
            _logger.warning(
              'AuthInit',
              'No se pudo crear usuario anónimo. La app funcionará en modo local.',
            );
          }
        } catch (e) {
          _logger.error(
            'AuthInit',
            'Error al crear usuario anónimo',
            error: e,
          );
          _logger.info(
            'AuthInit',
            'La app continuará en modo local.',
          );
        }
      }
    } catch (e) {
      _logger.error('AuthInit', 'Error al inicializar autenticación', error: e);
      _logger.info('AuthInit', 'La app continuará en modo local');
    }
  }

  /// Perform initial sync with Firebase after auth
  /// Note: Sync is only performed if cloudSyncEnabled is true in user preferences
  Future<void> _performInitialSync(String? userId) async {
    if (userId == null || userId.isEmpty) return;

    try {
      final dbService = ref.read(databaseServiceProvider);

      // Check if cloud sync is enabled before attempting sync
      final syncEnabled = await dbService.isCloudSyncEnabled();
      if (!syncEnabled) {
        _logger.info(
          'Sync',
          'Cloud sync deshabilitado - app funcionara en modo local',
        );
        return;
      }

      _logger.info('Sync', 'Iniciando sincronizacion inicial con Firebase...');
      final result = await dbService.performFullSync(userId);
      try {
        final financeRepo = ref.read(financeRepositoryProvider);
        await financeRepo.performFullSync(userId);
      } catch (fe) {
        _logger.warning('Sync', 'Error en sincronizacion inicial de finanzas: $fe');
      }
      if (result.hasChanges) {
        _logger.info(
          'Sync',
          'Sincronizacion completada: ${result.totalDownloaded} elementos descargados',
        );
      }
    } catch (e) {
      _logger.error('Sync', 'Error en sincronizacion inicial', error: e);
      // No propagamos el error - la app funciona sin sync
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return GlobalErrorListener(
      child: MaterialApp(
        title: 'AuraList',

        debugShowCheckedModeBanner: false,
        themeMode: themeMode,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          // FlutterQuillLocalizations.delegate, // Temporarily disabled
        ],
        supportedLocales: const [Locale('en', ''), Locale('es', '')],
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4),
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.outfitTextTheme(),
          cardTheme: const CardThemeData(
            elevation: 2,
            margin: EdgeInsets.all(8),
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFD0BCFF),
            brightness: Brightness.dark,
          ),
          textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
          cardTheme: const CardThemeData(
            elevation: 2,
            margin: EdgeInsets.all(8),
          ),
        ),
        home: const AppRouter(),
      ),
    );
  }
}



