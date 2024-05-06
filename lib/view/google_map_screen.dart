import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as maps_tool;

import 'homescreen.dart';

class GoogleMapScreen extends StatefulWidget {
  const GoogleMapScreen({super.key});

  @override
  State<GoogleMapScreen> createState() => _GoogleMapScreenState();
}

class _GoogleMapScreenState extends State<GoogleMapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  BitmapDescriptor markerBitmap = BitmapDescriptor.defaultMarker;

  LatLng initialLocation = const LatLng(11.524947, 104.884168);

  bool isInSelectedArea = true;

  LocationData? currentLocation;

  @override
  void initState() {
    addCustomMarker();
    getCurrentLocation();
    super.initState();
  }

  List<LatLng> selectedAreaCoordinates = const [
    LatLng(11.524994, 104.884192),
    LatLng(11.524984, 104.884121),
    LatLng(11.524873, 104.884133),
    LatLng(11.524885, 104.884207),
  ];

  void getCurrentLocation() async {
    Location location = Location();
    location.getLocation().then(
          (location) {
        currentLocation = location;
      },
    );
    GoogleMapController googleMapController = await _controller.future;
    location.onLocationChanged.listen(
          (newLoc) {
        currentLocation = newLoc;
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
        setState(() {});
      },
    );
  }

  bool isLocationInsideSelectedArea(LatLng location) {
    return maps_tool.PolygonUtil.containsLocation(
      maps_tool.LatLng(location.latitude, location.longitude),
      selectedAreaCoordinates
          .map((e) => maps_tool.LatLng(e.latitude, e.longitude))
          .toList(),
      false,
    );
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
    return Scaffold(
      body: currentLocation == null
          ? Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 40),
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: MaterialButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomeScreen(),
                    ),
                  );
                },
                textColor: Colors.black,
                child: const Icon(Icons.arrow_back),
              ),
            ),
          ),
          const Center(child: Text("Loading")),
        ],
      )
          :Column(
        children: [
          Container(
            alignment: Alignment.centerLeft,
            margin: const EdgeInsets.only(top: 40),
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: MaterialButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomeScreen(),
                    ),
                  );
                },
                textColor: Colors.black,
                child: const Icon(Icons.arrow_back),
              ),
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
                zoom: 18,
              ),
              onMapCreated: (controller) {
                _controller.complete(controller);
              },
              markers: {
                Marker(
                  icon: markerBitmap,
                  markerId: const MarkerId("marker"),
                  position: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
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
              polygons: {
                Polygon(
                  polygonId: const PolygonId("1"),
                  fillColor: const Color(0xff1d83ec).withOpacity(0.1),
                  strokeWidth: 1,
                  points: selectedAreaCoordinates,
                )
              },
              onCameraMove: (CameraPosition position) {
                setState(() {
                  isInSelectedArea = isLocationInsideSelectedArea(position.target);
                  initialLocation = position.target;
                });
              },
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
