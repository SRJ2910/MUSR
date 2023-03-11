import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import "package:cloud_firestore/cloud_firestore.dart";
import 'package:encrypt/encrypt.dart' as ency;
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:miniproject/pages/register_page.dart';

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
    prefs.clear();
    try {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Registration()),
          (route) => false);
      await widget.auth.signOut();
      widget.logoutCallback();
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
      onWillPop: () async => false,
      child: new Scaffold(
        appBar: new AppBar(
          title: new Text('Smart Attendance'),
          backgroundColor: Colors.deepOrange,
          actions: <Widget>[
            new FlatButton(
                child: new Text('Logout',
                    style: new TextStyle(fontSize: 20.0, color: Colors.white)),
                onPressed: signOut)
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(id),
              Text(name),
              // new IconButton(
              //     onPressed: (() =>
              //         qrCodeDecoder("CS2012020580428Cry86123", "202011069")),
              //     icon: Icon(Icons.abc)),
              TextButton(
                  onPressed: () async {
                    FlutterBarcodeScanner.getBarcodeStreamReceiver(
                            "#ff6666", "Cancel", false, ScanMode.QR)
                        .listen((barcode) async {
                      print(barcode);

                      await qrCodeDecoder(barcode, id);
                    }, onDone: () {
                      print("Done");
                    }, onError: (error) {
                      print("Error");
                    });
                  },
                  child: Text("Scanner"))
            ],
          ),
        ),
      ),
    );
  }

  Future qrCodeScan() async {
    String barcode = await scanner.scan();
    final key = ency.Key.fromUtf8('JingalalahuhuJingalalahuhuJingal');
    final iv = ency.IV.fromLength(16);
    final encrypter = ency.Encrypter(ency.AES(key));
    final decryptedQR =
        encrypter.decrypt(ency.Encrypted.from64(barcode), iv: iv);
    print('BARCODE' + decryptedQR);
    setState(() => this.barcode = decryptedQR);
    var a = updateDatabase();
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
    validateQRcode(code, courseID, batch, date, studentID);
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
        await docRef.delete().then((value) => print("QR DELETED"));
        markAttendance(courseID, batch, date, studentID);
      }
    } catch (e) {
      print("Error on validateQRcode()");
      print(e);
    }
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
// Future<bool> checkIfDocumentExists(String collectionName, String docId) async {
//   DocumentSnapshot documentSnapshot = await _firestore
//       .collection(collectionName)
//       .document(docId).collection(collectionPath)
//       .get();

//   return documentSnapshot.exists;
// }
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
