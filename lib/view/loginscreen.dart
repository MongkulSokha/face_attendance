import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/user.dart';
import 'homescreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController idController = TextEditingController();
  TextEditingController passController = TextEditingController();

  double screenHeight = 0;
  double screenWidth = 0;

  Color primary = const Color(0xff1d83ec);

  late SharedPreferences sharedPreferences;

  bool isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible =
    KeyboardVisibilityProvider.isKeyboardVisible(context);
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        child: Column(
          children: [
            isKeyboardVisible
                ? SizedBox(
              height: screenHeight / 16,
            )
                : Container(
              height: screenHeight / 3,
              width: screenWidth,
              decoration: BoxDecoration(
                color: primary,
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(50),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: screenWidth / 5,
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(
                  top: screenHeight / 30, bottom: screenHeight / 30),
              child: Text(
                "Login",
                style: TextStyle(
                  fontSize: screenWidth / 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              margin: EdgeInsets.symmetric(horizontal: screenWidth / 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  fieldTitle("Student ID:"),
                  customField("Enter your Student ID", idController, false, Icons.person),
                  fieldTitle("Password:"),
                  customField("Enter your Password", passController, true, Icons.lock),
                  GestureDetector(
                    onTap: () async {
                      FocusScope.of(context).unfocus();
                      String id = idController.text.trim();
                      String password = passController.text.trim();

                      if (id.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Student id is still empty!")));
                      } else if (password.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Password is still empty!")));
                      } else {
                        QuerySnapshot snap = await FirebaseFirestore.instance
                            .collection("Student")
                            .where('id', isEqualTo: id)
                            .get();

                        try {
                          if (password == snap.docs[0]['password']) {
                            sharedPreferences = await SharedPreferences.getInstance();

                            sharedPreferences.setString('studentId', id).then((_) {
                              Navigator.pushReplacement(context, MaterialPageRoute(
                                  builder: (context) => const HomeScreen())
                              );
                            });
                          } else {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text("Password incorrect"),
                            ));
                          }
                        } catch (e) {
                          String error = " ";
                          if (e.toString() ==
                              "RangeError (index): Invalid value: Valid value range is empty: 0") {
                            setState(() {
                              error = "Employee id does not exist!";
                            });
                          } else {
                            setState(() {
                              error = "Error occurred!";
                            });
                          }

                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(error),
                          ));
                        }
                      }
                    },
                    child: Container(
                      height: 60,
                      width: screenWidth,
                      decoration: BoxDecoration(
                          color: primary,
                          borderRadius:
                          const BorderRadius.all(Radius.circular(30))),
                      child: Center(
                        child: Text(
                          "LOGIN",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth / 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget fieldTitle(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: screenWidth / 26,
        ),
      ),
    );
  }

  Widget customField(
      String hint, TextEditingController controller, bool obscure, IconData icon) {
    return Container(
      width: screenWidth,
      margin: EdgeInsets.only(bottom: screenHeight / 30),
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(12)),
          boxShadow: [
            BoxShadow(
                color: Colors.black26, blurRadius: 2, offset: Offset(1, 1))
          ]),
      child: Row(
        children: [
          SizedBox(
            width: screenWidth / 8,
            child: Icon(
              icon,
              color: primary,
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: screenWidth / 20),
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    vertical: screenHeight / 45,
                  ),
                  border: InputBorder.none,
                  hintText: hint,
                  suffixIcon: obscure ? IconButton(
                    icon: Icon(
                      isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: primary,
                    ),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ) : null,
                ),
                maxLines: 1,
                obscureText: obscure && !isPasswordVisible,
              ),
            ),
          )
        ],
      ),
    );
  }
}
