import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/lingostream_app.dart';
import 'services/ad_config_service.dart';
import 'services/translation_service.dart';
import 'services/update_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Future.wait([
    TranslationService.init(),
    UpdateService.init(),
    AdConfigService.loadBannerConfig(),
  ]);

  runApp(const LingoStreamApp());
}
