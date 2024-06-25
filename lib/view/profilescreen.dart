import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../model/user.dart';
import '../recognition/face_register.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double screenHeight = 0;
  double screenWidth = 0;

  Color primary = const Color(0xff1d83ec);

  String birth = "Date of Birth";

  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refresh(); // Initial data load
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refresh(); // Reload data when dependencies change (e.g., when the screen becomes active)
  }

  Future<void> _refresh() async {
    // Simulate fetching updated data
    await Future.delayed(const Duration(seconds: 2)); // Simulating a delay of 2 seconds

    // Fetch updated data from Firestore
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection("Student").doc(User.id).get();
    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

    // Update the User model with the fetched data
    setState(() {
      User.firstName = userData['firstName'];
      User.lastName = userData['lastName'];
      User.birthDate = userData['birthDate'];
      User.address = userData['address'];
      User.profilePicLink = userData['profilePic'];
      User.canEdit = userData['canEdit'];
      birth = User.birthDate; // Update birth with the fetched birthDate
    });
  }

  void pickUploadProfilePic() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxHeight: 512,
      maxWidth: 512,
      imageQuality: 90,
    );

    Reference ref = FirebaseStorage.instance
        .ref()
        .child("${User.studentId.toLowerCase()}_profilepic.jpg");

    await ref.putFile(File(image!.path));

    ref.getDownloadURL().then((value) async {
      setState(() {
        User.profilePicLink = value;
      });

      await FirebaseFirestore.instance
          .collection("Student")
          .doc(User.id)
          .update({
        'profilePic': value,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Column(
              children: [
                GestureDetector(
                  onTap: () {
                    pickUploadProfilePic();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(top: 80, bottom: 24),
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: primary,
                    ),
                    child: Center(
                      child: User.profilePicLink == " "
                          ? const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 80,
                      )
                          : ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(User.profilePicLink),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    "${User.firstName} ${User.lastName}",
                    style: const TextStyle(
                      fontFamily: "NexaBold",
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 24,
                ),
                User.canEdit
                    ? textField("First Name", User.firstName, firstNameController)
                    : field("First Name", User.firstName),
                User.canEdit
                    ? textField("Last Name", User.lastName, lastNameController)
                    : field("Last Name", User.lastName),
                User.canEdit
                    ? GestureDetector(
                    onTap: () {
                      showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: primary,
                                secondary: primary,
                                onSecondary: Colors.white,
                              ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: primary,
                                ),
                              ),
                              textTheme: const TextTheme(
                                headlineMedium: TextStyle(
                                  fontFamily: "NexaBold",
                                ),
                                labelSmall: TextStyle(
                                  fontFamily: "NexaBold",
                                ),
                                labelLarge: TextStyle(
                                  fontFamily: "NexaBold",
                                ),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      ).then((value) {
                        setState(() {
                          birth = DateFormat("MM/dd/yyyy").format(value!);
                        });
                      });
                    },
                    child: field("Date of Birth", birth))
                    : field("Date of Birth", User.birthDate),
                User.canEdit
                    ? textField("Address", User.address, addressController)
                    : field("Address", User.address),
                User.canEdit
                    ? GestureDetector(
                  onTap: () async {
                    String firstName = firstNameController.text;
                    String lastName = lastNameController.text;
                    String birthDate = birth;
                    String address = addressController.text;

                    if (User.canEdit) {
                      if (firstName.isEmpty) {
                        showSnakeBar("Please enter your first name!");
                      } else if (lastName.isEmpty) {
                        showSnakeBar("Please enter your last name!");
                      } else if (birthDate.isEmpty) {
                        showSnakeBar("Please enter your birth date!");
                      } else if (address.isEmpty) {
                        showSnakeBar("Please enter your address!");
                      } else {
                        await FirebaseFirestore.instance
                            .collection("Student")
                            .doc(User.id)
                            .update({
                          'firstName': firstName,
                          'lastName': lastName,
                          'birthDate': birthDate,
                          'address': address,
                          'canEdit': false,
                        }).then((value) {
                          setState(() {
                            User.canEdit = false;
                            User.firstName = firstName;
                            User.lastName = lastName;
                            User.birthDate = birthDate;
                            User.address = address;
                          });
                        });
                      }
                    } else {
                      showSnakeBar(
                          "Please can't edit anymore, please contact support team.");
                    }
                  },
                  child: Container(
                    height: kToolbarHeight,
                    width: screenWidth,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.only(left: 11),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: primary,
                    ),
                    child: const Center(
                      child: Text(
                        "SAVE",
                        style: TextStyle(
                          fontFamily: "NexaBold",
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                )
                    : const SizedBox(),
              ],
            ),
            User.canEdit
                ? Container(
              margin: const EdgeInsets.only(top: 30),
              alignment: Alignment.center,
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
            ): SizedBox(),
          ],
        ),
      ),
    );
  }

  Widget field(String title, String text) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: "NexaBold",
              color: Colors.black54,
            ),
          ),
        ),
        Container(
          height: kToolbarHeight,
          width: screenWidth,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.only(left: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.black54,
            ),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: "NexaBold",
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget textField(
      String title, String hint, TextEditingController controller) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: "NexaBold",
              color: Colors.black54,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: controller,
            cursorColor: Colors.black54,
            maxLines: 1,
            decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                    color: Colors.black54, fontFamily: "NexaBold"),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.black54,
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.black54,
                    ))),
          ),
        ),
      ],
    );
  }

  void showSnakeBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          text,
        ),
      ),
    );
  }
}
