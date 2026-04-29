import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:whitecane/data/remote/api/naver_local_search_api.dart';
import 'package:whitecane/data/remote/api/navigation_api.dart';
import 'package:whitecane/domain/repository/place_repository.dart';
import 'package:whitecane/domain/usecase/search_places_usecase.dart';
import 'package:whitecane/presentation/map/search_viewmodel.dart';
import 'package:whitecane/presentation/settings/settings_viewmodel.dart';

final GetIt getIt = GetIt.instance;

void setupDependencies() {
  final dio = Dio();
  final baseUrl = dotenv.env['SERVER_URL'] ?? 'http://localhost:8000/';

  getIt.registerLazySingleton<NaverLocalSearchApi>(
    () => NaverLocalSearchApi(
      dio,
      clientId: dotenv.env['NAVER_SEARCH_CLIENT_ID'] ?? '',
      clientSecret: dotenv.env['NAVER_SEARCH_CLIENT_SECRET'] ?? '',
    ),
  );
  getIt.registerLazySingleton<NavigationApi>(
    () => NavigationApi(dio, baseUrl: baseUrl),
  );
  getIt.registerLazySingleton<PlaceRepository>(
    () => PlaceRepositoryImpl(naverLocalSearchApi: getIt<NaverLocalSearchApi>()),
  );
  getIt.registerLazySingleton<SearchPlacesUseCase>(
    () => SearchPlacesUseCase(repository: getIt<PlaceRepository>()),
  );
  getIt.registerLazySingleton<SearchViewModel>(
    () => SearchViewModel(searchPlacesUseCase: getIt<SearchPlacesUseCase>()),
  );
  getIt.registerLazySingleton<SettingsViewModel>(
    () => SettingsViewModel(),
  );
}
