import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:musr/pages/register_page.dart';
import 'package:musr/services/authentication.dart';
import 'package:new_version_plus/new_version_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/*import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';*/

import 'teach_tab1_page.dart';
import 'teach_tab2_page.dart';

class TeacherHomePage extends StatefulWidget {
  TeacherHomePage({Key? key, this.auth, this.userId, this.logoutCallback})
      : super(key: key);

  final BaseAuth? auth;
  final VoidCallback? logoutCallback;

  final String? userId;

  @override
  State<StatefulWidget> createState() => new _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  String name = "";

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _checkUpdate();
    getCachedData();
  }

  final newVersionPlus = NewVersionPlus();
  Future<void> _checkUpdate() async {
    final status = await newVersionPlus.getVersionStatus();
    if (status!.canUpdate) {
      newVersionPlus.showUpdateDialog(
          context: context, versionStatus: status, allowDismissal: false);
    }
  }

  getCachedData() {
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        name = prefs.getString('name')!;
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
      await widget.auth!.signOut();
      widget.logoutCallback!();
    } catch (e) {
      print(e);
    }
  }

  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            bottom: const TabBar(
              indicatorColor: Colors.white54,
              tabs: [
                Tab(
                  icon: Icon(Icons.mark_chat_read_rounded),
                  text: "Take Attendance",
                ),
                Tab(icon: Icon(Icons.book), text: "View Records"),
              ],
            ),
            title: Text(
              'Teacher Portal',
              style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.deepPurple,
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: signOut,
              ),
            ],
          ),
          body: TabBarView(
            children: [
              TeacherBasicPage(),
              TeacherBasicSecPage(),
            ],
          ),
        ),
      ),
    );
  }
}
