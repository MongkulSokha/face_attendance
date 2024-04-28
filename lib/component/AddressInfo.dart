import 'package:flutter/material.dart';

class AddressInfo extends StatefulWidget {
  const AddressInfo({super.key});

  @override
  State<AddressInfo> createState() => _AddressInfoState();
}

class _AddressInfoState extends State<AddressInfo> {
  Color primary = const Color(0xff1d83ec);
  Color grey = const Color(0xff9e9e9e);
  late final String text;
  late final void Function()? onPressed;
  late final bool isInTheDeliveryArea;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              child: MaterialButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(vertical: 5),
                onPressed: isInTheDeliveryArea == true ? onPressed : null,
                color: isInTheDeliveryArea == true ? primary : grey,
                textColor: Colors.white,
                child: Text(text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
