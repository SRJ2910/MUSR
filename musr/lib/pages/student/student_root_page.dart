import 'package:flutter/material.dart';
import 'package:musr/pages/student/student_login.dart';
import 'package:musr/services/authentication.dart';
import 'package:musr/pages/student/student_home_page.dart';

enum AuthStatus {
  NOT_DETERMINED,
  NOT_LOGGED_IN,
  LOGGED_IN,
}

class StudentRootPage extends StatefulWidget {
  StudentRootPage({this.auth});

  final BaseAuth? auth;

  @override
  State<StatefulWidget> createState() => new _StudentRootPageState();
}

class _StudentRootPageState extends State<StudentRootPage> {
  AuthStatus authStatus = AuthStatus.NOT_DETERMINED;
  String _userId = "";

  @override
  void initState() {
    super.initState();
    widget.auth!.getCurrentUser().then((user) {
      setState(() {
        _userId = user.uid;
        authStatus =
            user.uid == null ? AuthStatus.NOT_LOGGED_IN : AuthStatus.LOGGED_IN;
      });
    });
  }

  void loginCallback() {
    widget.auth!.getCurrentUser().then((user) {
      setState(() {
        _userId = user.uid.toString();
      });
    });
    setState(() {
      authStatus = AuthStatus.LOGGED_IN;
    });
  }

  void logoutCallback() {
    setState(() {
      authStatus = AuthStatus.NOT_LOGGED_IN;
      _userId = "";
    });
  }

  Widget buildWaitingScreen() {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child: CircularProgressIndicator(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (authStatus) {
      case AuthStatus.NOT_DETERMINED:
        return buildWaitingScreen();
        break;
      case AuthStatus.NOT_LOGGED_IN:
        return StudentLogin(
          auth: widget.auth,
          loginCallback: loginCallback,
        );
      case AuthStatus.LOGGED_IN:
        if (_userId.isNotEmpty) {
          return StudentHomePage(
            userId: _userId,
            auth: widget.auth,
            logoutCallback: logoutCallback,
          );
        } else {
          return buildWaitingScreen();
        }
      default:
        return buildWaitingScreen();
    }
  }
}
