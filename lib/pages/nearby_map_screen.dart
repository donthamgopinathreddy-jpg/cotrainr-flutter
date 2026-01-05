import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NearbyMapScreen extends StatefulWidget {
  const NearbyMapScreen({super.key});

  @override
  State<NearbyMapScreen> createState() => _NearbyMapScreenState();
}

class _NearbyMapScreenState extends State<NearbyMapScreen> {
  final _sb = Supabase.instance.client;

  GoogleMapController? _mapController;
  LatLng? _userLocation;
  bool _loading = true;
  bool _locationPermissionDenied = false;
  String _kind = 'all'; // all|trainer|nutritionist|center
  int _radiusM = 5000; // 5km default

  final Set<Marker> _markers = {};
  Map<String, dynamic>? _selectedEntity;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _locationPermissionDenied = false;
    });

    // Always set a default location first so map can render
    _userLocation = const LatLng(17.3850, 78.4867); // Hyderabad, India default
    
    // Try to get user's actual location
    final hasPermission = await _ensureLocationPermission();
    
    if (!hasPermission) {
      setState(() => _locationPermissionDenied = true);
    } else {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        _userLocation = LatLng(position.latitude, position.longitude);
      } catch (e) {
        print('❌ [MAP] Error getting location: $e');
        setState(() => _locationPermissionDenied = true);
        // Keep default location
      }
    }

    // Set loading to false so map can render
    if (mounted) {
      setState(() => _loading = false);
    }
    
    // Load markers after map is visible
    await _loadMarkers();
  }

  Future<bool> _ensureLocationPermission() async {
    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check permission status
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  Future<void> _loadMarkers() async {
    if (_userLocation == null) return;

    try {
      final response = await _sb.rpc(
        'nearby_entities',
        params: {
          'in_lat': _userLocation!.latitude,
          'in_lng': _userLocation!.longitude,
          'in_radius_m': _radiusM,
          'in_kind': _kind,
        },
      );

      final entities = (response as List).cast<Map<String, dynamic>>();

      final newMarkers = <Marker>{};

      // Add user location marker
      newMarkers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _userLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'You are here',
          ),
        ),
      );

      // Add entity markers
      for (final entity in entities) {
        final id = '${entity['kind']}_${entity['id']}';
        final lat = (entity['lat'] as num).toDouble();
        final lng = (entity['lng'] as num).toDouble();
        final kind = entity['kind']?.toString() ?? '';

        // Choose marker color based on kind
        BitmapDescriptor icon;
        if (kind == 'trainer') {
          icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
        } else if (kind == 'nutritionist') {
          icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
        } else {
          icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
        }

        newMarkers.add(
          Marker(
            markerId: MarkerId(id),
            position: LatLng(lat, lng),
            icon: icon,
            infoWindow: InfoWindow(
              title: entity['name']?.toString() ?? 'Unknown',
              snippet: '${kind.capitalize()} • ${(entity['distance_m'] as num).round()}m',
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _selectedEntity = entity);
            },
          ),
        );
      }

      if (mounted) {
        setState(() {
          _markers
            ..clear()
            ..addAll(newMarkers);
          _selectedEntity = null;
        });

        // Animate camera to user location
        await _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_userLocation!, 13),
        );
      }
    } catch (e) {
      print('❌ [MAP] Error loading markers: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading nearby providers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _requestLocationPermission() async {
    final hasPermission = await _ensureLocationPermission();
    if (hasPermission) {
      await _init();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is required to show your location on the map'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1220) : const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          'Nearby',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            tooltip: 'My Location',
            onPressed: () async {
              if (_userLocation != null) {
                await _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(_userLocation!, 14),
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map - Always show map with default location
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _userLocation ?? const LatLng(17.3850, 78.4867),
                zoom: 12,
              ),
              myLocationEnabled: !_locationPermissionDenied,
              myLocationButtonEnabled: false,
              markers: _markers,
              onMapCreated: (controller) {
                _mapController = controller;
                // Move camera to user location if available
                if (_userLocation != null) {
                  controller.animateCamera(
                    CameraUpdate.newLatLngZoom(_userLocation!, 13),
                  );
                }
              },
              onTap: (_) {
                setState(() => _selectedEntity = null);
              },
              mapType: MapType.normal,
              zoomControlsEnabled: false,
              compassEnabled: true,
            ),
          ),

          // Top filter chips
          Positioned(
            left: 16,
            right: 16,
            top: 12,
            child: _FilterChips(
              value: _kind,
              onChanged: (kind) async {
                setState(() => _kind = kind);
                await _loadMarkers();
              },
              isDark: isDark,
            ),
          ),

          // Location permission denied banner
          if (_locationPermissionDenied)
            Positioned(
              left: 16,
              right: 16,
              top: 80,
              child: _LocationPermissionBanner(
                onEnable: _requestLocationPermission,
                isDark: isDark,
              ),
            ),

          // Bottom entity detail card
          if (_selectedEntity != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _EntityCard(
                data: _selectedEntity!,
                onView: () {
                  // TODO: Navigate to profile/center detail page
                  final kind = _selectedEntity!['kind']?.toString() ?? '';
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Opening ${kind.capitalize()} profile...'),
                    ),
                  );
                },
                isDark: isDark,
                supabase: _sb,
              ),
            ),

          // Loading overlay
          if (_loading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.15),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          
          // Error message if map fails to load (API key issue)
          if (!_loading && _userLocation == null)
            Positioned.fill(
              child: Container(
                color: isDark ? const Color(0xFF0B1220) : const Color(0xFFF6F7FB),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 64,
                          color: isDark ? Colors.white54 : Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Map not available',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please configure Google Maps API key\nin AndroidManifest.xml and Info.plist',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

// Filter Chips Widget
class _FilterChips extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final bool isDark;

  const _FilterChips({
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    Widget chip(String kind, String label, Color color) {
      final selected = value == kind;
      return ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF1F2937)),
          ),
        ),
        selected: selected,
        onSelected: (_) {
          HapticFeedback.lightImpact();
          onChanged(kind);
        },
        selectedColor: color,
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        elevation: selected ? 4 : 1,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      );
    }

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(20),
      color: isDark ? const Color(0xFF1F2937) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            chip('all', 'All', const Color(0xFF14B8A6)),
            chip('trainer', 'Trainers', const Color(0xFF8B5CF6)),
            chip('nutritionist', 'Nutritionists', const Color(0xFF10B981)),
            chip('center', 'Centers', const Color(0xFFF59E0B)),
          ],
        ),
      ),
    );
  }
}

