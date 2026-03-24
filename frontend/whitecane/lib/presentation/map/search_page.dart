import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:whitecane/di/service_locator.dart';
import 'package:whitecane/presentation/common/custom_search_bar.dart';
import 'package:whitecane/presentation/common/map_component.dart';
import 'package:whitecane/presentation/common/place_item.dart';
import 'package:whitecane/presentation/map/search_viewmodel.dart';

class SearchPage extends StatelessWidget {
  final GlobalKey<MapComponentState> mapComponentKey;

  const SearchPage({super.key, required this.mapComponentKey});

  @override
  Widget build(BuildContext context) {
    final SearchViewModel viewModel = getIt<SearchViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('목적지 검색'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          CustomSearchBar(
            hasShadow: false,
            readOnly: false,
            viewModel: viewModel,
          ),
          const SizedBox(height: 16.0),
          Expanded(
            child: Obx(() {
              if (viewModel.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (viewModel.error.isNotEmpty) {
                return const Center(
                  child: Text(
                    '오류가 발생했습니다.',
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }
              if (viewModel.places.isEmpty) {
                return const Center(
                  child: Text(
                    '검색어를 입력하세요.',
                    style: TextStyle(fontSize: 16.0, color: Colors.black54),
                  ),
                );
              }
              return ListView.builder(
                itemCount: viewModel.places.length,
                itemBuilder: (context, index) {
                  return PlaceItem(
                    place: viewModel.places[index],
                    mapComponentKey: mapComponentKey,
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
