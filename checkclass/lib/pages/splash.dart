import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:miniproject/pages/register_page.dart';
import 'package:miniproject/pages/student/student_home_page.dart';
import 'package:miniproject/pages/teacher/teach_home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class spalshscreen extends StatefulWidget {
  spalshscreen({Key key}) : super(key: key);

  @override
  State<spalshscreen> createState() => _spalshscreenState();
}

class _spalshscreenState extends State<spalshscreen> {
  @override
  void initState() {
    super.initState();
    authStatus();
  }

  void authStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userID = prefs.getString('userID');

    Future.delayed(const Duration(milliseconds: 6000), () {
      if (userID != null) {
        Future<String> userRole = checkUser(userID);
        userRole.then((value) async {
          if (value == "Student") {
            await fetchStudentData(userID);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => StudentHomePage()),
            );
          } else {
            await fetchTeacherData(userID);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => TeacherHomePage()),
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
    await Firestore.instance
        .collection('user')
        .document(userID)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        user_role = documentSnapshot.data['role'];
      } else {
        print("User Doesn't Exist");
      }
    });
    return user_role;
  }

  void fetchStudentData(String userID) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await Firestore.instance
        .collection('user')
        .document(userID)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        prefs.setString('name', documentSnapshot.data['name']);
        prefs.setString('email', documentSnapshot.data['email']);
        prefs.setString('id', documentSnapshot.data['id']);
        prefs.setString('batch', documentSnapshot.data['batch']);
      } else {
        print("User Doesn't Exist");
      }
    });
  }

  void fetchTeacherData(String userID) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await Firestore.instance
        .collection('user')
        .document(userID)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        prefs.setString('name', documentSnapshot.data['name']);
        prefs.setString('email', documentSnapshot.data['email']);
      } else {
        print("User Doesn't Exist");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      primary: false,
      appBar: AppBar(
          // systemOverlayStyle: const SystemUiOverlayStyle(
          //   statusBarIconBrightness: Brightness.dark,
          //   statusBarColor: Color.fromARGB(255, 81, 163, 251),
          // ),
          backgroundColor: Colors.pink),
      backgroundColor: Colors.pink,
      body: Center(
        child: Text("Splash Screen"),
        // child: SvgPicture.asset("assets/icon/splash.svg"),
      ),
    );
  }
}
