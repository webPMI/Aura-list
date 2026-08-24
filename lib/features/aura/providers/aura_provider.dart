import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/aura_service.dart';
import '../models/aura_state.dart';

/// Provider singleton de AuraService
final auraServiceProvider = ChangeNotifierProvider<AuraService>((ref) {
  final service = AuraService();
  service.load();
  return service;
});

/// Provider del estado reactivo de Aura
final auraStateProvider = Provider<AuraState>((ref) {
  return ref.watch(auraServiceProvider).state;
});

/// Provider del rango celestial actual
final auraRankProvider = Provider<AuraRank>((ref) {
  return ref.watch(auraStateProvider).rank;
});
