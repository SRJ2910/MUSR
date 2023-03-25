import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:musr/pages/register_page.dart';
import 'package:new_version_plus/new_version_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class admin_homepage extends StatefulWidget {
  admin_homepage({Key? key}) : super(key: key);

  @override
  State<admin_homepage> createState() => _admin_homepageState();
}

class _admin_homepageState extends State<admin_homepage> {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();

    if (!kIsWeb) _checkUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Portal'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: signOut,
            ),
          ],
        ),
        body: _useraccessbox());
  }

  final newVersionPlus = NewVersionPlus();
  Future<void> _checkUpdate() async {
    final status = await newVersionPlus.getVersionStatus();
    if (status!.canUpdate) {
      newVersionPlus.showUpdateDialog(
          context: context, versionStatus: status, allowDismissal: false);
    }
  }

  Widget _useraccessbox() {
    return StreamBuilder(
      stream: _firebaseFirestore.collection('user').snapshots(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasError) {
          return const Text('Something went wrong');
        } else if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator());
        else {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: ListView.builder(
              itemCount: snapshot.data.docs.length,
              itemBuilder: (context, index) {
                if (snapshot.data.docs[index].data()['access'] == false) {
                  return Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(snapshot.data.docs[index].data()['name'],
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text(snapshot.data.docs[index]
                                      .data()['email']),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Text(snapshot.data.docs[index].data()['role']),
                                Container(
                                  width: 100,
                                  child: IconButton(
                                    color: Colors.green,
                                    splashRadius: 20,
                                    onPressed: () {
                                      _firebaseFirestore
                                          .collection('user')
                                          .doc(snapshot.data.docs[index].id)
                                          .update({'access': true}).then(
                                              (value) => print("User Updated"));
                                    },
                                    icon: Icon(Icons.check_box_outlined),
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                        const Divider(
                          height: 5,
                          thickness: 1,
                        ),
                      ],
                    ),
                  );
                } else {
                  return Container(
                      // color: Colors.amber,
                      // height: 10,
                      );
                }
              },
            ),
          );
        }
      },
    );
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
}
