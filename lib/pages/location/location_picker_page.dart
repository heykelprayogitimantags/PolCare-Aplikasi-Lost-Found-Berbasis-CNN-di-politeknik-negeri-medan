import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class LocationPickerPage extends StatefulWidget {
  final LatLng? initialLocation;
  final String? initialAddress;
  final bool viewOnly;

  const LocationPickerPage({
    super.key,
    this.initialLocation,
    this.initialAddress,
    this.viewOnly = false, 
  });

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  late final MapController _mapController;
  LatLng? _selectedLocation;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initLocation();
  }

  /// 🔹 Dapatkan posisi pengguna (real-time)
  Future<void> _initLocation() async {
    if (widget.initialLocation != null) {
      // Jika sudah ada lokasi awal (misalnya dari detail report)
      _selectedLocation = widget.initialLocation;
      _loading = false;
      setState(() {});
      _mapController.move(widget.initialLocation!, 16);
      return;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _loading = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _loading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _loading = false);
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    final current = LatLng(position.latitude, position.longitude);

    setState(() {
      _selectedLocation = current;
      _loading = false;
    });

    _mapController.move(current, 16);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.viewOnly ? "Lihat Lokasi" : "Pilih Lokasi di Peta"),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter:
              _selectedLocation ?? const LatLng(-6.2000, 106.8167),
          initialZoom: 15,
          onTap: widget.viewOnly
              ? null // ✅ jika viewOnly → tidak bisa tap
              : (tapPosition, point) {
                  setState(() => _selectedLocation = point);
                },
          interactionOptions: widget.viewOnly
              ? const InteractionOptions(flags: InteractiveFlag.none) // tidak bisa geser/zoom
              : const InteractionOptions(
                  flags: InteractiveFlag.all, // bisa interaktif
                ),
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.heykel.polmed_care',
          ),
          if (_selectedLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _selectedLocation!,
                  width: 60,
                  height: 60,
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: widget.viewOnly
          ? null // ✅ Tidak ada tombol di mode lihat
          : FloatingActionButton.extended(
              onPressed: () {
                if (_selectedLocation != null) {
                  Navigator.pop(context, {
                    'location': _selectedLocation,
                    'address':
                        "Lat: ${_selectedLocation!.latitude}, Lng: ${_selectedLocation!.longitude}",
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Pilih lokasi di peta terlebih dahulu')),
                  );
                }
              },
              icon: const Icon(Icons.check),
              label: const Text("Pilih Lokasi"),
            ),
    );
  }
}
