import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import "package:cloud_firestore/cloud_firestore.dart";
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:musr/pages/register_page.dart';
import 'package:musr/pages/teacher/teach_tab2_page.dart';

import 'package:musr/services/authentication.dart';

import 'package:qrscan/qrscan.dart' as scanner;
import 'package:shared_preferences/shared_preferences.dart';

class StudentHomePage extends StatefulWidget {
  StudentHomePage({Key? key, this.auth, this.userId, this.logoutCallback})
      : super(key: key);

  final BaseAuth? auth;
  final VoidCallback? logoutCallback;
  final String? userId;

  @override
  State<StatefulWidget> createState() => new _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  //final FirebaseDatabase _database = FirebaseDatabase.instance;

  final FirebaseDatabase _firebase = FirebaseDatabase.instance;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String barcode = "";
  String status = "";
  String id = "";
  String name = "";
  //final _textEditingController = TextEditingController();

  //bool _isEmailVerified = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  @override
  void initState() {
    super.initState();
    getCachedData();
    //_checkEmailVerification();
  }

  getCachedData() {
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        id = prefs.getString('id')!;
        name = prefs.getString('name')!;
      });
    });
  }

  signOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    try {
      final FirebaseAuth _auth = FirebaseAuth.instance;
      await _auth.signOut();
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Registration()),
          (route) => false);
      // await widget.auth.signOut();
      // widget.logoutCallback();
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    // print(id);
    return WillPopScope(
        onWillPop: () async => false,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            appBarTheme: AppBarTheme(color: Colors.deepPurple),
          ),
          home: DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Student Portal'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: signOut,
                  ),
                ],
                bottom: const TabBar(
                  indicatorColor: Colors.white,
                  tabs: [
                    Tab(
                      icon: Icon(Icons.qr_code_scanner),
                      text: "Scan QR Code",
                    ),
                    Tab(icon: Icon(Icons.book), text: "View Records"),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  ScannerButton(),
                  TeacherBasicSecPage(),
                ],
              ),
              // Center(
              //   child: Column(
              //     mainAxisAlignment: MainAxisAlignment.center,
              //     children: [
              //       // ScannerButton(),
              //       detail(),
              //     ],
              //   ),
              // ),
            ),
          ),
        ));
  }

  Widget detail() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Container(
        height: 150,
        width: 125,
        child: Column(
          children: [
            // Text("Name: " + name),
            // Text("ID: " + id),
          ],
        ),
      ),
    );
  }

  scannnn() {
    FlutterBarcodeScanner.getBarcodeStreamReceiver(
            "#ff6666", "Cancel", false, ScanMode.QR)!
        .listen((barcode) async {
      print(barcode);

      await qrCodeDecoder(barcode, id);
    });
  }

  scan() async {
    String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666", "Cancel", false, ScanMode.QR);
    print(barcodeScanRes);
    try {
      await qrCodeDecoder(barcodeScanRes, id);
    } catch (e) {
      print(e);
      print("SOME ERROR OCCURED");
      // scan();
    }
  }

  Widget ScannerButton() {
    return IconButton(
        // splashColor: Colors.red,
        iconSize: 100,
        onPressed: () async {
          scan();
        },
        icon: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.2),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(10.0),
                child: Icon(Icons.qr_code_scanner_rounded),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(10.0),
              child: Text("Tap to Scan"),
            )
          ],
        ));
  }

  qrCodeDecoder(String code, String studentID) {
    String courseID = code.substring(0, 5);
    String batch = code.substring(5, 9);
    String date =
        // "22-02-2023";
        DateTime.now().day.toString() +
            '-' +
            DateTime.now().month.toString() +
            '-' +
            DateTime.now().year.toString();
    String id_batch = studentID.substring(0, 4);

    print(id_batch);
    if (id_batch == batch)
      validateQRcode(code, courseID, batch, date, studentID);
    else {
      return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Error"),
            content: Text("Batch Mismatch"),
            actions: [
              TextButton(
                child: Text("Close"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      // throw Exception("Batch Mismatch");
    }
  }

  validateQRcode(String code, String courseID, String batch, String date,
      String studentID) async {
    final DocumentReference docRef = _firestore
        .collection('QRcode')
        .doc(courseID)
        .collection(courseID)
        .doc(code);
    try {
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        // If the document doesn't exist, create a new one
        // print("QR EXPIRED");
        throw Exception("QR Expired");
      } else {
        if (await checkattendancemarked(courseID, batch, date, studentID)) {
          await addcurrentattendance(courseID, batch, date, studentID);
          await docRef.delete().then((value) => print("QR DELETED"));
          markAttendance(courseID, batch, date, studentID);
        } else {
          return showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Alert !"),
                content: Text("Attendance already marked"),
                actions: [
                  TextButton(
                    child: Text("Close"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
          // throw Exception("Attendance Already Marked");
        }
      }
    } catch (e) {
      print("Error on validateQRcode()");
      scan();
      // print(e);
    }
  }

  checkattendancemarked(
      String courseID, String batch, String date, String studentID) async {
    final DocumentReference docRef = _firestore
        .collection('course')
        .doc(courseID)
        .collection(batch)
        .doc('classtaken');
    try {
      final docSnapshot = await docRef.get();
      Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
      if (!data.containsKey('currentAttendance')) {
        return true;
      } else {
        Map<dynamic, dynamic> attendance = data['currentAttendance'];

        if (attendance.containsKey(studentID)) {
          print("Attendance Already Marked");
          return false;
        } else {
          return true;
        }
      }
    } catch (e) {
      print(e);
    }
  }

  addcurrentattendance(
      String courseID, String batch, String date, String studentID) async {
    final DocumentReference docRef = _firestore
        .collection('course')
        .doc(courseID)
        .collection(batch)
        .doc('classtaken');

    final newData = {
      'currentAttendance': {studentID: name}
    };

    print(newData);
    docRef
        .set(newData, SetOptions(merge: true))
        .then((value) => print(
            'currentAttendence field added successfully without deleting other fields'))
        .catchError(
            (error) => print('Failed to add currentAttendence field: $error'));
  }

  markAttendance(
      String courseID, String batch, String date, String studentID) async {
    final CollectionReference _collectionRef = _firestore.collection('course');
    final DocumentReference docRef =
        _collectionRef.doc(courseID).collection(batch).doc(studentID);

    try {
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        // If the document doesn't exist, create a new one
        await docRef.set({
          'date': [date]
        }).then((value) => print("New document added successfully"));
      } else {
        // If the document exists, update it
        await docRef.update({
          'date': FieldValue.arrayUnion([date])
        }).then((value) =>
            print("Attendance Marked for $studentID in $courseID for $date"));
      }
      return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Status"),
            content: Row(
              children: const [
                Text(
                  "Attendance marked",
                  softWrap: true,
                ),
                Icon(Icons.done, color: Colors.green)
              ],
            ),
            actions: [
              TextButton(
                child: Text("Close"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      print(e);
    }
  }
}
