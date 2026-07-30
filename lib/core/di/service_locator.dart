import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../database/database.dart';
import '../vault/vault_service.dart';
import '../vault/fts_index_service.dart';
import '../services/ai_route_service.dart';
import '../services/unified_search_service.dart';
import '../services/embedding_service.dart';
import '../theme/theme_config.dart';

final getIt = GetIt.instance;

Future<void> setupLocator() async {
  getIt.registerSingleton<AppDatabase>(AppDatabase());

  final vaultService = VaultService();
  getIt.registerSingleton<VaultService>(vaultService);

  final ftsService = FtsIndexService();
  getIt.registerSingleton<FtsIndexService>(ftsService);

  getIt.registerSingleton<AiRouteService>(AiRouteService());
  getIt.registerSingleton<UnifiedSearchService>(UnifiedSearchService());
  getIt.registerSingleton<EmbeddingService>(EmbeddingService());
  getIt.registerSingleton<ThemeConfig>(ThemeConfig());

  final db = getIt<AppDatabase>();
  final savedVaultPath = await db.getConfig('vault_path');
  if (savedVaultPath != null && savedVaultPath.isNotEmpty) {
    await vaultService.initialize(savedVaultPath);
    await ftsService.initialize(savedVaultPath);
    debugPrint('Locus Vault auto-initialized: $savedVaultPath');
  } else {
    debugPrint('Locus Vault not configured. Set path in Settings.');
  }

  debugPrint("Locus Core Hub Initialized.");
}
