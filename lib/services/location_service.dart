import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationService {
  static const double allowedLatitude = 24.774265; // عدلها حسب موقع التدريب
  static const double allowedLongitude = 46.738586;
  static const double allowedRadiusInMeters = 200;

  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("⚠️ خدمات الموقع غير مفعلة.");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("❌ تم رفض إذن الموقع.");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("🚫 تم رفض إذن الموقع نهائيًا.");
    }

    return await Geolocator.getCurrentPosition();
  }

  static Future<bool> isInsideAllowedArea(Position position) async {
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      allowedLatitude,
      allowedLongitude,
    );
    return distance <= allowedRadiusInMeters;
  }

  static Future<Map<String, dynamic>?> getCoordinatesFromTrainingOrg(String orgName) async {
    final encodedName = Uri.encodeComponent(orgName);
    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$encodedName&format=json&limit=1');

    final response = await http.get(url, headers: {
      'User-Agent': 'SmartTrackApp/1.0 (your_email@example.com)'
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data != null && data.isNotEmpty) {
        final lat = double.parse(data[0]['lat']);
        final lon = double.parse(data[0]['lon']);
        return {
          'latitude': lat,
          'longitude': lon,
          'displayName': data[0]['display_name'],
        };
      }
    }

    return null;
  }
}
