import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:face_attendance/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ntp/ntp.dart';

import '../model/user.dart';
import 'calendarscreen.dart';
import 'profilescreen.dart';
import 'todayscreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double screenHeight = 0;
  double screenWidth = 0;

  Color primary = const Color(0xff1d83ec);

  int currentIndex = 1;

  bool timeManipulated = false;
  late Timer _timer;

  List<IconData> navigationIcons = [
    FontAwesomeIcons.calendarDay,
    FontAwesomeIcons.checkToSlot,
    FontAwesomeIcons.circleUser,
  ];

  @override
  void initState() {
    super.initState();
    _startLocationService();

    getId().then((value) {
      _getCredentials();
      _getProfilePic();
    });
    startLiveDetection();
  }

  @override
  void dispose() {
    // Dispose the timer when the widget is disposed
    _timer.cancel();
    super.dispose();
  }

  void startLiveDetection() {
    // Define a periodic timer to check time manipulation every second
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      checkTimeManipulation();
    });
  }

  Future<void> checkTimeManipulation() async {
    try {
      DateTime currentTime = DateTime.now();
      DateTime serverTime = await NTP.now();
      Duration difference = serverTime.difference(currentTime);
      Duration threshold = const Duration(seconds: 5);
      if (difference.abs() > threshold) {
        setState(() {timeManipulated = true;});
      } else {
        setState(() {timeManipulated = false;});
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _getCredentials() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("Student")
          .doc(User.id)
          .get();
      setState(() {
        User.canEdit = doc['canEdit'];
        User.firstName = doc['firstName'];
        User.lastName = doc['lastName'];
        User.birthDate = doc['birthDate'];
        User.address = doc['address'];
      });
    } catch (e) {
      return;
    }
  }

  void _getProfilePic() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection("Student")
        .doc(User.id)
        .get();
    setState(() {
      User.profilePicLink = doc['profilePic'];
    });
  }

  void _startLocationService() async {
    LocationService().initialize();

    LocationService().getLongtitute().then((value) {
      setState(() {
        User.long = value!;
      });

      LocationService().getLatitute().then((value) {
        setState(() {
          User.lat = value!;
        });
      });
    });
  }

  Future<void> getId() async {
    QuerySnapshot snap = await FirebaseFirestore.instance
        .collection("Student")
        .where('id', isEqualTo: User.studentId)
        .get();

    setState(() {
      User.id = snap.docs[0].id;
    });
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    if (timeManipulated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Time Manipulation Detected'),
        ),
        body: const Center(
          child: Text(
            'Please restart the app.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      return Scaffold(
        body: IndexedStack(
          index: currentIndex,
          children: const [
            CalendarScreen(),
            TodayScreen(),
            ProfileScreen(),
          ],
        ),
        bottomNavigationBar: Container(
          height: 70,
          margin: const EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: 24,
          ),
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(40)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 2,
                  offset: Offset(1, 1),
                )
              ]),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(40)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < navigationIcons.length; i++) ...<Expanded>{
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          currentIndex = i;
                        });
                      },
                      child: Container(
                        height: screenHeight,
                        width: screenWidth,
                        color: Colors.white,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                navigationIcons[i],
                                color: i == currentIndex
                                    ? primary
                                    : Colors.black54,
                                size: i == currentIndex ? 27 : 24,
                              ),
                              i == currentIndex
                                  ? Container(
                                      margin: const EdgeInsets.only(top: 6),
                                      height: 3,
                                      width: 22,
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(40)),
                                        color: primary,
                                      ),
                                    )
                                  : const SizedBox(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                }
              ],
            ),
          ),
        ),
      );
    }
  }
}
