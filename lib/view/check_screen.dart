import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
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

  LatLng initialLocation = const LatLng(11.524947, 104.884168);

  bool isInSelectedArea = true;

  String location = " ";

  double screenHeight = 0;
  double screenWidth = 0;

  LocationData? currentLocation;

  String checkIn = "--/--";
  String checkOut = "--/--";

  Color primary = const Color(0xff1d83ec);

  late SharedPreferences sharedPreferences;

  @override
  void initState() {
    super.initState();
    fetchSelectedLocationFromFirestore();
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

  double circleRadius = 50.0; // Define the radius of the circle in meters

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

  Future<void> fetchSelectedLocationFromFirestore() async {
    try {
      // Retrieve selected location from Firestore
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('selected_location')
          .doc('location')
          .get();
      if (documentSnapshot.exists) {
        // Check if the data exists
        Map<String, dynamic>? data = documentSnapshot.data()
            as Map<String, dynamic>?; // Cast data to Map
        if (data != null) {
          double latitude =
              data['latitude'] as double; // Access latitude property
          double longitude =
              data['longitude'] as double; // Access longitude property
          setState(() {
            initialLocation = LatLng(latitude, longitude);
          });
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching selected location: $e');
    }
  }

  bool isLocationInsideSelectedArea(LatLng location) {
    // Calculate the distance between the current location and the center of the circle
    num distance = maps_tool.SphericalUtil.computeDistanceBetween(
      maps_tool.LatLng(location.latitude, location.longitude),
      maps_tool.LatLng(initialLocation.latitude, initialLocation.longitude),
    );
    return distance <=
        circleRadius; // Check if the distance is within the radius
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
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Center vertically
                children: [
                  Center(
                    child: CircularProgressIndicator(),
                  ),
                ],
              ),
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
                        onDragEnd: (LatLng updatedLatLng) {
                          setState(() {
                            initialLocation = updatedLatLng;
                            isInSelectedArea =
                                isLocationInsideSelectedArea(updatedLatLng);
                          });
                        },
                      ),
                    },
                    circles: {
                      Circle(
                        circleId: const CircleId("1"),
                        center: LatLng(initialLocation.latitude,
                            initialLocation.longitude),
                        radius: circleRadius,
                        fillColor: const Color(0xff1d83ec).withOpacity(0.1),
                        strokeWidth: 1,
                        strokeColor: Colors.blue,
                      )
                    },
                  ),
                ),
                isInSelectedArea
                    ? checkOut == "--/--" ? Container(
                        margin: const EdgeInsets.only(
                            top: 44, bottom: 10, right: 30, left: 30),
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
                                if (User.lat != 0) {
                                  // _getLocation();
                                  Future.delayed(
                                      const Duration(milliseconds: 500), () {
                                    key.currentState!.reset();
                                  });

                                  QuerySnapshot snap = await FirebaseFirestore
                                      .instance
                                      .collection("Student")
                                      .where('id', isEqualTo: User.studentId)
                                      .get();

                                  DocumentSnapshot snap2 =
                                      await FirebaseFirestore.instance
                                          .collection("Student")
                                          .doc(snap.docs[0].id)
                                          .collection("Record")
                                          .doc(DateFormat('dd MMMM yy')
                                              .format(DateTime.now()))
                                          .get();

                                  try {
                                    String checkIn = snap2['checkIn'];

                                    setState(() {
                                      checkOut = DateFormat('hh:mm')
                                          .format(DateTime.now());
                                    });

                                    await FirebaseFirestore.instance
                                        .collection("Student")
                                        .doc(snap.docs[0].id)
                                        .collection("Record")
                                        .doc(DateFormat('dd MMMM yy')
                                            .format(DateTime.now()))
                                        .update({
                                      'date': Timestamp.now(),
                                      'checkIn': checkIn,
                                      'checkOut': DateFormat('hh:mm')
                                          .format(DateTime.now()),
                                      'checkOutLocation': location,
                                    });
                                  } catch (e) {
                                    setState(() {
                                      checkIn = DateFormat('hh:mm')
                                          .format(DateTime.now());
                                    });
                                    await FirebaseFirestore.instance
                                        .collection("Student")
                                        .doc(snap.docs[0].id)
                                        .collection("Record")
                                        .doc(DateFormat('dd MMMM yy')
                                            .format(DateTime.now()))
                                        .set({
                                      'date': Timestamp.now(),
                                      'checkIn': DateFormat('hh:mm')
                                          .format(DateTime.now()),
                                      'checkOut': "--/--",
                                      'checkInLocation': location,
                                    });
                                  }
                                  key.currentState!.reset();
                                } else {
                                  Timer(
                                    const Duration(seconds: 3),
                                    () async {
                                      // _getLocation();

                                      Future.delayed(
                                          const Duration(milliseconds: 500),
                                          () {
                                        key.currentState!.reset();
                                      });

                                      QuerySnapshot snap =
                                          await FirebaseFirestore.instance
                                              .collection("Student")
                                              .where('id',
                                                  isEqualTo: User.studentId)
                                              .get();

                                      DocumentSnapshot snap2 =
                                          await FirebaseFirestore.instance
                                              .collection("Student")
                                              .doc(snap.docs[0].id)
                                              .collection("Record")
                                              .doc(DateFormat('dd MMMM yy')
                                                  .format(DateTime.now()))
                                              .get();

                                      try {
                                        String checkIn = snap2['checkIn'];

                                        setState(() {
                                          checkOut = DateFormat('hh:mm')
                                              .format(DateTime.now());
                                        });

                                        await FirebaseFirestore.instance
                                            .collection("Student")
                                            .doc(snap.docs[0].id)
                                            .collection("Record")
                                            .doc(DateFormat('dd MMMM yy')
                                                .format(DateTime.now()))
                                            .update({
                                          'date': Timestamp.now(),
                                          'checkIn': checkIn,
                                          'checkOut': DateFormat('hh:mm')
                                              .format(DateTime.now()),
                                          'checkOutLocation': location,
                                        });
                                      } catch (e) {
                                        setState(() {
                                          checkIn = DateFormat('hh:mm')
                                              .format(DateTime.now());
                                        });
                                        await FirebaseFirestore.instance
                                            .collection("Student")
                                            .doc(snap.docs[0].id)
                                            .collection("Record")
                                            .doc(DateFormat('dd MMMM yy')
                                                .format(DateTime.now()))
                                            .set({
                                          'date': Timestamp.now(),
                                          'checkIn': DateFormat('hh:mm')
                                              .format(DateTime.now()),
                                          'checkOut': "--/--",
                                          'checkInLocation': location,
                                        });
                                      }
                                      key.currentState!.reset();
                                    },
                                  );
                                }
                              },
                            );
                          },
                        ),
                      )
                    : const SizedBox() : const SizedBox(),
                Container(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: MaterialButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CircleSelectionScreen(),
                          ),
                        );
                      },
                      textColor: Colors.black,
                      child: const Text("Select Circle Geofence"),
                    ),
                  ),
                ),
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
