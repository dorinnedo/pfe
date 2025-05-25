import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:http/http.dart' as http;

class Prediction {
  final String? description;
  final String? placeId;

  Prediction({
    this.description,
    this.placeId,
  });
}

class HomeClient extends StatefulWidget {
  const HomeClient({super.key});

  @override
  State<HomeClient> createState() => _HomeClientState();
}

class _HomeClientState extends State<HomeClient> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _currentPosition;
  LatLng? _pickupLocation;
  LatLng? _deliveryLocation;
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();
  bool _isLoading = false;
  String? _pickupAddress;
  String? _deliveryAddress;
  Set<Marker> _markers = {};
  bool _isSelectingPickup = true;
  List<Prediction> _predictions = [];
  bool _isSearching = false;
  bool _showBottomUI = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndGetLocation();
  }

  Future<void> _checkPermissionsAndGetLocation() async {
    try {
      var status = await Permission.locationWhenInUse.status;
      if (!status.isGranted) {
        status = await Permission.locationWhenInUse.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is required')),
          );
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _pickupLocation = _currentPosition;
      });

      await _getAddressFromLatLng(_pickupLocation!, true);

      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentPosition!, zoom: 15),
      ));
    } catch (e) {
      print('Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  Future<void> _getAddressFromLatLng(LatLng location, bool isPickup) async {
    try {
      List<geocoding.Placemark> placemarks = await geocoding.placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        geocoding.Placemark place = placemarks[0];
        String address = '';
        
        if (place.street?.isNotEmpty ?? false) address += '${place.street}, ';
        if (place.locality?.isNotEmpty ?? false) address += '${place.locality}, ';
        if (place.subLocality?.isNotEmpty ?? false) address += '${place.subLocality}, ';
        if (place.administrativeArea?.isNotEmpty ?? false) address += '${place.administrativeArea}, ';
        if (place.country?.isNotEmpty ?? false) address += place.country!;

        address = address.trim();
        if (address.endsWith(',')) {
          address = address.substring(0, address.length - 1);
        }

        setState(() {
          if (isPickup) {
            _pickupAddress = address;
          } else {
            _deliveryAddress = address;
          }
        });
      }
    } catch (e) {
      print('Error getting address: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting address: $e')),
      );
    }
  }

  void _onMapTap(LatLng location) {
    setState(() {
      if (_isSelectingPickup) {
        _pickupLocation = location;
        _getAddressFromLatLng(location, true);
        _markers.removeWhere((marker) => marker.markerId.value == 'pickup');
        _markers.add(
          Marker(
            markerId: const MarkerId('pickup'),
            position: location,
            infoWindow: const InfoWindow(title: 'Pickup Location'),
          ),
        );
      } else {
        _deliveryLocation = location;
        _getAddressFromLatLng(location, false);
        _markers.removeWhere((marker) => marker.markerId.value == 'delivery');
        _markers.add(
          Marker(
            markerId: const MarkerId('delivery'),
            position: location,
            infoWindow: const InfoWindow(title: 'Delivery Location'),
          ),
        );
      }
    });
  }

  Future<void> _submitDeliveryRequest() async {
    if (!_formKey.currentState!.validate() || 
        _pickupLocation == null || 
        _deliveryLocation == null || 
        _pickupAddress == null || 
        _deliveryAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both pickup and delivery locations')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      await FirebaseFirestore.instance.collection('delivery_requests').add({
        'clientId': user.uid,
        'clientName': user.displayName ?? 'Anonymous',
        'pickupAddress': _pickupAddress,
        'deliveryAddress': _deliveryAddress,
        'pickupLocation': GeoPoint(_pickupLocation!.latitude, _pickupLocation!.longitude),
        'deliveryLocation': GeoPoint(_deliveryLocation!.latitude, _deliveryLocation!.longitude),
        'description': _descriptionController.text,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery request submitted successfully!')),
      );

      _descriptionController.clear();
      setState(() {
        _deliveryLocation = null;
        _deliveryAddress = null;
        _markers.removeWhere((marker) => marker.markerId.value == 'delivery');
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _predictions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final apiKey = 'AIzaSyDF_5GGZiW8qoKfWHzPIfe3qi5JpbIsI8k';
      final baseUrl = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
      
      String locationBias = '';
      if (_currentPosition != null) {
        locationBias = '&location=${_currentPosition!.latitude},${_currentPosition!.longitude}&radius=50000';
      }

      final encodedQuery = Uri.encodeComponent(query);
      final url = '$baseUrl?input=$encodedQuery&types=address,establishment&language=fr&components=country:fr$locationBias&key=$apiKey';
      
      print('Search URL: $url');
      
      final response = await http.get(Uri.parse(url));
      print('Search response status: ${response.statusCode}');
      print('Search response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['predictions'] != null) {
          final predictions = (data['predictions'] as List)
              .map((p) => Prediction(
                    description: p['description'],
                    placeId: p['place_id'],
                  ))
              .toList();

          setState(() {
            _predictions = predictions;
            _isSearching = false;
          });
        } else {
          print('API Error: ${data['status']} - ${data['error_message'] ?? 'No error message'}');
          setState(() {
            _predictions = [];
            _isSearching = false;
          });
        }
      } else {
        throw Exception('Failed to load places: ${response.statusCode}');
      }
    } catch (e) {
      print('Search error: $e');
      setState(() {
        _predictions = [];
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching places: $e')),
      );
    }
  }

  Future<void> _selectPlace(Prediction prediction) async {
    try {
      print('Selected place: ${prediction.description}');
      final apiKey = 'AIzaSyDF_5GGZiW8qoKfWHzPIfe3qi5JpbIsI8k';
      final baseUrl = 'https://maps.googleapis.com/maps/api/place/details/json';
      
      final url = '$baseUrl?place_id=${prediction.placeId}&fields=geometry,formatted_address&key=$apiKey';
      
      print('Details URL: $url');
      
      final response = await http.get(Uri.parse(url));
      print('Details response status: ${response.statusCode}');
      print('Details response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['result'] != null) {
          final result = data['result'];
          final location = result['geometry']['location'];
          final lat = location['lat'];
          final lng = location['lng'];

          setState(() {
            _searchController.text = prediction.description ?? '';
            _predictions = [];
            if (_isSelectingPickup) {
              _pickupLocation = LatLng(lat, lng);
              _pickupAddress = prediction.description;
              _markers.removeWhere((marker) => marker.markerId.value == 'pickup');
              _markers.add(
                Marker(
                  markerId: const MarkerId('pickup'),
                  position: _pickupLocation!,
                  infoWindow: InfoWindow(title: 'Pickup Location', snippet: prediction.description),
                ),
              );
            } else {
              _deliveryLocation = LatLng(lat, lng);
              _deliveryAddress = prediction.description;
              _markers.removeWhere((marker) => marker.markerId.value == 'delivery');
              _markers.add(
                Marker(
                  markerId: const MarkerId('delivery'),
                  position: _deliveryLocation!,
                  infoWindow: InfoWindow(title: 'Delivery Location', snippet: prediction.description),
                ),
              );
            }
          });

          if (_controller.isCompleted) {
            final controller = await _controller.future;
            controller.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: LatLng(lat, lng),
                  zoom: 15,
                ),
              ),
            );
          }
        } else {
          print('API Error: ${data['status']} - ${data['error_message'] ?? 'No error message'}');
        }
      } else {
        throw Exception('Failed to load place details: ${response.statusCode}');
      }
    } catch (e) {
      print('Select place error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting place details: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Delivery'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: _isSelectingPickup ? 'Search pickup location...' : 'Search delivery location...',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _isSearching
                                    ? const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              onChanged: _searchPlaces,
                            ),
                          ),
                          if (_predictions.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ListView.builder(
                                itemCount: _predictions.length,
                                itemBuilder: (context, index) {
                                  final prediction = _predictions[index];
                                  return ListTile(
                                    leading: const Icon(Icons.location_on),
                                    title: Text(
                                      prediction.description ?? '',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    onTap: () => _selectPlace(prediction),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
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
                        onMapCreated: (GoogleMapController controller) {
                          if (!_controller.isCompleted) {
                            _controller.complete(controller);
                          }
                        },
                        onTap: _onMapTap,
                      ),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: () {
                      setState(() {
                        _showBottomUI = !_showBottomUI;
                      });
                    },
                    child: Icon(_showBottomUI ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up),
                  ),
                ),
                if (_showBottomUI)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: GestureDetector(
                      onVerticalDragEnd: (details) {
                        if (details.primaryVelocity! > 0) {
                          // Swipe up
                          setState(() => _showBottomUI = false);
                        }
                      },
                      child: Container(
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Request Details',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    setState(() => _showBottomUI = false);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            setState(() => _isSelectingPickup = true);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _isSelectingPickup 
                                                ? Colors.blue 
                                                : Colors.grey[300],
                                          ),
                                          child: const Text('Pickup Location'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            setState(() => _isSelectingPickup = false);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: !_isSelectingPickup 
                                                ? Colors.blue 
                                                : Colors.grey[300],
                                          ),
                                          child: const Text('Delivery Location'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  if (_pickupAddress != null)
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Pickup: $_pickupAddress',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  if (_deliveryAddress != null) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Delivery: $_deliveryAddress',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _descriptionController,
                                    decoration: const InputDecoration(
                                      labelText: 'Description (optional)',
                                      border: OutlineInputBorder(),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    maxLines: 3,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _isLoading ? null : _submitDeliveryRequest,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const CircularProgressIndicator()
                                        : const Text(
                                            'Request Delivery',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}