import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:miniproject/pages/QR/qr_generator.dart';
import 'package:miniproject/services/authentication.dart';
import 'package:encrypt/encrypt.dart' as ency;

import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherBasicPage extends StatefulWidget {
  TeacherBasicPage({Key key, this.auth, this.userId, this.logoutCallback})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback logoutCallback;

  final String userId;

  @override
  State<StatefulWidget> createState() => new _TeacherBasicPageState();
}

class _TeacherBasicPageState extends State<TeacherBasicPage> {
  //final FirebaseDatabase _database = FirebaseDatabase.instance;
  final GlobalKey<FormState> _formKey1 = GlobalKey<FormState>();

  //bool _isEmailVerified = false;
  String classname;
  String date;
  String secretcode;
  String check;
  String str;
  String userId = '';
  String saveMessage = 'Click save to update or cancel to reject';

  String _courseId;
  String _courseName;
  String _batch;
  String _errorMessage;
  bool _isLoading;
  bool _fetchingdata;

  List<String> _coursenameList = [];
  List<String> _courseIdList = [];

  bool validateAndSave() {
    print(3);
    final form = _formKey1.currentState;
    print(form.toString());
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  void validateAndSubmit() async {
    print(1);
    setState(() {
      _errorMessage = "";
      _isLoading = true;
    });
    print(2);
    if (validateAndSave()) {
      try {
//add all user to database
        await Firestore.instance
            .collection('course')
            .document(_courseId)
            .setData({'id': _courseId, 'name': _courseName, 'batch': _batch});

//add student to database

        print("course Added Successfully");
        setState(() {
          _isLoading = false;
        });
        // print(result['role']);
        // if (result['role'] == "student")
        //   throw Exception("Only Teachers can login");
        // print('Signed in: $userId');
        // setState(() {
        //   _isLoading = false;
        // });

      } catch (e) {
        print('Error: $e');
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
          _formKey1.currentState.reset();
        });
      }
    }
  }

  @override
  void initState() {
    userId = widget.userId;
    _isLoading = false;
    _fetchingdata = false;
    fetchdata();
    super.initState();
    //_checkEmailVerification();
  }

  signOut() async {
    try {
      await widget.auth.signOut();
      widget.logoutCallback();
    } catch (e) {
      print(e);
    }
  }

  fetchdata() async {
    try {
      await Firestore.instance
          .collection('course')
          .getDocuments()
          .then((snapshot) {
        snapshot.documents.forEach((f) {
          _coursenameList.add(f.data['name']);
          _courseIdList.add(f.data['id']);
        });
      });
      setState(() {
        _fetchingdata = true;
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _fetchingdata
            ? StreamBuilder(
                stream: Firestore.instance.collection('course').snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  return ListView(
                    children: snapshot.data.documents.map((document) {
                      return ListTile(
                        leading: Icon(
                          Icons.book,
                          color: Colors.black,
                        ),
                        title: Text(document['name']),
                        subtitle: Text(document['id']),
                        trailing: Text(document['batch']),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => QrGenerator(
                                        courseId: document['id'],
                                        courseName: document['name'],
                                        batch: document['batch'],
                                      )));
                        },
                      );
                    }).toList(),
                  );
                })
            : Center(
                child: CircularProgressIndicator(),
              ),
        Align(
            alignment: Alignment.bottomRight,
            child: Container(
              margin: EdgeInsets.only(bottom: 20, right: 20),
              child: addCourse(),
            ))
      ],
    );
    // body: SingleChildScrollView(
    //   /*ConstrainedBox(
    //   constraints: new BoxConstraints(
    //     minHeight: 500,
    //     minWidth: 300,
    //     maxHeight: 700,
    //     maxWidth: 500,
    //   ),*/
    //   child: Center(
    //     child: Column(
    //       crossAxisAlignment: CrossAxisAlignment.center,
    //       children: <Widget>[
    //         SingleChildScrollView(
    //           child: Column(
    //             children: <Widget>[
    //               enterDetails(),
    //               formInput(),
    //               GestureDetector(
    //                 onTap: () {
    //                   showCustomDialogWithImage(context);
    //                 },
    //                 child: Container(
    //                   margin: EdgeInsets.all(70),
    //                   width: 300,
    //                   height: 40,
    //                   //color:Colors.pink,
    //                   decoration: BoxDecoration(
    //                       color: Colors.pink,
    //                       shape: BoxShape.rectangle,
    //                       //borderRadius: BorderRadius.circular(10),
    //                       borderRadius:
    //                           BorderRadius.all(Radius.circular(25))),

    //                   child: const Center(
    //                     child: Text(
    //                       'Generate QR Code',
    //                       style: TextStyle(
    //                           color: Colors.white,
    //                           fontWeight: FontWeight.bold,
    //                           fontSize: 16),
    //                     ),
    //                   ),
    //                 ),
    //               ),
    //             ],
    //           ),
    //         ),
    //       ],
    //     ),
    //   ),
    // )
  }

  Widget formInput() {
    return new Form(
      key: _formKey1,
      child: new ListView(
        shrinkWrap: true,
        children: <Widget>[
          subjCodeInput(),
          dateInput(),
          checkInput(),
          codeInput(),
        ],
      ),
    );
  }

  Widget addCourse() {
    return FloatingActionButton(
      onPressed: () {
        return showModalBottomSheet(
          isScrollControlled: true,
          context: context,
          builder: (context) {
            return Form(
              key: _formKey1,
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Container(
                    height: 250.0,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 0.0),
                      child: Column(
                        children: [
                          TextFormField(
                            maxLines: 1,
                            keyboardType: TextInputType.emailAddress,
                            autofocus: true,
                            decoration: new InputDecoration(
                                hintText: 'Course ID',
                                icon: new Icon(
                                  Icons.indeterminate_check_box_outlined,
                                  color: Colors.grey,
                                )),
                            validator: (value) => value.isEmpty
                                ? 'Course ID can\'t be empty'
                                : null,
                            onSaved: (value) => _courseId = value.trim(),
                          ),
                          TextFormField(
                            maxLines: 1,
                            keyboardType: TextInputType.text,
                            autofocus: false,
                            decoration: new InputDecoration(
                                hintText: 'Course Name',
                                icon: new Icon(
                                  Icons.book,
                                  color: Colors.grey,
                                )),
                            validator: (value) => value.isEmpty
                                ? 'Course name can\'t be empty'
                                : null,
                            onSaved: (value) => _courseName = value.trim(),
                          ),
                          TextFormField(
                            maxLines: 1,
                            keyboardType: TextInputType.text,
                            autofocus: true,
                            decoration: new InputDecoration(
                                hintText: 'Batch Year',
                                icon: new Icon(
                                  Icons.numbers,
                                  color: Colors.grey,
                                )),
                            validator: (value) => value.isEmpty
                                ? 'Batch number can\'t be empty'
                                : null,
                            onSaved: (value) => _batch = value.trim(),
                          ),
                          SizedBox(height: 20),
                          RaisedButton(
                            elevation: 5.0,
                            shape: new RoundedRectangleBorder(
                                borderRadius: new BorderRadius.circular(30.0)),
                            color: Colors.pink,
                            onPressed: validateAndSubmit,
                            child: new Text('Create Course',
                                style: new TextStyle(
                                    fontSize: 20.0, color: Colors.white)),
                          ),
                        ],
                      ),
                    )),
              ),
            );
          },
        );
      },
      child: Icon(Icons.add),
      backgroundColor: Colors.pink,
    );
  }

  Widget enterDetails() {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Container(
        padding: EdgeInsets.fromLTRB(2, 2, 2, 2),
        width: 280,
        height: 50,
        alignment: Alignment(80, 30),
        decoration: BoxDecoration(
          color: Colors.pink,
          shape: BoxShape.rectangle,
          //borderRadius: BorderRadius.circular(12),
          borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(20), topLeft: Radius.circular(20)),
        ),
        child: const Center(
          child: Text(
            'Enter Details',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
          ),
        ),
      ),
    );
  }

  Widget checkInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 5.0),
      child: new TextFormField(
        maxLines: 1,
        textAlign: TextAlign.center,
        decoration: new InputDecoration(
          hintText: 'Enter no of classes for the day',
        ),
        keyboardType: TextInputType.number,
        autofocus: false,
        validator: (value) => value.isEmpty ? 'Enter classes first' : null,
        onSaved: (value) => check = value.trim(),
      ),
    );
  }

  Widget subjCodeInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 5.0),
      child: new TextFormField(
        maxLines: 1,
        textAlign: TextAlign.center,
        decoration: new InputDecoration(
          hintText: 'Enter subject code',
        ),
        keyboardType: TextInputType.text,
        autofocus: false,
        validator: (value) => value.isEmpty ? 'Enter subject code first' : null,
        onSaved: (value) => classname = value.trim(),
      ),
    );
  }

  Widget dateInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 0.0),
      child: new TextFormField(
        maxLines: 1,
        decoration: new InputDecoration(
          hintText: 'Enter date in dd.mm.yy format',
        ),
        textAlign: TextAlign.center,
        keyboardType: TextInputType.datetime,
        autofocus: false,
        validator: (value) =>
            value.isEmpty ? 'Enter date in dd.mm.yy format' : null,
        onSaved: (value) => date = value.trim(),
      ),
    );
  }

  Widget codeInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new TextFormField(
        maxLines: 1,
        decoration: new InputDecoration(
          hintText: 'Enter your code',
        ),
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        autofocus: false,
        validator: (value) =>
            value.isEmpty || value.contains('.') || value.contains(' ')
                ? 'Code cant be empty or have spaces and dots'
                : null,
        onSaved: (value) => secretcode = value.trim(),
      ),
    );
  }

  Future<void> showCustomDialogWithImage(BuildContext context) async {
    if (validateAndSave()) {
      //print(userId);
      var firebaseUser = await FirebaseAuth.instance.currentUser();
      String qrData = classname +
          '/' +
          date +
          '/' +
          check +
          '/' +
          secretcode +
          '/' +
          firebaseUser.uid;

      final key = ency.Key.fromUtf8('JingalalahuhuJingalalahuhuJingal');
      final iv = ency.IV.fromLength(16);
      final encrypter = ency.Encrypter(ency.AES(key));
      final encryptedQR = encrypter.encrypt(qrData, iv: iv);
      final decryptedQR =
          encrypter.decrypt(encryptedQR, iv: iv); //used in student's home page

      print(qrData);
      print(encryptedQR.base64);
      print(decryptedQR);
      print(encryptedQR.base64);

      Dialog dialogWithImage = Dialog(
        child: Container(
          height: 330.0,
          width: 300.0,
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 20.0, bottom: 10.0),
                child: Container(
                  height: 200,
                  width: 300,
                  child: Center(
                    child: QrImage(
                      data: encryptedQR.base64,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  RaisedButton(
                    color: Colors.blue,
                    onPressed: () {
                      saveTheForm(qrData);
                    },
                    child: Text(
                      'Save',
                      style: TextStyle(fontSize: 18.0, color: Colors.white),
                    ),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  RaisedButton(
                    color: Colors.blue,
                    onPressed: () {
                      setState(() {
                        saveMessage =
                            'Click save to update or cancel to reject';
                      });
                      Navigator.of(context, rootNavigator: true).pop();
                    },
                    child: Text(
                      'Cancel',
                      style: TextStyle(fontSize: 18.0, color: Colors.white),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Text(saveMessage)
            ],
          ),
        ),
      );
      showDialog(
          context: context,
          builder: (BuildContext context) => dialogWithImage,
          barrierDismissible: false);
    }
  }

  void showCustomDialog(BuildContext context, String msg, String msg1) {
    AlertDialog dialogWithImage = AlertDialog(
      title: Text(msg1),
      content: Text(msg),
      actions: <Widget>[
        FlatButton(
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
          },
          child:
              Text('OK', style: TextStyle(fontSize: 18.0, color: Colors.blue)),
        ),
      ],
      elevation: 24.0,
    );
    showDialog(
        context: context,
        builder: (BuildContext context) => dialogWithImage,
        barrierDismissible: false);
  }

  Future<void> saveTheForm(String qrData) async {
    final firestoreInstance = Firestore.instance;
    var qrDetails = qrData.split('/');
    var classname = qrDetails[0];
    var dates = qrDetails[1].split('.');
    var day = dates[0];
    var date = dates[1] + '.' + dates[2];
    var secretCode = qrDetails[3];
    var exists = 0;
    var codeExists = 0;
    var updatedData = [];
    //print(docs);
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

    //print(data[day]['codes'][0]);

    try {
      for (int i = 0; i < data[day]['codes'].length; i++)
        if (data[day]['codes'][i] == secretCode) {
          codeExists = 1;
          break;
        }
    } catch (e) {
      print("Caught");
    }

    print(codeExists);
    if (codeExists == 1) {
      Navigator.of(context, rootNavigator: true).pop();
      showCustomDialog(
          context, 'Secret code already exists.Please enter a new one', 'Oops');
    } else {
      try {
        updatedData = data[day]['codes'] + [secretCode];
      } catch (e) {
        updatedData = [secretCode];
      }

      try {
        firestoreInstance
            .collection("users")
            .document(firebaseUser.uid)
            .collection(classname)
            .document(date)
            .updateData({
          "$day.codes": updatedData,
        });
        // Navigator.of(context, rootNavigator: true).pop();
        showCustomDialog(
            context, 'QR Saved and ready to be scanned', 'Success');
      } catch (e) {
        showCustomDialog(context, 'Update Failed,Please try again', 'Error');
        print(e.toString());
      }
    }
  }
}
