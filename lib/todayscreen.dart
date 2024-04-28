import 'dart:async';
import 'package:face_attendance/google_map_screen.dart';
import 'package:geocoding/geocoding.dart'; // Import geocoding package
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:intl/intl.dart';

import 'model/user.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  double screenHeight = 0;
  double screenWidth = 0;

  String checkIn = "--/--";
  String checkOut = "--/--";
  String location = " ";

  Color primary = const Color(0xff1d83ec);

  late GeoFlutterFire geo;
  bool isInsideGeofence = false;
  late SharedPreferences sharedPreferences;

  @override
  void initState() {
    super.initState();
    _getRecord();
  }

  void _getLocation() async {
    List<Placemark> placemark =
        await placemarkFromCoordinates(User.lat, User.long);

    setState(() {
      location =
          "${placemark[0].street}, ${placemark[0].administrativeArea}, ${placemark[0].postalCode}, ${placemark[0].country}";
    });
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

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              alignment: Alignment.centerLeft,
              margin: const EdgeInsets.only(top: 32),
              child: Text(
                "Welcome",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: screenWidth / 20,
                  fontFamily: "NexaRegular",
                ),
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              child: Text(
                User.lastName,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: screenWidth / 14,
                  fontFamily: "NexaBold",
                ),
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              margin: const EdgeInsets.only(top: 32),
              child: Text(
                "Today's Status",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: screenWidth / 18,
                  fontFamily: "NexaBold",
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 32),
              height: 150,
              decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 2,
                      offset: Offset(1, 1),
                    )
                  ],
                  borderRadius: BorderRadius.all(Radius.circular(20))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Check In",
                          style: TextStyle(
                            fontFamily: "NexaRegular",
                            fontSize: screenWidth / 20,
                          ),
                        ),
                        Text(
                          checkIn,
                          style: TextStyle(
                            fontFamily: "NexaBold",
                            fontSize: screenWidth / 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Check Out",
                          style: TextStyle(
                            fontFamily: "NexaRegular",
                            fontSize: screenWidth / 20,
                          ),
                        ),
                        Text(
                          checkOut,
                          style: TextStyle(
                            fontFamily: "NexaBold",
                            fontSize: screenWidth / 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              child: RichText(
                text: TextSpan(
                  text: DateTime.now().day.toString(),
                  style: TextStyle(
                    fontFamily: "NexaBold",
                    color: primary,
                    fontSize: screenWidth / 18,
                  ),
                  children: [
                    TextSpan(
                      text: DateFormat(' MMMM yy').format(DateTime.now()),
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: "NexaBold",
                        fontSize: screenWidth / 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            StreamBuilder(
                stream: Stream.periodic(const Duration(seconds: 1)),
                builder: (context, snapshot) {
                  return Container(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      DateFormat('hh:mm:ss a').format(DateTime.now()),
                      style: TextStyle(
                        fontFamily: "NexaRegular",
                        fontSize: screenWidth / 20,
                        color: Colors.black54,
                      ),
                    ),
                  );
                }),
            checkOut == "--/--"
                ? Container(
                    margin: const EdgeInsets.only(top: 24, bottom: 40),
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
                              _getLocation();

                              Future.delayed(const Duration(milliseconds: 500),
                                  () {
                                key.currentState!.reset();
                              });

                              QuerySnapshot snap = await FirebaseFirestore
                                  .instance
                                  .collection("Student")
                                  .where('id', isEqualTo: User.studentId)
                                  .get();

                              DocumentSnapshot snap2 = await FirebaseFirestore
                                  .instance
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
                              Timer(const Duration(seconds: 3), () async {
                                _getLocation();

                                Future.delayed(
                                    const Duration(milliseconds: 500), () {
                                  key.currentState!.reset();
                                });

                                QuerySnapshot snap = await FirebaseFirestore
                                    .instance
                                    .collection("Student")
                                    .where('id', isEqualTo: User.studentId)
                                    .get();

                                DocumentSnapshot snap2 = await FirebaseFirestore
                                    .instance
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
                              });
                            }
                          },
                        );
                      },
                    ),
                  )
                : Container(
                    margin: const EdgeInsets.only(top: 37, bottom: 12),
                    child: Text(
                      "You have completed Today :)",
                      style: TextStyle(
                        color: Colors.black54,
                        fontFamily: "NexaBold",
                        fontSize: screenWidth / 20,
                      ),
                    ),
                  ),
            location != " "
                ? Text(
                    "Location: $location",
                  )
                : const SizedBox(),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const GoogleMapScreen()));
              },
              child: Text(
                "Check Geofence",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: screenWidth / 20,
                  fontFamily: "NexaBold",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
