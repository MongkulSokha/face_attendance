import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;
import '../main.dart';
import '../ml/recognition.dart';
import '../ml/recognizer.dart';
import '../model/user.dart';
import '../view/homescreen.dart';

class LiveRecognition extends StatefulWidget {
  const LiveRecognition({Key? key}) : super(key: key);

  @override
  State<LiveRecognition> createState() => HomePageState();
}

class HomePageState extends State<LiveRecognition> {
  dynamic controller;
  bool isBusy = false;
  late Size size;
  late CameraDescription description = cameras[1];
  CameraLensDirection camDirect = CameraLensDirection.front;
  late List<Recognition> recognitions = [];
  late FaceDetector faceDetector;
  late Recognizer recognizer;

  String location = " ";

  String checkIn = "--/--";
  String checkOut = "--/--";

  Color primary = const Color(0xff1d83ec);

  late SharedPreferences sharedPreferences;

  Map<String, DateTime> lastActionTime = {};

  @override
  void initState() {
    super.initState();
    var options = FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate);
    faceDetector = FaceDetector(options: options);
    recognizer = Recognizer();
    initializeCamera();
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

//TODO code to initialize the camera feed
  initializeCamera() async {
    controller = CameraController(description, ResolutionPreset.medium,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21 // for Android
            : ImageFormatGroup.bgra8888,
        enableAudio: false); // for iOS);
    await controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      controller.startImageStream((image) => {
            if (!isBusy)
              {isBusy = true, frame = image, doFaceDetectionOnFrame()}
          });
    });
  }

//TODO close all resources
  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

