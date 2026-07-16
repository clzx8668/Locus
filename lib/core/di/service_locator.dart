import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../database/database.dart';
import '../services/ai_engine.dart';
import '../services/settings_service.dart';
import '../services/connectivity_service.dart';
import '../services/secure_storage_service.dart';
import '../services/vector_service.dart';
import '../services/vector_dedup_service.dart';
import '../services/ai_router_service.dart';
import '../services/dispatch_service.dart';
import '../services/decay_manager.dart';
import '../services/processing_pipeline.dart';
import '../services/text_cleaner_service.dart';
import '../../features/dashboard/data/dashboard_repository.dart';
import '../../features/chat/data/chat_repository.dart';
import '../../features/idea_stream/data/idea_repository.dart';
import '../../features/idea_stream/data/crm_repository.dart';
import '../../features/idea_stream/data/ledger_repository.dart';
import '../../features/idea_stream/data/todo_repository.dart';
import '../../features/idea_stream/data/tag_repository.dart';
import '../../features/memory/data/memory_repository.dart';

final getIt = GetIt.instance;

Future<void> setupLocator() async {
  // 数据库
  getIt.registerSingleton<AppDatabase>(AppDatabase());

  // Repositories
  getIt.registerSingleton<IdeaRepository>(IdeaRepository(getIt<AppDatabase>()));
  getIt.registerSingleton<TemplateRepository>(
    TemplateRepository(getIt<AppDatabase>()),
  );
  getIt.registerSingleton<DashboardRepository>(
    DashboardRepository(getIt<AppDatabase>()),
  );
  getIt.registerSingleton<ChatRepository>(ChatRepository(getIt<AppDatabase>()));
  getIt.registerSingleton<CrmRepository>(CrmRepository(getIt<AppDatabase>()));
  getIt.registerSingleton<LedgerRepository>(
    LedgerRepository(getIt<AppDatabase>()),
  );
  getIt.registerSingleton<TodoRepository>(TodoRepository(getIt<AppDatabase>()));
  getIt.registerSingleton<TagRepository>(TagRepository(getIt<AppDatabase>()));
  getIt.registerSingleton<MemoryRepository>(
    MemoryRepository(getIt<AppDatabase>()),
  );

  // Settings (requires async init)
  final settings = SettingsService();
  await settings.init();
  getIt.registerSingleton<SettingsService>(settings);

  // Secure storage
  getIt.registerSingleton<SecureStorageService>(SecureStorageService());

  // AI Engine (with secure storage + settings for async config + anonymize)
  final aiEngine = AiEngine(
    secureStorage: getIt<SecureStorageService>(),
    settings: getIt<SettingsService>(),
  );
  await aiEngine.init();
  getIt.registerSingleton<AiEngine>(aiEngine);

  // Other core services
  getIt.registerSingleton<ConnectivityService>(ConnectivityService());
  final vectorService = VectorService();
  await vectorService.init();
  getIt.registerSingleton<VectorService>(vectorService);
  getIt.registerSingleton<VectorDedupService>(
    VectorDedupService(getIt<IdeaRepository>(), getIt<VectorService>()),
  );
  getIt.registerSingleton<AiRouterService>(
    AiRouterService(
      getIt<AppDatabase>(),
      getIt<AiEngine>(),
      getIt<ConnectivityService>(),
    ),
  );
  getIt.registerSingleton<DispatchService>(
    DispatchService(getIt<AppDatabase>()),
  );
  getIt.registerSingleton<DecayManager>(DecayManager(getIt<AppDatabase>()));

  getIt.registerSingleton<TextCleanerService>(TextCleanerService());

  // Pipeline (depends on all services above)
  getIt.registerSingleton<ProcessingPipeline>(
    ProcessingPipeline(
      getIt<IdeaRepository>(),
      getIt<ConnectivityService>(),
      getIt<TextCleanerService>(),
      getIt<VectorService>(),
      getIt<VectorDedupService>(),
      getIt<AiRouterService>(),
      getIt<DispatchService>(),
      getIt<DecayManager>(),
    ),
  );

  debugPrint("Locus Core Hub Initialized with Processing Pipeline.");
}
