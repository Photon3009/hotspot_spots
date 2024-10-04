import 'package:dio/dio.dart';
import 'package:hotspot_hosts/model/experience.dart';

class ExperienceService {
  final Dio _dio = Dio();
  final String _url = 'https://staging.cos.8club.co/experiences';

  Future<List<Experience>> fetchExperiences() async {
    try {
      final response = await _dio.get(_url);

      if (response.statusCode == 200) {
        final List<dynamic> experienceData =
            response.data['data']['experiences'];
        print(experienceData.map((json) => Experience.fromJson(json)).toList());
        return experienceData.map((json) => Experience.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load experiences');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Failed to fetch experiences');
    }
  }
}
