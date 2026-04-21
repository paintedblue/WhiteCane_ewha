import 'package:dio/dio.dart';
import 'package:whitecane/domain/model/place.dart';

class NaverLocalSearchApi {
  final Dio _dio;
  final String _clientId;
  final String _clientSecret;

  static const _url = 'https://openapi.naver.com/v1/search/local.json';
  static final _htmlTag = RegExp(r'<[^>]*>');

  NaverLocalSearchApi(
    this._dio, {
    required String clientId,
    required String clientSecret,
  })  : _clientId = clientId,
        _clientSecret = clientSecret;

  Future<List<Place>> search(String query) async {
    final response = await _dio.get(
      _url,
      queryParameters: {'query': query, 'display': 10, 'sort': 'sim'},
      options: Options(headers: {
        'X-Naver-Client-Id': _clientId,
        'X-Naver-Client-Secret': _clientSecret,
      }),
    );

    final items = response.data['items'] as List<dynamic>;
    return items.map((item) {
      final mapx = int.parse(item['mapx'] as String);
      final mapy = int.parse(item['mapy'] as String);
      final address = (item['roadAddress'] as String).isNotEmpty
          ? item['roadAddress'] as String
          : item['address'] as String;

      return Place(
        placeName: (item['title'] as String).replaceAll(_htmlTag, ''),
        address: address,
        category: item['category'] as String? ?? '',
        contact: item['telephone'] as String? ?? '',
        longitude: mapx / 1e7,
        latitude: mapy / 1e7,
      );
    }).toList();
  }
}
