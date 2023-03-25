// ignore_for_file: camel_case_types

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:musr/pages/Admin/admin_homepage.dart';
import 'package:musr/pages/register_page.dart';
import 'package:musr/pages/student/student_home_page.dart';
import 'package:musr/pages/teacher/teach_home_page.dart';
import 'package:new_version_plus/new_version_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class spalshscreen extends StatefulWidget {
  const spalshscreen({Key? key}) : super(key: key);

  @override
  State<spalshscreen> createState() => _spalshscreenState();
}

class _spalshscreenState extends State<spalshscreen> {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _checkUpdate();
    authStatus();
  }

  final newVersionPlus = NewVersionPlus();
  Future<void> _checkUpdate() async {
    final status = await newVersionPlus.getVersionStatus();
    if (status!.canUpdate) {
      newVersionPlus.showUpdateDialog(
          context: context, versionStatus: status, allowDismissal: false);
    }
  }

  void authStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userID = prefs.getString('userID');

    Future.delayed(const Duration(milliseconds: 600), () {
      if (userID != null) {
        Future<String> userRole = checkUser(userID);
        userRole.then((value) async {
          if (value == "Student") {
            fetchStudentData(userID);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => StudentHomePage()),
            );
          } else if (value == "Teacher") {
            fetchTeacherData(userID);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => TeacherHomePage()),
            );
          } else if (value == "Admin") {
            fetchTeacherData(userID);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => admin_homepage()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Registration()),
            );
          }
        });
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Registration()),
        );
      }
    });
  }

  Future<String> checkUser(String userID) async {
    String user_role = "";
    await _firebaseFirestore
        .collection('user')
        .doc(userID)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.get('access') == false)
        return "Access Denied";
      else {
        if (documentSnapshot.exists) {
          user_role = documentSnapshot.get('role');
        } else {
          print("User Doesn't Exist");
        }
      }
    });
    return user_role;
  }

  void fetchStudentData(String userID) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await _firebaseFirestore
        .collection('user')
        .doc(userID)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        prefs.setString('name', documentSnapshot.get('name'));
        prefs.setString('email', documentSnapshot.get('email'));
        prefs.setString('id', documentSnapshot.get('id'));
        prefs.setString('batch', documentSnapshot.get('batch'));
      } else {
        print("User Doesn't Exist");
      }
    });
  }

  void fetchTeacherData(String userID) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await _firebaseFirestore
        .collection('user')
        .doc(userID)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        prefs.setString('name', documentSnapshot.get('name'));
        prefs.setString('email', documentSnapshot.get('email'));
      } else {
        print("User Doesn't Exist");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        primary: false,
        backgroundColor: Colors.white,
        body: Center(
          child: Image.asset('assets/logo.png'),
        ));
  }
}
