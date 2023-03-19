import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:musr/pages/QR/qr_generator.dart';
import 'package:musr/services/authentication.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherBasicPage extends StatefulWidget {
  TeacherBasicPage({Key? key, this.auth, this.userId, this.logoutCallback})
      : super(key: key);

  final BaseAuth? auth;
  final VoidCallback? logoutCallback;

  final String? userId;

  @override
  State<StatefulWidget> createState() => new _TeacherBasicPageState();
}

class _TeacherBasicPageState extends State<TeacherBasicPage> {
  //final FirebaseDatabase _database = FirebaseDatabase.instance;
  final GlobalKey<FormState> _formKey1 = GlobalKey<FormState>();

  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  //bool _isEmailVerified = false;
  String? classname;
  String? date;
  String? secretcode;
  String? check;
  String? str;
  String? userId = '';
  String? saveMessage = 'Click save to update or cancel to reject';

  String? _courseId;
  String? _courseName;
  String? _batch;
  String? _errorMessage;
  bool _isLoading = false;
  bool _fetchingdata = false;

  List<String?> _coursenameList = [];
  List<String?> _courseIdList = [];

  bool validateAndSave() {
    print(3);
    final form = _formKey1.currentState;
    // print(form.toString());
    if (form!.validate()) {
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
        await _firebaseFirestore
            .collection('course')
            .doc(_courseId)
            .set({'id': _courseId, 'name': _courseName, 'batch': _batch});

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
          _errorMessage = e.toString();
          _formKey1.currentState!.reset();
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
      await widget.auth!.signOut();
      widget.logoutCallback!();
    } catch (e) {
      print(e);
    }
  }

  fetchdata() async {
    try {
      await _firebaseFirestore.collection('course').get().then((snapshot) {
        for (var f in snapshot.docs) {
          _coursenameList.add(f.get('name'));
          _courseIdList.add(f.get('id'));
        }
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
                stream: _firebaseFirestore.collection('course').snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  return ListView(
                    children: snapshot.data!.docs.map((document) {
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
  }

  Widget formInput() {
    return Form(
      key: _formKey1,
      child: ListView(
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
        showModalBottomSheet(
          isScrollControlled: true,
          context: context,
          builder: (context) {
            return Form(
              key: _formKey1,
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: SizedBox(
                    height: 250.0,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 0.0),
                      child: Column(
                        children: [
                          TextFormField(
                            maxLines: 1,
                            keyboardType: TextInputType.emailAddress,
                            autofocus: true,
                            decoration: const InputDecoration(
                                hintText: 'Course ID',
                                icon: Icon(
                                  Icons.indeterminate_check_box_outlined,
                                  color: Colors.black,
                                )),
                            validator: (value) => value!.isEmpty
                                ? 'Course ID can\'t be empty'
                                : null,
                            onSaved: (value) => _courseId = value!.trim(),
                          ),
                          TextFormField(
                            maxLines: 1,
                            keyboardType: TextInputType.text,
                            autofocus: false,
                            decoration: const InputDecoration(
                                hintText: 'Course Name',
                                icon: Icon(
                                  Icons.book,
                                  color: Colors.black,
                                )),
                            validator: (value) => value!.isEmpty
                                ? 'Course name can\'t be empty'
                                : null,
                            onSaved: (value) => _courseName = value!.trim(),
                          ),
                          TextFormField(
                            maxLines: 1,
                            keyboardType: TextInputType.text,
                            autofocus: true,
                            decoration: const InputDecoration(
                                hintText: 'Batch Year',
                                icon: Icon(
                                  Icons.numbers,
                                  color: Colors.black,
                                )),
                            validator: (value) => value!.isEmpty
                                ? 'Batch number can\'t be empty'
                                : null,
                            onSaved: (value) => _batch = value!.trim(),
                          ),
                          const SizedBox(height: 20),
                          RaisedButton(
                            elevation: 5.0,
                            shape: new RoundedRectangleBorder(
                                borderRadius: new BorderRadius.circular(30.0)),
                            color: Colors.deepPurple,
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
      backgroundColor: Colors.deepPurple,
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
        decoration: const BoxDecoration(
          color: Colors.deepPurple,
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
      child: TextFormField(
        maxLines: 1,
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          hintText: 'Enter no of classes for the day',
        ),
        keyboardType: TextInputType.number,
        autofocus: false,
        validator: (value) => value!.isEmpty ? 'Enter classes first' : null,
        onSaved: (value) => check = value!.trim(),
      ),
    );
  }

  Widget subjCodeInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 5.0),
      child: TextFormField(
        maxLines: 1,
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          hintText: 'Enter subject code',
        ),
        keyboardType: TextInputType.text,
        autofocus: false,
        validator: (value) =>
            value!.isEmpty ? 'Enter subject code first' : null,
        onSaved: (value) => classname = value!.trim(),
      ),
    );
  }

  Widget dateInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 0.0),
      child: TextFormField(
        maxLines: 1,
        decoration: const InputDecoration(
          hintText: 'Enter date in dd.mm.yy format',
        ),
        textAlign: TextAlign.center,
        keyboardType: TextInputType.datetime,
        autofocus: false,
        validator: (value) =>
            value!.isEmpty ? 'Enter date in dd.mm.yy format' : null,
        onSaved: (value) => date = value!.trim(),
      ),
    );
  }

  Widget codeInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: TextFormField(
        maxLines: 1,
        decoration: const InputDecoration(
          hintText: 'Enter your code',
        ),
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        autofocus: false,
        validator: (value) =>
            value!.isEmpty || value.contains('.') || value.contains(' ')
                ? 'Code cant be empty or have spaces and dots'
                : null,
        onSaved: (value) => secretcode = value!.trim(),
      ),
    );
  }
}
