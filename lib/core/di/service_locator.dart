import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../database/database.dart';
import '../services/ai_engine.dart';
import '../services/settings_service.dart';
import '../services/connectivity_service.dart';
import '../services/vector_dedup_service.dart';
import '../services/ai_router_service.dart';
import '../services/dispatch_service.dart';
import '../services/decay_manager.dart';
import '../services/processing_pipeline.dart';
import '../../features/idea_stream/data/idea_repository.dart';
import '../../features/idea_stream/data/crm_repository.dart';
import '../../features/idea_stream/data/ledger_repository.dart';
import '../../features/idea_stream/data/todo_repository.dart';

final getIt = GetIt.instance;

Future<void> setupLocator() async {
  // 数据库
  getIt.registerSingleton<AppDatabase>(AppDatabase());

  // Repositories
  getIt.registerSingleton<IdeaRepository>(IdeaRepository(getIt<AppDatabase>()));
  getIt.registerSingleton<TemplateRepository>(
      TemplateRepository(getIt<AppDatabase>()));
  getIt.registerSingleton<CrmRepository>(CrmRepository(getIt<AppDatabase>()));
  getIt.registerSingleton<LedgerRepository>(
      LedgerRepository(getIt<AppDatabase>()));
  getIt.registerSingleton<TodoRepository>(TodoRepository(getIt<AppDatabase>()));

  // Core services
  getIt.registerSingleton<AiEngine>(AiEngine());
  getIt.registerSingleton<ConnectivityService>(ConnectivityService());
  getIt.registerSingleton<VectorDedupService>(
      VectorDedupService(getIt<AppDatabase>()));
  getIt.registerSingleton<AiRouterService>(AiRouterService(
    getIt<AppDatabase>(),
    getIt<AiEngine>(),
    getIt<ConnectivityService>(),
  ));
  getIt.registerSingleton<DispatchService>(
      DispatchService(getIt<AppDatabase>()));
  getIt.registerSingleton<DecayManager>(DecayManager(getIt<AppDatabase>()));

  // Pipeline (depends on all services above)
  getIt.registerSingleton<ProcessingPipeline>(ProcessingPipeline(
    getIt<AppDatabase>(),
    getIt<ConnectivityService>(),
    getIt<VectorDedupService>(),
    getIt<AiRouterService>(),
    getIt<DispatchService>(),
    getIt<DecayManager>(),
  ));

  // Settings (requires async init)
  final settings = SettingsService();
  await settings.init();
  getIt.registerSingleton<SettingsService>(settings);

  debugPrint("Locus Core Hub Initialized with Processing Pipeline.");
}