// Location Permission Banner
class _LocationPermissionBanner extends StatelessWidget {
  final VoidCallback onEnable;
  final bool isDark;

  const _LocationPermissionBanner({
    required this.onEnable,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      color: isDark ? const Color(0xFF1F2937) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.location_off_rounded,
              color: const Color(0xFFF59E0B),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Location disabled',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Enable location to see providers near you',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onEnable,
              child: const Text(
                'Enable',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF14B8A6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Entity Card Widget
class _EntityCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onView;
  final bool isDark;
  final SupabaseClient supabase;

  const _EntityCard({
    required this.data,
    required this.onView,
    required this.isDark,
    required this.supabase,
  });
  
  String _getAvatarUrl(String? avatarPath) {
    if (avatarPath == null || avatarPath.isEmpty) return '';
    try {
      return supabase.storage.from('avatars').getPublicUrl(avatarPath);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final kind = data['kind']?.toString() ?? '';
    final name = data['name']?.toString() ?? 'Unknown';
    final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
    final distance = (data['distance_m'] as num?)?.round() ?? 0;
    final avatarUrl = data['avatar_url']?.toString();

    // Get color based on kind
    Color kindColor;
    IconData kindIcon;
    switch (kind) {
      case 'trainer':
        kindColor = const Color(0xFF8B5CF6);
        kindIcon = Icons.fitness_center_rounded;
        break;
      case 'nutritionist':
        kindColor = const Color(0xFF10B981);
        kindIcon = Icons.restaurant_menu_rounded;
        break;
      case 'center':
        kindColor = const Color(0xFFF59E0B);
        kindIcon = Icons.business_rounded;
        break;
      default:
        kindColor = const Color(0xFF14B8A6);
        kindIcon = Icons.person_rounded;
    }

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(20),
      color: isDark ? const Color(0xFF1F2937) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar/Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kindColor.withOpacity(0.1),
                border: Border.all(
                  color: kindColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: avatarUrl != null && avatarUrl.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        _getAvatarUrl(avatarUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            kindIcon,
                            color: kindColor,
                            size: 28,
                          );
                        },
                      ),
                    )
                  : Icon(
                      kindIcon,
                      color: kindColor,
                      size: 28,
                    ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        kindIcon,
                        size: 12,
                        color: kindColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        kind.capitalize(),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: kindColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.location_on_rounded,
                        size: 12,
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        distance < 1000
                            ? '${distance}m'
                            : '${(distance / 1000).toStringAsFixed(1)}km',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // View Button
            ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onView();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14B8A6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'View',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

