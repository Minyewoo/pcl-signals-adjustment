import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Localizations;
import 'package:flutter/rendering.dart';
import 'package:hmi_core/hmi_core.dart';
import 'package:hmi_core/hmi_core_app_settings.dart';
import 'package:hmi_networking/hmi_networking.dart';
import 'package:plc_signals_adjustment/exit_listening_widget.dart';
import 'package:plc_signals_adjustment/main_app.dart';

Future<void> main() async {
  Log.initialize(
    level: switch(kDebugMode) {
      true => LogLevel.all,
      false => LogLevel.info,
    },
  );
  const log = Log('main');
  final (fileCache, memoryCache, cache) = await _initCaches();
  await runZonedGuarded(
    () async {
      debugRepaintRainbowEnabled = false;
      WidgetsFlutterBinding.ensureInitialized();
      await _initStatics();
      final dsClient = _initDsClient(
        cache, 
        debugEvents: [
          'Local.System.Connection',
          'Connection',
        ],
      );
      final reconnectStartup = _initJds(dsClient)..run();
      runApp(
        ExitListeningWidget(
          onExit: () => _onExit(log, reconnectStartup, dsClient, fileCache, memoryCache),
          child: const MainApp(),
        ),
      );
    },
    (error, stackTrace) => log.error(error.toString(), error, stackTrace),
  );
}

Future<void> _initStatics() async {
  await Localizations.initialize(
    AppLang.ru,
    jsonMap: JsonMap.fromTextFile(
      const TextFile.asset(
        'assets/translations/translations.json',
      ),
    ),
  );
  await AppSettings.initialize(
    jsonMap: JsonMap.fromTextFile(
      const TextFile.asset(
        'assets/settings/app-settings.json',
      ),
    ),
  );
}

Future<(DsClientFileCache, DsClientMemoryCache, DsClientFilteredCache)> _initCaches() async {
  const fileCache = DsClientFileCache(
    cacheFile: DsCacheFile(
      TextFile.path('cache.json'),
    ),
  );
  final memoryCache = DsClientMemoryCache(
    initialCache: {
      for (final point in await fileCache.getAll()) 
        point.name.name: point,
    },
  );
  final filteredCache = DsClientFilteredCache(
    filter: (point) => point.cot == DsCot.inf, 
    cache: DsClientDelayedCache(
      primaryCache: memoryCache,
      secondaryCache: fileCache,
    ),
  );
  return (fileCache, memoryCache, filteredCache);
}

DsClientReal _initDsClient(DsClientCache cache, {List<String> debugEvents = const []}) {
  final dsClient = DsClientReal(
    line: JdsLine(
      lineSocket: DsLineSocket(
        ip: const Setting('jds-host').toString(), 
        port: const Setting('jds-port').toInt,
      ),
    ),
    cache: cache,
  );
  return dsClient;
}

JdsServiceStartupOnReconnect _initJds(DsClient dsClient) {
  final jdsService = JdsService(
    dsClient: dsClient,
    route: const JdsServiceRoute(
      appName: Setting('jds-app-name'),
      serviceName: Setting('jds-service-name'),
    ),
  );
  return JdsServiceStartupOnReconnect(
    connectionStatuses: dsClient.streamInt('Local.System.Connection'),
    startup: JdsServiceStartup(
      service: jdsService,
    ),
    isConnected: dsClient.isConnected(),
  );
}

Future<void> _onExit(
  Log log,
  JdsServiceStartupOnReconnect startup,
  DsClientReal dsClient,
  DsClientFileCache fileCache,
  DsClientMemoryCache memoryCache,
) async {
  log.info('Stopping server connection listening...');
  await startup.dispose();
  log.info('Stopping DsClient...');
  await dsClient.cancel();
  log.info('Persisting cache...');
  await fileCache.addMany(await memoryCache.getAll());
  log.info('Ready to exit!');
}