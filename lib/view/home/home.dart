import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class HomeLivreur extends StatefulWidget {
  const HomeLivreur({super.key});

  @override
  State<HomeLivreur> createState() => _HomeLivreurState();
}

class _HomeLivreurState extends State<HomeLivreur> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _currentPosition;
  Set<Marker> _markers = {};
  String? _selectedRequestId;
  bool _isLoading = false;
  Set<Polyline> _polylines = {};
  bool _isNavigating = false;
  bool _isGoingToPickup = true;
  GeoPoint? _pickupLocation;
  GeoPoint? _deliveryLocation;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndGetLocation();
  }

  Future<void> _checkPermissionsAndGetLocation() async {
    var status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) {
      status = await Permission.locationWhenInUse.request();
      if (!status.isGranted) return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: _currentPosition!, zoom: 15),
    ));
  }

  Future<void> _acceptRequest(String requestId, GeoPoint pickup, GeoPoint delivery) async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Livreur not logged in');

      await FirebaseFirestore.instance
          .collection('delivery_requests')
          .doc(requestId)
          .update({
        'status': 'accepted',
        'acceptedBy': user.uid,
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _selectedRequestId = requestId;
        _pickupLocation = pickup;
        _deliveryLocation = delivery;
        _markers.add(
          Marker(
            markerId: const MarkerId('pickup'),
            position: LatLng(pickup.latitude, pickup.longitude),
            infoWindow: const InfoWindow(title: 'Pickup Location'),
          ),
        );
        _markers.add(
          Marker(
            markerId: const MarkerId('delivery'),
            position: LatLng(delivery.latitude, delivery.longitude),
            infoWindow: const InfoWindow(title: 'Delivery Location'),
          ),
        );
      });

      // Start navigation to pickup location
      _startNavigation(pickup);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery request accepted!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startNavigation(GeoPoint destination) async {
    if (_currentPosition == null) return;

    setState(() => _isNavigating = true);

    try {
      final apiKey = 'AIzaSyACYydOW1dwRcangSbJo8OAACG2SNv1XlE';
      final origin = '${_currentPosition!.latitude},${_currentPosition!.longitude}';
      final dest = '${destination.latitude},${destination.longitude}';
      
      final url = 'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$dest&mode=driving&key=$apiKey';
      
      print('Directions URL: $url');
      
      final response = await http.get(Uri.parse(url));
      print('Directions response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final routes = data['routes'] as List;
          if (routes.isNotEmpty) {
            final points = routes[0]['overview_polyline']['points'];
            final List<LatLng> decodedPoints = _decodePolyline(points);
            
            setState(() {
              _polylines.clear();
              _polylines.add(
                Polyline(
                  polylineId: const PolylineId('route'),
                  color: Colors.blue,
                  width: 5,
                  points: decodedPoints,
                ),
              );
            });

            // Fit the map to show the entire route
            if (_controller.isCompleted) {
              final controller = await _controller.future;
              controller.animateCamera(
                CameraUpdate.newLatLngBounds(
                  _getBoundsForPolyline(decodedPoints),
                  50, // padding
                ),
              );
            }
          }
        } else {
          print('Directions API Error: ${data['status']} - ${data['error_message'] ?? 'No error message'}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error getting directions: ${data['status']}')),
          );
        }
      } else {
        throw Exception('Failed to load directions: ${response.statusCode}');
      }
    } catch (e) {
      print('Navigation error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting directions: $e')),
      );
    }

    // Start location updates
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      if (_isNavigating) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
      }
    });
  }

  // Helper method to decode the polyline points
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      final p = LatLng(lat / 1E5, lng / 1E5);
      poly.add(p);
    }
    return poly;
  }

  // Helper method to get bounds for the polyline
  LatLngBounds _getBoundsForPolyline(List<LatLng> points) {
    double? minLat, maxLat, minLng, maxLng;
    
    for (var point in points) {
      if (minLat == null || point.latitude < minLat) minLat = point.latitude;
      if (maxLat == null || point.latitude > maxLat) maxLat = point.latitude;
      if (minLng == null || point.longitude < minLng) minLng = point.longitude;
      if (maxLng == null || point.longitude > maxLng) maxLng = point.longitude;
    }
    
    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  Future<void> _switchDestination() async {
    if (_isGoingToPickup && _deliveryLocation != null) {
      setState(() {
        _isGoingToPickup = false;
        _polylines.clear();
      });
      _startNavigation(_deliveryLocation!);
    } else if (!_isGoingToPickup && _pickupLocation != null) {
      setState(() {
        _isGoingToPickup = true;
        _polylines.clear();
      });
      _startNavigation(_pickupLocation!);
    }
  }

  Future<void> _stopNavigation() async {
    setState(() {
      _isNavigating = false;
      _polylines.clear();
      _selectedRequestId = null;
      _isGoingToPickup = true;
      _pickupLocation = null;
      _deliveryLocation = null;
      _markers.clear();
    });
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      print('Error signing out: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Requests'),
        backgroundColor: Colors.blue,
        actions: [
          if (_isNavigating) ...[
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              onPressed: _switchDestination,
              tooltip: 'Switch Destination',
            ),
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _stopNavigation,
              tooltip: 'Stop Navigation',
            ),
          ],
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition!,
                      zoom: 15,
                    ),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    markers: _markers,
                    polylines: _polylines,
                    onMapCreated: (GoogleMapController controller) {
                      _controller.complete(controller);
                    },
                  ),
                ),
                if (!_isNavigating)
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('delivery_requests')
                          .where('status', isEqualTo: 'pending')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(
                              child: Text('Something went wrong'));
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final requests = snapshot.data!.docs;

                        if (requests.isEmpty) {
                          return const Center(
                              child: Text('No pending delivery requests'));
                        }

                        return ListView.builder(
                          itemCount: requests.length,
                          itemBuilder: (context, index) {
                            final request = requests[index];
                            final data = request.data() as Map<String, dynamic>;
                            
                            // Add null checks for GeoPoint casting
                            final pickup = data['pickupLocation'] as GeoPoint?;
                            final delivery = data['deliveryLocation'] as GeoPoint?;

                            if (pickup == null || delivery == null) {
                              return const Card(
                                child: ListTile(
                                  title: Text('Invalid location data'),
                                  subtitle: Text('This request has missing location information'),
                                ),
                              );
                            }

                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                title: Text(
                                  'Client: ${data['clientName']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      'Pickup: ${data['pickupAddress']}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Delivery: ${data['deliveryAddress']}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    if (data['description']?.isNotEmpty ?? false) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Description: ${data['description']}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () => _acceptRequest(
                                          request.id, pickup, delivery),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Accept'),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }
} 