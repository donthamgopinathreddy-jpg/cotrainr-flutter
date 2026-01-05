import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class RealtimeMap extends StatefulWidget {
  final double height;
  final Function(LatLng)? onMapTap;
  final List<MapMarker>? markers;
  final LatLng? initialCameraPosition;
  final bool showUserLocation;
  final double? zoom;

  const RealtimeMap({
    super.key,
    required this.height,
    this.onMapTap,
    this.markers,
    this.initialCameraPosition,
    this.showUserLocation = true,
    this.zoom,
  });

  @override
  State<RealtimeMap> createState() => _RealtimeMapState();
}

class MapMarker {
  final String id;
  final LatLng position;
  final String? title;
  final String? snippet;
  final BitmapDescriptor? icon;

  MapMarker({
    required this.id,
    required this.position,
    this.title,
    this.snippet,
    this.icon,
  });
}

class _RealtimeMapState extends State<RealtimeMap> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      // Request location permission
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        return;
      }

      // Get current position
      if (widget.showUserLocation) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        if (!mounted) return;
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
      } else {
        if (!mounted) return;
        setState(() {
          _currentPosition = widget.initialCameraPosition ?? const LatLng(37.7749, -122.4194); // Default to San Francisco
        });
      }

      // Create markers
      if (!mounted) return;
      _createMarkers();

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
        _currentPosition = widget.initialCameraPosition ?? const LatLng(37.7749, -122.4194);
      });
      if (mounted) {
        _createMarkers();
      }
    }
  }

  void _createMarkers() {
    _markers = {};

    // Add user location marker
    if (widget.showUserLocation && _currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }

    // Add custom markers
    if (widget.markers != null) {
      for (var marker in widget.markers!) {
        _markers.add(
          Marker(
            markerId: MarkerId(marker.id),
            position: marker.position,
            icon: marker.icon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: marker.title,
              snippet: marker.snippet,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1),
              Color(0xFF06B6D4),
            ],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_hasError || _currentPosition == null) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1),
              Color(0xFF06B6D4),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Unable to load map',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  if (!mounted) return;
                  setState(() {
                    _isLoading = true;
                    _hasError = false;
                  });
                  _initializeMap();
                },
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: widget.height,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentPosition!,
          zoom: widget.zoom ?? 14.0,
        ),
        markers: _markers,
        myLocationEnabled: widget.showUserLocation,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        onTap: widget.onMapTap,
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}



