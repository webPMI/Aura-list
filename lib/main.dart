import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
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
    });
  }

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
          'Firebase Auth no disponible - app funcionara en modo local',
        );
        return;
      }

      final currentUser = authService.currentUser;

      if (currentUser == null) {
        _logger.info(
          'AuthInit',
          'No hay usuario autenticado, iniciando sesion anonima...',
        );
        final result = await authService.signInAnonymously();
        if (result != null) {
          _logger.info(
            'AuthInit',
            'Usuario anonimo creado correctamente: ${result.user?.uid}',
          );
          // Perform initial sync after new login
          _performInitialSync(result.user?.uid);
        } else {
          _logger.warning(
            'AuthInit',
            'Login anonimo omitido - app funcionara en modo local',
          );
        }
      } else {
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
      }
    } catch (e) {
      _logger.error('AuthInit', 'Error al inicializar autenticacion', error: e);
      _logger.info('AuthInit', 'La app continuara en modo local');
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

    return MaterialApp(
      title: 'AuraList',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('es', '')],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.outfitTextTheme(),
        cardTheme: const CardThemeData(elevation: 2, margin: EdgeInsets.all(8)),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD0BCFF),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        cardTheme: const CardThemeData(elevation: 2, margin: EdgeInsets.all(8)),
      ),
      home: const AppRouter(),
    );
  }
}
