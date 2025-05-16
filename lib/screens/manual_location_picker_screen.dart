import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class ManualLocationPickerScreen extends StatefulWidget {
  final Function(double lat, double lon) onLocationSelected;

  const ManualLocationPickerScreen({Key? key, required this.onLocationSelected}) : super(key: key);

  @override
  _ManualLocationPickerScreenState createState() => _ManualLocationPickerScreenState();
}

class _ManualLocationPickerScreenState extends State<ManualLocationPickerScreen> {
  LatLng _selectedLocation = LatLng(24.7136, 46.6753); // الرياض
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();

  Future<void> _goToCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage("❌ خدمة الموقع غير مفعّلة");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          _showMessage("⚠️ لم يتم منح صلاحية الموقع");
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final current = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() {
        _selectedLocation = current;
        _mapController.move(current, 16);
      });
    } catch (e) {
      _showMessage("❌ فشل في جلب الموقع الحالي");
    }
  }

  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _showMessage("⚠️ اكتب اسم الموقع للبحث");
      return;
    }

    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final target = LatLng(locations[0].latitude, locations[0].longitude);
        if (!mounted) return;
        setState(() {
          _selectedLocation = target;
          _mapController.move(target, 16);
        });
      } else {
        _showMessage("❌ لم يتم العثور على الموقع");
      }
    } catch (e) {
      _showMessage("❌ خطأ أثناء البحث عن الموقع");
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textAlign: TextAlign.center),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _confirmLocationAndReturn() async {
    await widget.onLocationSelected(
      _selectedLocation.latitude,
      _selectedLocation.longitude,
    );

    Navigator.pop(context, {'lat': _selectedLocation.latitude, 'lon': _selectedLocation.longitude});
 // ✅ يرجع true بشكل صحيح
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('اختيار موقع التدريب')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "ابحث عن الموقع...",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                  IconButton(icon: Icon(Icons.search), onPressed: _searchLocation),
                  IconButton(icon: Icon(Icons.my_location), onPressed: _goToCurrentLocation),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      center: _selectedLocation,
                      zoom: 15,
                      onTap: (tapPosition, point) {
                        setState(() {
                          _selectedLocation = point;
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.google.com/vt/lyrs=s&x={x}&y={y}&z={z}',
                        subdomains: ['mt0', 'mt1', 'mt2', 'mt3'],
                        userAgentPackageName: 'com.example.smarttrack',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLocation,
                            width: 40,
                            height: 40,
                            child: Icon(Icons.location_on, size: 40, color: Colors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: ElevatedButton.icon(
                      onPressed: _confirmLocationAndReturn,
                      icon: Icon(Icons.check),
                      label: Text("تأكيد الموقع"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
