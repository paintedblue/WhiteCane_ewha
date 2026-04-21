import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:sizing/sizing_builder.dart';
import 'package:whitecane/navigation/main_navigation_page.dart';
import 'package:whitecane/presentation/map/map_page.dart';
import 'di/service_locator.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final clientId = dotenv.env['NAVER_MAP_CLIENT_ID'] ?? '';
  debugPrint('네이버 지도 Client ID: "$clientId"');
  await FlutterNaverMap().init(
    clientId: clientId,
    onAuthFailed: (ex) => debugPrint('네이버 지도 인증 실패: $ex'),
  );
  setupDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SizingBuilder(
      builder: () => GetMaterialApp(
        color: Colors.white,
        title: 'WhiteCane',
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => const MainNavigationPage()),
          GetPage(name: '/main', page: () => const MainNavigationPage()),
          GetPage(name: '/map', page: () => const MapPage()),
        ],
      ),
    );
  }
}
