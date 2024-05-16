import 'dart:async';
import 'package:face_attendance/recognition/face_register.dart';
import 'package:face_attendance/recognition/live_face_recognition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../model/user.dart';
import 'check_screen.dart';

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

  late SharedPreferences sharedPreferences;

  @override
  void initState() {
    super.initState();
    _getRecord();
  }

  Future<void> _refresh() async {
    // Simulate fetching updated data
    await Future.delayed(
        const Duration(seconds: 2)); // Simulating a delay of 1 second

    // Update the _month variable with the current month
    setState(() {
      User.lastName;
      checkIn;
      checkOut;
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

  // void _getLocation() async {
  //   List<Placemark> placemark =
  //       await placemarkFromCoordinates(User.lat, User.long);
  //
  //   setState(() {
  //     location =
  //         "${placemark[0].street}, ${placemark[0].administrativeArea}, ${placemark[0].postalCode}, ${placemark[0].country}";
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
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
                margin: const EdgeInsets.only(top: 30),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CheckScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: screenWidth / 4, // Adjust the width and height as needed
                    height: screenWidth / 4,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xff1d83ec),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      checkIn == "--/--"
                          ? "Check-In"
                          : "Check-Out",
                      style: TextStyle(
                        color: Colors.white, // Change text color to make it visible on the button
                        fontSize: screenWidth / 24,
                        fontFamily: "NexaBold",
                      ),
                    ),
                  ),
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
              Container(
                margin: const EdgeInsets.only(top: 30),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const FaceRegister()));
                  },
                  child: Text(
                    "Face Register",
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: screenWidth / 20,
                      fontFamily: "NexaBold",
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
