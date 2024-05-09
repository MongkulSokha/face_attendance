import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../ml/Recognition.dart';
import '../ml/recognizer.dart';
import '../view/homescreen.dart';

class FaceRegistrationScreen extends StatefulWidget {
  const FaceRegistrationScreen({super.key});

  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  late ImagePicker imagePicker;
  File? _image;

  late FaceDetector faceDetector;

  late Recognizer recognizer;

  @override
  void initState() {
    super.initState();
    imagePicker = ImagePicker();

    final options = FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate);
    faceDetector = FaceDetector(options: options);

    recognizer = Recognizer();
  }

  _imgFromGallery() async {
    XFile? pickedFile =
        await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        doFaceDetection();
      });
    }
  }

  _imgFromCamera() async {
    XFile? pickedFile = await imagePicker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        doFaceDetection();
      });
    }
  }

  List<Face> faces = [];

  doFaceDetection() async {
    InputImage inputImage = InputImage.fromFile(_image!);

    // image = await _image?.readAsBytes();
    image = await decodeImageFromList(_image!.readAsBytesSync());

    faces = await faceDetector.processImage(inputImage);

    for (Face face in faces) {
      final Rect boundingBox = face.boundingBox;
      // print("Rect =" + boundingBox.toString());

      num left = boundingBox.left<0?0:boundingBox.left;
      num top = boundingBox.top<0?0:boundingBox.top ;
      num right = boundingBox.right>image.width?image.width-1:boundingBox.right;
      num bottom = boundingBox.bottom>image.height?image.height-1:boundingBox.bottom;
      num width = right - left;
      num height = bottom - top;

      final bytes = _image!.readAsBytesSync();
      img.Image? faceImg = img.decodeImage(bytes!);
      img.Image croppedFace = img.copyCrop(faceImg!, x: left.toInt(), y: top.toInt(), width: width.toInt(), height: height.toInt());
      Recognition recognition = recognizer.recognize(croppedFace, boundingBox);
      showFaceRegistrationDialogue(Uint8List.fromList(img.encodeBmp(croppedFace)), recognition);
    }
    drawRectangleAroundFaces();
  }

  removeRotation(File inputImage) async {
    final img.Image? capturedImage =
        img.decodeImage(await File(inputImage.path).readAsBytes());
    final img.Image orientedImage = img.bakeOrientation(capturedImage!);
    return await File(_image!.path).writeAsBytes(img.encodeJpg(orientedImage));
  }

  //TODO Face Registration Dialogue
  TextEditingController textEditingController = TextEditingController();
  showFaceRegistrationDialogue(Uint8List cropedFace, Recognition recognition){
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Face Registration", textAlign: TextAlign.center), alignment: Alignment.center,
        content: SizedBox(
          height: 340,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20,),
              Image.memory(
                cropedFace,
                width: 200,
                height: 200,
              ),
              SizedBox(
                width: 200,
                child: TextField(
                    controller: textEditingController,
                    decoration: const InputDecoration( fillColor: Colors.white, filled: true,hintText: "Enter Name")
                ),
              ),
              const SizedBox(height: 10,),
              ElevatedButton(
                  onPressed: () {
                    recognizer.registerFaceInDB(textEditingController.text, recognition.embeddings);
                    textEditingController.text = "";
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Face Registered"),
                    ));
                  },style: ElevatedButton.styleFrom(backgroundColor: Colors.blue,minimumSize: const Size(200,40)),
                  child: const Text("Register", style: TextStyle(color: Colors.white),))
            ],
          ),
        ),contentPadding: EdgeInsets.zero,
      ),
    );
  }

  var image;
  drawRectangleAroundFaces() async {

    // print("${image.width}   ${image.height}");
    setState(() {
      image;
      faces;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    // double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 30),
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
          image != null
              ?
              Container(
                margin: const EdgeInsets.only(top: 0, left: 30, right: 30, bottom: 0),
                  child: FittedBox(
                    child: SizedBox(
                      width: image.width.toDouble(),
                      height: image.width.toDouble(),
                      child: CustomPaint(
                        painter:
                            FacePainter(facesList: faces, imageFile: image),
                      ),
                    ),
                  ),
                )
              : Container(
                  margin: const EdgeInsets.only(top: 100),
                  width: screenWidth - 100,
                  height: screenWidth - 100,
                  child: const Icon(
                    Icons.image_rounded,
                    color: Colors.black87,
                    size: 300,
                  ),
                ),
          Container(
            margin: const EdgeInsets.only(bottom: 50, top:150),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Card(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(200),
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      _imgFromGallery();
                    },
                    child: SizedBox(
                      width: screenWidth / 2 - 90,
                      height: screenWidth / 2 - 90,
                      child: Icon(
                        Icons.image,
                        color: Colors.blue,
                        size: screenWidth / 7,
                      ),
                    ),
                  ),
                ),
                Card(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(200),
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      _imgFromCamera();
                    },
                    child: SizedBox(
                      width: screenWidth / 2 - 90,
                      height: screenWidth / 2 - 90,
                      child: Icon(
                        Icons.camera,
                        color: Colors.blue,
                        size: screenWidth / 7,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  List<Face> facesList;
  dynamic imageFile;
  FacePainter({required this.facesList, @required this.imageFile});

  @override
  void paint(Canvas canvas, Size size) {
    if (imageFile != null) {
      canvas.drawImage(imageFile, Offset.zero, Paint());
    }

    Paint p = Paint();
    p.color = Colors.red;
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 3;

    for (Face face in facesList) {
      canvas.drawRect(face.boundingBox, p);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
