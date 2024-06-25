import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:face_attendance/recognition/live_face_recognition.dart';
import 'package:face_attendance/view/circle_geofence.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as maps_tool;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slide_to_act/slide_to_act.dart';

import '../model/user.dart';
import 'homescreen.dart';

class CheckScreen extends StatefulWidget {
  const CheckScreen({Key? key}) : super(key: key);

  @override
  State<CheckScreen> createState() => _CheckScreenState();
}

class _CheckScreenState extends State<CheckScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  BitmapDescriptor markerBitmap = BitmapDescriptor.defaultMarker;

  bool isInSelectedArea = false;

  double screenHeight = 0;
  double screenWidth = 0;

  LocationData? currentLocation;

  String checkIn = "--/--";
  String checkOut = "--/--";

  Color primary = const Color(0xff1d83ec);

  late SharedPreferences sharedPreferences;

  List<Map<String, dynamic>> geofenceAreas = [];
  double circleRadius = 25.0; // Define the radius of the circle in meters

  @override
  void initState() {
    super.initState();
    fetchSelectedLocationsFromFirestore();
    getCurrentLocation();
    _getRecord();
  }

  void _getRecord() async {
    try {
      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection("Student")
          .where('id', isEqualTo: User.studentId)
          .get();

      DocumentSnapshot snap2 = await FirebaseFirestore.instance
          .collection("Student")
          .doc(snap.docs[0].id)
          .collection("Record")
          .doc(DateFormat('dd MMMM yy').format(DateTime.now()))
          .get();

      setState(() {
        checkIn = snap2['checkIn'];
        checkOut = snap2['checkOut'];
      });
    } catch (e) {
      setState(() {
        checkIn = "--/--";
        checkOut = "--/--";
      });
    }
  }

  Future<void> getCurrentLocation() async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    location.onLocationChanged.listen(
          (newLoc) async {
        setState(() {
          currentLocation = newLoc;
          isInSelectedArea = isLocationInsideSelectedArea(
              LatLng(newLoc.latitude!, newLoc.longitude!));
        });
        GoogleMapController googleMapController = await _controller.future;
        googleMapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              zoom: 18,
              target: LatLng(
                newLoc.latitude!,
                newLoc.longitude!,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> fetchSelectedLocationsFromFirestore() async {
    try {
      // Retrieve selected locations from Firestore
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('locations')
          .get();

      List<Map<String, dynamic>> fetchedGeofenceAreas = [];
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        double latitude = data['latitude'];
        double longitude = data['longitude'];
        double radius = circleRadius;
        fetchedGeofenceAreas.add({
          'latitude': latitude,
          'longitude': longitude,
          'radius': radius,
        });
      }

      setState(() {
        geofenceAreas = fetchedGeofenceAreas;
      });
    } catch (e) {
      print('Error fetching selected locations: $e');
    }
  }

  bool isLocationInsideSelectedArea(LatLng location) {
    for (var area in geofenceAreas) {
      num distance = maps_tool.SphericalUtil.computeDistanceBetween(
        maps_tool.LatLng(location.latitude, location.longitude),
        maps_tool.LatLng(area['latitude'], area['longitude']),
      );
      if (distance <= area['radius']) {
        return true;
      }
    }
    return false;
  }

  void addCustomMarker() async {
    BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(),
      "assets/location_marker.png",
    ).then((markerIcon) {
      setState(() {
        markerBitmap = markerIcon;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check In/Out'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              ),
            );
          },
        ),
      ),
      body: currentLocation == null
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(currentLocation!.latitude!,
                    currentLocation!.longitude!),
                zoom: 18,
              ),
              onMapCreated: (controller) {
                _controller.complete(controller);
              },
              markers: {
                Marker(
                  icon: markerBitmap,
                  markerId: const MarkerId("marker"),
                  position: LatLng(currentLocation!.latitude!,
                      currentLocation!.longitude!),
                  draggable: true,
                ),
              },
              circles: geofenceAreas.map((area) {
                return Circle(
                  circleId: CircleId(area.toString()),
                  center: LatLng(area['latitude'], area['longitude']),
                  radius: area['radius'],
                  fillColor: const Color(0xff1d83ec).withOpacity(0.1),
                  strokeWidth: 1,
                  strokeColor: Colors.blue,
                );
              }).toSet(),
            ),
          ),
          if (isInSelectedArea)
            checkOut == "--/--"
                ? Container(
              margin: const EdgeInsets.all(20.0),
              child: Builder(
                builder: (context) {
                  final GlobalKey<SlideActionState> key = GlobalKey();

                  return SlideAction(
                    sliderButtonIcon: const Icon(
                      FontAwesomeIcons.arrowRight,
                      color: Colors.white,
                    ),
                    submittedIcon: Icon(
                      FontAwesomeIcons.check,
                      color: primary,
                    ),
                    text: checkIn == "--/--"
                        ? "Slide to Check In"
                        : "Slide to Check Out",
                    textStyle: TextStyle(
                      color: Colors.black54,
                      fontFamily: "NexaRegular",
                      fontSize: screenWidth / 20,
                    ),
                    outerColor: Colors.white,
                    innerColor: primary,
                    key: key,
                    onSubmit: () async {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          const LiveRecognition(),
                        ),
                      );
                    },
                  );
                },
              ),
            )
                : const SizedBox(),
          if (!isInSelectedArea)
            const Text(
              'Your location is outside the selected area.',
              style: TextStyle(color: Colors.red),
            ),
        ],
      ),
    );
  }
}