//TODO face detection on a frame
  dynamic _scanResults;
  CameraImage? frame;
  doFaceDetectionOnFrame() async {
//TODO convert frame into InputImage format
//     print('dfd');
    InputImage? inputImage = getInputImage();
//TODO pass InputImage to face detection model and detect faces
    List<Face> faces = await faceDetector.processImage(inputImage!);

    // print("fl=${faces.length}");
//TODO perform face recognition on detected faces
    performFaceRecognition(faces);
// setState(() {
//   _scanResults = faces;
//   isBusy = false;
// });
  }

  img.Image? image;
  bool register = false;

  // TODO perform Face Recognition
  performFaceRecognition(List<Face> faces) async {
    recognitions.clear();

    // Convert CameraImage to Image and rotate it for portrait
    image = Platform.isIOS
        ? _convertBGRA8888ToImage(frame!) as img.Image?
        : _convertNV21(frame!);
    image = img.copyRotate(image!,
        angle: camDirect == CameraLensDirection.front ? 270 : 90);

    for (Face face in faces) {
      Rect faceRect = face.boundingBox;

      // Crop face
      img.Image croppedFace = img.copyCrop(image!,
          x: faceRect.left.toInt(),
          y: faceRect.top.toInt(),
          width: faceRect.width.toInt(),
          height: faceRect.height.toInt());

      // Pass cropped face to face recognition model
      Recognition recognition = recognizer.recognize(croppedFace, faceRect);
      if (recognition.distance > 1.0) {
        recognition.name = "Unknown";
      }
      recognitions.add(recognition);

      // Check if face is recognized and perform action
      if (recognition.name != "Unknown") {
        if(recognition.name == User.lastName) {
          // Ensure performActionOnMatch is called only once per face recognition
          DateTime now = DateTime.now();
          if (lastActionTime[recognition.name] == null ||
              now
                  .difference(lastActionTime[recognition.name]!)
                  .inSeconds >= 10) { // 10 seconds debounce time
            lastActionTime[recognition.name] = now;
            performActionOnMatch(recognition);
          }
        } else{
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Wrong Face Detected!"),
            ),
          );
        }
      }

      // Show face registration dialogue if needed
      if (register) {
        showFaceRegistrationDialogue(croppedFace, recognition);
        register = false;
      }
    }

    setState(() {
      isBusy = false;
      _scanResults = recognitions;
    });
  }

  //TODO Define the action to perform when a registered face is
  Future<void> performActionOnMatch(Recognition recognition) async {
    if (User.lat != 0) {
      // Fetch student record
      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection("Student")
          .where('id', isEqualTo: User.studentId)
          .get();

      String recordId = DateFormat('dd MMMM yy').format(DateTime.now());

      // Fetch existing check-in/check-out times
      DocumentSnapshot snap2 = await FirebaseFirestore.instance
          .collection("Student")
          .doc(snap.docs[0].id)
          .collection("Record")
          .doc(recordId)
          .get();

      try {
        // Check if check-in exists
        String currentCheckIn = snap2['checkIn'];
        if (currentCheckIn != "--/--") {
          // If check-in exists, update check-out
          setState(() {
            checkOut = DateFormat('hh:mm').format(DateTime.now());
          });
          await FirebaseFirestore.instance
              .collection("Student")
              .doc(snap.docs[0].id)
              .collection("Record")
              .doc(recordId)
              .update({
            'date': Timestamp.now(),
            'checkIn': currentCheckIn,
            'checkOut': checkOut,
            'checkOutLocation': location,
          });
        } else {
          // If check-in does not exist, set check-in
          setState(() {
            checkIn = DateFormat('hh:mm').format(DateTime.now());
          });
          await FirebaseFirestore.instance
              .collection("Student")
              .doc(snap.docs[0].id)
              .collection("Record")
              .doc(recordId)
              .set({
            'date': Timestamp.now(),
            'checkIn': checkIn,
            'checkOut': "--/--",
            'checkInLocation': location,
          });
        }
      } catch (e) {
        // If no record exists, set check-in
        setState(() {
          checkIn = DateFormat('hh:mm').format(DateTime.now());
        });
        await FirebaseFirestore.instance
            .collection("Student")
            .doc(snap.docs[0].id)
            .collection("Record")
            .doc(recordId)
            .set({
          'date': Timestamp.now(),
          'checkIn': checkIn,
          'checkOut': "--/--",
          'checkInLocation': location,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Done!"),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    } else {
      Timer(
        const Duration(seconds: 3),
            () async {
          // Fetch student record
          QuerySnapshot snap = await FirebaseFirestore.instance
              .collection("Student")
              .where('id', isEqualTo: User.studentId)
              .get();

          String recordId = DateFormat('dd MMMM yy').format(DateTime.now());

          // Fetch existing check-in/check-out times
          DocumentSnapshot snap2 = await FirebaseFirestore.instance
              .collection("Student")
              .doc(snap.docs[0].id)
              .collection("Record")
              .doc(recordId)
              .get();

          try {
            // Check if check-in exists
            String currentCheckIn = snap2['checkIn'];
            if (currentCheckIn != "--/--") {
              // If check-in exists, update check-out
              setState(() {
                checkOut = DateFormat('hh:mm').format(DateTime.now());
              });
              await FirebaseFirestore.instance
                  .collection("Student")
                  .doc(snap.docs[0].id)
                  .collection("Record")
                  .doc(recordId)
                  .update({
                'date': Timestamp.now(),
                'checkIn': currentCheckIn,
                'checkOut': checkOut,
                'checkOutLocation': location,
              });
            } else {
              // If check-in does not exist, set check-in
              setState(() {
                checkIn = DateFormat('hh:mm').format(DateTime.now());
              });
              await FirebaseFirestore.instance
                  .collection("Student")
                  .doc(snap.docs[0].id)
                  .collection("Record")
                  .doc(recordId)
                  .set({
                'date': Timestamp.now(),
                'checkIn': checkIn,
                'checkOut': "--/--",
                'checkInLocation': location,
              });
            }
          } catch (e) {
            // If no record exists, set check-in
            setState(() {
              checkIn = DateFormat('hh:mm').format(DateTime.now());
            });
            await FirebaseFirestore.instance
                .collection("Student")
                .doc(snap.docs[0].id)
                .collection("Record")
                .doc(recordId)
                .set({
              'date': Timestamp.now(),
              'checkIn': checkIn,
              'checkOut': "--/--",
              'checkInLocation': location,
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Done!"),
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
        },
      );
    }
  }

//TODO Face Registration Dialogue
  TextEditingController textEditingController = TextEditingController();
  showFaceRegistrationDialogue(img.Image croppedFace, Recognition recognition) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Face Registration", textAlign: TextAlign.center),
        alignment: Alignment.center,
        content: SizedBox(
          height: 340,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 20,
              ),
              Image.memory(
                Uint8List.fromList(img.encodeBmp(croppedFace)),
                width: 200,
                height: 200,
              ),
              SizedBox(
                width: 200,
                child: TextField(
                    controller: textEditingController,
                    decoration: const InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        hintText: "Enter Name")),
              ),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                  onPressed: () {
                    recognizer.registerFaceInDB(
                        textEditingController.text, recognition.embeddings);
                    textEditingController.text = "";
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Face Registered"),
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(200, 40)),
                  child: const Text("Register"))
            ],
          ),
        ),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  static var IOS_BYTES_OFFSET = 28;

  static img.Image _convertBGRA8888ToImage(CameraImage cameraImage) {
    final plane = cameraImage.planes[0];

    return img.Image.fromBytes(
      width: cameraImage.width,
      height: cameraImage.height,
      bytes: plane.bytes.buffer,
      rowStride: plane.bytesPerRow,
      bytesOffset: IOS_BYTES_OFFSET,
      order: img.ChannelOrder.bgra,
    );
  }

  static img.Image _convertNV21(CameraImage image) {
    final width = image.width.toInt();
    final height = image.height.toInt();

    Uint8List yuv420sp = image.planes[0].bytes;

    final outImg = img.Image(height: height, width: width);
    final int frameSize = width * height;

    for (int j = 0, yp = 0; j < height; j++) {
      int uvp = frameSize + (j >> 1) * width, u = 0, v = 0;
      for (int i = 0; i < width; i++, yp++) {
        int y = (0xff & yuv420sp[yp]) - 16;
        if (y < 0) y = 0;
        if ((i & 1) == 0) {
          v = (0xff & yuv420sp[uvp++]) - 128;
          u = (0xff & yuv420sp[uvp++]) - 128;
        }
        int y1192 = 1192 * y;
        int r = (y1192 + 1634 * v);
        int g = (y1192 - 833 * v - 400 * u);
        int b = (y1192 + 2066 * u);

        if (r < 0) {
          r = 0;
        } else if (r > 262143) r = 262143;
        if (g < 0) {
          g = 0;
        } else if (g > 262143) g = 262143;
        if (b < 0) {
          b = 0;
        } else if (b > 262143) b = 262143;

        outImg.setPixelRgb(i, j, ((r << 6) & 0xff0000) >> 16,
            ((g >> 2) & 0xff00) >> 8, (b >> 10) & 0xff);
      }
    }
    return outImg;
  }

// TODO convert CameraImage to Image
  img.Image convertYUV420ToImage(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;

    final yRowStride = cameraImage.planes[0].bytesPerRow;
    final uvRowStride = cameraImage.planes[1].bytesPerRow;
    final uvPixelStride = cameraImage.planes[1].bytesPerPixel!;

    final image = img.Image(width: width, height: height);

    for (var w = 0; w < width; w++) {
      for (var h = 0; h < height; h++) {
        final uvIndex =
            uvPixelStride * (w / 2).floor() + uvRowStride * (h / 2).floor();
        final index = h * width + w;
        final yIndex = h * yRowStride + w;

        final y = cameraImage.planes[0].bytes[yIndex];
        final u = cameraImage.planes[1].bytes[uvIndex];
        final v = cameraImage.planes[2].bytes[uvIndex];

        image.data!.setPixelR(w, h, yuv2rgb(y, u, v)); //= yuv2rgb(y, u, v);
      }
    }
    return image;
  }

  int yuv2rgb(int y, int u, int v) {
// Convert yuv pixel to rgb
    var r = (y + v * 1436 / 1024 - 179).round();
    var g = (y - u * 46549 / 131072 + 44 - v * 93604 / 131072 + 91).round();
    var b = (y + u * 1814 / 1024 - 227).round();

// Clipping RGB values to be inside boundaries [ 0 , 255 ]
    r = r.clamp(0, 255);
    g = g.clamp(0, 255);
    b = b.clamp(0, 255);

    return 0xff000000 |
        ((b << 16) & 0xff0000) |
        ((g << 8) & 0xff00) |
        (r & 0xff);
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

//TODO convert CameraImage to InputImage
  InputImage? getInputImage() {
    final camera =
        camDirect == CameraLensDirection.front ? cameras[1] : cameras[0];
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[controller!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
// front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
// back-facing
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(frame!.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;

    if (frame!.planes.length != 1) return null;
    final plane = frame!.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(frame!.width.toDouble(), frame!.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Widget buildResult() {
    if (_scanResults == null ||
        controller == null ||
        !controller.value.isInitialized) {
      return const Center(child: Text('Camera is not initialized'));
    }
    final Size imageSize = Size(
      controller.value.previewSize!.height,
      controller.value.previewSize!.width,
    );
    CustomPainter painter =
        FaceDetectorPainter(imageSize, _scanResults, camDirect);
    return CustomPaint(
      painter: painter,
    );
  }

//TODO toggle camera direction
  void _toggleCameraDirection() async {
    if (camDirect == CameraLensDirection.back) {
      camDirect = CameraLensDirection.front;
      description = cameras[1];
    } else {
      camDirect = CameraLensDirection.back;
      description = cameras[0];
    }
    await controller.stopImageStream();
    setState(() {
      controller;
    });

    initializeCamera();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> stackChildren = [];
    size = MediaQuery.of(context).size;
    if (controller != null) {
      //TODO View for displaying the live camera footage
      stackChildren.add(
        Positioned(
          top: 0.0,
          left: 0.0,
          width: size.width,
          height: size.height,
          child: Container(
            child: (controller.value.isInitialized)
                ? AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: CameraPreview(controller),
                  )
                : Container(),
          ),
        ),
      );

      //TODO View for displaying rectangles around detected aces
      stackChildren.add(
        Positioned(
            top: 0.0,
            left: 0.0,
            width: size.width,
            height: size.height,
            child: buildResult()),
      );
    }

    //TODO View for displaying the bar to switch camera direction or for registering faces
//     stackChildren.add(Positioned(
//       top: size.height - 220,
//       left: 0,
//       width: size.width,
//       height: 80,
//       child: Card(
//         margin: const EdgeInsets.only(left: 20, right: 20),
//         color: Colors.blue,
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   IconButton(
//                     icon: const Icon(
//                       Icons.cached,
//                       color: Colors.white,
//                     ),
//                     iconSize: 40,
//                     color: Colors.black,
//                     onPressed: () {
//                       _toggleCameraDirection();
//                     },
//                   ),
//                   Container(
//                     width: 30,
//                   ),
//                   IconButton(
//                     icon: const Icon(
//                       Icons.face_retouching_natural,
//                       color: Colors.white,
//                     ),
//                     iconSize: 40,
//                     color: Colors.black,
//                     onPressed: () {
//                       setState(() {
//                         register = true;
//                       });
//                     },
//                   )
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     ));

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Live Recognition'),
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
        body: Container(
            margin: const EdgeInsets.only(top: 0),
            color: Colors.black,
            child: Stack(
              children: stackChildren,
            )),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('IOS_BYTES_OFFSET', IOS_BYTES_OFFSET));
    properties.add(IntProperty('IOS_BYTES_OFFSET', IOS_BYTES_OFFSET));
  }
}

class FaceDetectorPainter extends CustomPainter {
  FaceDetectorPainter(this.absoluteImageSize, this.faces, this.camDire2);

  final Size absoluteImageSize;
  final List<Recognition> faces;
  CameraLensDirection camDire2;

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / absoluteImageSize.width;
    final double scaleY = size.height / absoluteImageSize.height;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.indigoAccent;

    for (Recognition face in faces) {
      canvas.drawRect(
        Rect.fromLTRB(
          camDire2 == CameraLensDirection.front
              ? (absoluteImageSize.width - face.location.right) * scaleX
              : face.location.left * scaleX,
          face.location.top * scaleY,
          camDire2 == CameraLensDirection.front
              ? (absoluteImageSize.width - face.location.left) * scaleX
              : face.location.right * scaleX,
          face.location.bottom * scaleY,
        ),
        paint,
      );

      TextSpan span = TextSpan(
          style: const TextStyle(color: Colors.white, fontSize: 20),
          text: "${face.name}  ${face.distance.toStringAsFixed(2)}");
      TextPainter tp = TextPainter(
          text: span,
          textAlign: TextAlign.left,
          textDirection: ui.TextDirection.ltr);
      tp.layout();
      tp.paint(canvas,
          Offset(face.location.left * scaleX, face.location.top * scaleY));
    }
  }

  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    return true;
  }
}
