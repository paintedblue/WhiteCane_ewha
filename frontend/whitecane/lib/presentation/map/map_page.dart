import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:whitecane/data/remote/api/building_api.dart';
import 'package:whitecane/data/remote/api/navigation_api.dart';
import 'package:whitecane/presentation/common/custom_search_bar.dart';
import 'package:whitecane/presentation/common/map_component.dart';
import 'package:whitecane/presentation/map/search_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late final BuildingApi _buildingApi;
  late final NavigationApi _navigationApi;
  late final String _baseUrl;

  final GlobalKey<MapComponentState> _mapComponentKey =
      GlobalKey<MapComponentState>();

  @override
  void initState() {
    super.initState();
    final dio = Dio();
    _baseUrl = dotenv.env['SERVER_URL'] ?? 'http://localhost:8000/';
    _buildingApi = BuildingApi(dio, baseUrl: _baseUrl);
    _navigationApi = NavigationApi(dio, baseUrl: _baseUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── 지도 컴포넌트 ─────────────────────────────────────
          MapComponent(
            key: _mapComponentKey,
            navigationApi: _navigationApi,
            baseUrl: _baseUrl,
          ),

          // ── 검색바 (상단 오버레이) ────────────────────────────
          Positioned(
            top: 60.0,
            left: 8.0,
            right: 8.0,
            child: CustomSearchBar(
              hasShadow: true,
              readOnly: true,
              onTap: () {
                Get.to(() => SearchPage(mapComponentKey: _mapComponentKey));
              },
            ),
          ),
        ],
      ),
    );
  }
}
