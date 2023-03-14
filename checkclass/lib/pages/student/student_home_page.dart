import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import "package:cloud_firestore/cloud_firestore.dart";
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:miniproject/pages/register_page.dart';
import 'package:miniproject/pages/teacher/teach_tab1_page.dart';
import 'package:miniproject/pages/teacher/teach_tab2_page.dart';

import 'package:miniproject/services/authentication.dart';

import 'package:qrscan/qrscan.dart' as scanner;
import 'package:shared_preferences/shared_preferences.dart';

class StudentHomePage extends StatefulWidget {
  StudentHomePage({Key key, this.auth, this.userId, this.logoutCallback})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback logoutCallback;
  final String userId;

  @override
  State<StatefulWidget> createState() => new _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  //final FirebaseDatabase _database = FirebaseDatabase.instance;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String barcode = "";
  String status = "";
  String id = "";
  String name = "";
  //final _textEditingController = TextEditingController();

  //bool _isEmailVerified = false;

  final Firestore _firestore = Firestore.instance;
  @override
  void initState() {
    super.initState();
    getCachedData();
    //_checkEmailVerification();
  }

  getCachedData() {
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        id = prefs.getString('id');
        name = prefs.getString('name');
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
    return new WillPopScope(
        onWillPop: () async => false,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: DefaultTabController(
            length: 2,
            child: new Scaffold(
              appBar: new AppBar(
                title: new Text('Student Portal'),
                backgroundColor: Colors.pink,
                actions: [
                  IconButton(
                    icon: Icon(Icons.logout),
                    onPressed: signOut,
                  ),
                ],
                bottom: TabBar(
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
            color: Colors.pink.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: Offset(0, 3), // changes position of shadow
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
            "#ff6666", "Cancel", false, ScanMode.QR)
        .listen((barcode) async {
      print(barcode);

      await qrCodeDecoder(barcode, id);
    });
  }

  Widget ScannerButton() {
    return IconButton(
        // splashColor: Colors.red,
        iconSize: 100,
        onPressed: () async {
          FlutterBarcodeScanner.getBarcodeStreamReceiver(
                  "#ff6666", "Cancel", false, ScanMode.QR)
              .listen((barcode) async {
            print(barcode);
            try {
              await qrCodeDecoder(barcode, id);
            } catch (e) {
              print(e);
              if (e.toString() == "Exception: Batch Mismatch") {
                print("object");
                showDialog(
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
              }
            }
          });
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
                    color: Colors.pink.withOpacity(0.2),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Icon(Icons.qr_code_scanner_rounded),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
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
    if (id_batch == batch)
      validateQRcode(code, courseID, batch, date, studentID);
    else {
      throw Exception("Batch Mismatch");
    }
  }

  validateQRcode(String code, String courseID, String batch, String date,
      String studentID) async {
    final DocumentReference docRef = _firestore
        .collection('QRcode')
        .document(courseID)
        .collection(courseID)
        .document(code);
    try {
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        // If the document doesn't exist, create a new one
        print("QR EXPIRED");
      } else {
        if (await checkattendancemarked(courseID, batch, date, studentID)) {
          await addcurrentattendance(courseID, batch, date, studentID);
          await docRef.delete().then((value) => print("QR DELETED"));
          markAttendance(courseID, batch, date, studentID);
        } else
          throw Exception("Attendance Already Marked");
      }
    } catch (e) {
      print("Error on validateQRcode()");
      print(e);
    }
  }

  checkattendancemarked(
      String courseID, String batch, String date, String studentID) async {
    final DocumentReference docRef = _firestore
        .collection('course')
        .document(courseID)
        .collection(batch)
        .document('classtaken');
    try {
      final docSnapshot = await docRef.get();
      Map<String, dynamic> data = docSnapshot.data;
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
        .document(courseID)
        .collection(batch)
        .document('classtaken');

    final newData = {
      'currentAttendance': {studentID: name}
    };

    print(newData);
    docRef
        .setData(newData, merge: true)
        .then((value) => print(
            'currentAttendence field added successfully without deleting other fields'))
        .catchError(
            (error) => print('Failed to add currentAttendence field: $error'));
  }

  markAttendance(
      String courseID, String batch, String date, String studentID) async {
    final CollectionReference _collectionRef = _firestore.collection('course');
    final DocumentReference docRef =
        _collectionRef.document(courseID).collection(batch).document(studentID);

    try {
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        // If the document doesn't exist, create a new one
        await docRef.setData({
          'date': [date]
        }).then((value) => print("New document added successfully"));
      } else {
        // If the document exists, update it
        await docRef.updateData({
          'date': FieldValue.arrayUnion([date])
        }).then((value) =>
            print("Attendance Marked for $studentID in $courseID for $date"));
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> updateDatabase() async {
    final firestoreInstance = Firestore.instance;
    var docs = Firestore.instance.document('Users/$this.userId');
    var qrDetails = barcode.split('/');
    var classname = qrDetails[0];
    var dates = qrDetails[1].split('.');
    var day = dates[0];
    var date = dates[1] + '.' + dates[2];
    var check = qrDetails[2];
    var secretCode = qrDetails[3];
    var updatedCount = 0;
    var updatedCodes = [];
    var codeExists = 0;
    var teacherCodeExists = 0;
    var exists = 0;
    //print(docs);
    var teacherUID = qrDetails[4];
    var firebaseUser = await FirebaseAuth.instance.currentUser();
    final CollectionReference monthsRef = Firestore.instance
        .collection('users')
        .document(firebaseUser.uid)
        .collection(classname);
    var monthsDocs = await Firestore.instance
        .collection("users")
        .document(firebaseUser.uid)
        .collection(classname)
        .getDocuments();

    var months = monthsDocs.documents;

    for (int i = 0; i < months.length; i++)
      if (date == months[i].documentID) {
        exists = 1;
        break;
      }

    if (exists == 0) await monthsRef.document(date).setData({});

    var data = await Firestore.instance
        .collection("users")
        .document(firebaseUser.uid)
        .collection(classname)
        .document(date)
        .get();

    print('TEACHER UID :' + teacherUID);

    var teacherData = await Firestore.instance
        .collection("users")
        .document(teacherUID)
        .collection(classname)
        .document(date)
        .get();

    try {
      for (int i = 0; i < teacherData[day]['codes'].length; i++) {
        print(teacherData[day]['codes'][i]);
        if (teacherData[day]['codes'][i] == secretCode) {
          teacherCodeExists = 1;
          break;
        }
      }
    } catch (e) {
      print('Teacher Code exists caught');
    }

    try {
      updatedCount = data[day]['count'] + 1;
    } catch (e) {
      updatedCount = 1;
    }

    try {
      for (int i = 0; i < data[day]['codes'].length; i++) {
        print(data[day]['codes'][i]);
        if (data[day]['codes'][i] == secretCode) {
          codeExists = 1;
          break;
        }
      }
    } catch (e) {
      print('Code exists caught');
    }
    print('CODE EXISTS' + codeExists.toString());
    if (int.parse(check) < updatedCount) {
      setState(() {
        this.status = 'Attendance limit exeeded';
      });
    } else if (codeExists == 1) {
      setState(() {
        this.status = 'Reuse of code detected';
      });
    } else if (teacherCodeExists == 0) {
      setState(() {
        this.status = 'Invalid Code,not in database';
      });
    } else {
      try {
        updatedCodes = data[day]['codes'] + [secretCode];
      } catch (e) {
        updatedCodes = [secretCode];
      }

      try {
        firestoreInstance
            .collection("users")
            .document(firebaseUser.uid)
            .collection(classname)
            .document(date)
            .updateData({
          "$day.check": int.parse(check),
          "$day.count": updatedCount,
          "$day.codes": updatedCodes
        }).then((_) {
          setState(() {
            this.status = 'Update Successful';
          });
        });
      } catch (e) {
        setState(() {
          this.status = this.status + 'Update Fail';
        });
        print(e.toString());
      }
    }
  }
}
