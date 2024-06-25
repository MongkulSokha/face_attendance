import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:face_attendance/view/check_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CircleSelectionScreen extends StatefulWidget {
  const CircleSelectionScreen({Key? key}) : super(key: key);

  @override
  _CircleSelectionScreenState createState() => _CircleSelectionScreenState();
}

class _CircleSelectionScreenState extends State<CircleSelectionScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _selectedLatLng;
  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Circle'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const CheckScreen(),
              ),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(11.524947, 104.884168),
              zoom: 18,
            ),
            onMapCreated: (controller) {
              _controller.complete(controller);
            },
            onTap: (latLng) {
              setState(() {
                _selectedLatLng = latLng;
              });
            },
            markers: _selectedLatLng == null
                ? {}
                : {
              Marker(
                markerId: const MarkerId('selected_location'),
                position: _selectedLatLng!,
              ),
            },
          ),
          if (_selectedLatLng != null)
            Positioned(
              bottom: 80,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Location Name',
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      // Save the selected location to Firestore
                      saveLocationToFirestore(_selectedLatLng!, _nameController.text);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CheckScreen(),
                        ),
                      );
                    },
                    child: const Text('Select this location'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> saveLocationToFirestore(LatLng latLng, String name) async {
    try {
      // Convert LatLng to GeoPoint
      GeoPoint geoPoint = GeoPoint(latLng.latitude, latLng.longitude);

      // Check if there is an existing document in Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('locations')
          .where('latitude', isEqualTo: latLng.latitude)
          .where('longitude', isEqualTo: latLng.longitude)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Update existing document
        await FirebaseFirestore.instance
            .collection('locations')
            .doc(querySnapshot.docs.first.id)
            .set({
          'latitude': latLng.latitude,
          'longitude': latLng.longitude,
          'name': name,
          // You can add more data if needed
        });
      } else {
        // Add new document
        await FirebaseFirestore.instance.collection('locations').add({
          'latitude': latLng.latitude,
          'longitude': latLng.longitude,
          'name': name,
          // You can add more data if needed
        });
      }

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location saved to Firestore')),
      );
    } catch (e) {
      // Show an error message if saving fails
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save location')),
      );
      print('Error saving location: $e');
    }
  }
}
