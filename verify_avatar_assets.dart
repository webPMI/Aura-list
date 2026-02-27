// ignore_for_file: avoid_print

import 'dart:io';
import 'package:path/path.dart' as path;

/// Quick verification script to check if all guide avatars exist in the assets folder
void main() async {
  final repoRoot = Directory.current;
  final avatarsDir = Directory(
    path.join(repoRoot.path, 'assets', 'guides', 'avatars'),
  );

  print('=' * 80);
  print('AVATAR ASSETS VERIFICATION');
  print('=' * 80);
  print('Repository: ${repoRoot.path}');
  print('Avatars directory: ${avatarsDir.path}');
  print('=' * 80);
  print('');

  if (!avatarsDir.existsSync()) {
    print('❌ ERROR: Avatars directory does not exist!');
    exit(1);
  }

  // Expected guide IDs (from guide_catalog.dart)
  final expectedGuideIds = [
    'aethel',
    'crono-velo',
    'luna-vacia',
    'helioforja',
    'leona-nova',
    'chispa-azul',
    'gloria-sincro',
    'pacha-nexo',
    'gea-metrica',
    'selene-fase',
    'viento-estacion',
    'atlas-orbital',
    'erebo-logica',
    'anima-suave',
    'morfeo-astral',
    'shiva-fluido',
    'loki-error',
    'eris-nucleo',
    'anubis-vinculo',
    'zenit-cero',
    'oceano-bit',
  ];

  print('Expected guide avatars: ${expectedGuideIds.length}');
  print('');

  int found = 0;
  int missing = 0;
  final missingFiles = <String>[];

  for (final guideId in expectedGuideIds) {
    final avatarFile = File(path.join(avatarsDir.path, '$guideId.png'));

    if (avatarFile.existsSync()) {
      final size = avatarFile.lengthSync();
      final sizeKb = (size / 1024).toStringAsFixed(1);
      print('✓ $guideId.png ($sizeKb KB)');
      found++;
    } else {
      print('❌ $guideId.png - MISSING');
      missingFiles.add('$guideId.png');
      missing++;
    }
  }

  print('');
  print('=' * 80);
  print('SUMMARY');
  print('=' * 80);
  print('Total guides: ${expectedGuideIds.length}');
  print('Found: $found');
  print('Missing: $missing');
  print('=' * 80);

  if (missing > 0) {
    print('');
    print('❌ Missing avatar files:');
    for (final file in missingFiles) {
      print('   - $file');
    }
    exit(1);
  } else {
    print('');
    print('✅ All guide avatars are present!');
    exit(0);
  }
}
