import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:miniproject/pages/signup_page.dart';
import 'package:miniproject/pages/student/student_home_page.dart';
import 'package:miniproject/pages/teacher/teach_home_page.dart';
import 'package:miniproject/pages/teacher/teacher_root_page.dart';
import 'package:miniproject/pages/student/student_root_page.dart';
import 'package:miniproject/services/authentication.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Registration extends StatefulWidget {
  State<StatefulWidget> createState() {
    return _RegistrationState();
  }
}

class _RegistrationState extends State<Registration> {
  final _formKey = new GlobalKey<FormState>();

  // String _name;
  String _email;
  String _password;
  String _errorMessage;
  // String _role;

  bool _isLoading;

  // Check if form is valid before perform login or signup
  bool validateAndSave() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  // Perform login or signup

  /// Databse is not connected yet
  void validateAndSubmit() async {
    setState(() {
      _errorMessage = "";
      _isLoading = true;
    });
    if (validateAndSave()) {
      String userId = "";
      try {
        BaseAuth auth = new Auth();
        userId = await auth.signIn(_email, _password);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('userID', userId);

        var result =
            await Firestore.instance.collection('user').document(userId).get();
        print(result['role']);
        if (result['role'] == "Student") {
          await fetchStudentData(userId);
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => StudentHomePage()),
              (route) => false);
        }
        if (result['role'] == "Teacher") {
          await fetchTeacherData(userId);
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => TeacherHomePage()),
              (route) => false);
        }
        //   throw Exception("Only Teachers can login");
        // print('Signed in: $userId');
        // setState(() {
        //   _isLoading = false;
        // });

        // if (userId.length > 0 && userId != null) {
        //   Navigator.push(
        //     context,
        //     MaterialPageRoute(builder: (context) => Registration()),
        //   );
        // }
      } catch (e) {
        print('Error: $e');
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
          _formKey.currentState.reset();
        });
      }
    }
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
  void initState() {
    _errorMessage = "";
    _isLoading = false;
    // checkUser();
    super.initState();
  }

  void resetForm() {
    _formKey.currentState.reset();
    _errorMessage = "";
  }

  checkUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userID = prefs.getString('userID');
    final DocumentReference docRef =
        Firestore.instance.collection('user').document(userID);

    try {
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        print("User Doesn't Exist");
      } else {
        await docRef.get();
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        body: SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Stack(
            children: <Widget>[_showForm(), _showCircularProgress()],
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: _notHaveAnAccount(),
          ),
        ],
      ),
    ));
  }

  Widget _showCircularProgress() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    return Container(
      color: Colors.transparent,
      height: 0.0,
      width: 0.0,
    );
  }

  Widget _notHaveAnAccount() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        new Text(
          '''don't have an account?''',
          style: new TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w300,
          ),
        ),
        SizedBox(width: 5.0),
        GestureDetector(
            child: new Text(
              '''Register here''',
              style: new TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w300,
                  decoration: TextDecoration.underline,
                  color: Colors.blue),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Signuppage()),
              );
            }),
      ],
    );
  }

  Widget _showForm() {
    return new Container(
        padding: EdgeInsets.all(16.0),
        child: new Form(
          key: _formKey,
          child: new ListView(
            shrinkWrap: true,
            children: <Widget>[
              showLogo(),
              showEmailInput(),
              showPasswordInput(),
              showPrimaryButton(),
              showErrorMessage(),
            ],
          ),
        ));
  }

  Widget showErrorMessage() {
    if (_errorMessage.length > 0 && _errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(10.0),
        child: Center(
          child: new Text(
            _errorMessage,
            style: TextStyle(
                fontSize: 13.0,
                color: Colors.red,
                height: 1.0,
                fontWeight: FontWeight.w300),
          ),
        ),
      );
    } else {
      return new Container(
        height: 0.0,
      );
    }
  }

  Widget showLogo() {
    return new Hero(
      tag: 'hero',
      child: Padding(
        padding: EdgeInsets.fromLTRB(0.0, 25.0, 0.0, 0.0),
        child: CircleAvatar(
          backgroundColor: Colors.transparent,
          radius: 100.0,
          child: Image.asset('assets/Teacher.png'),
        ),
      ),
    );
  }

  Widget showEmailInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 80.0, 0.0, 0.0),
      child: new TextFormField(
        maxLines: 1,
        keyboardType: TextInputType.emailAddress,
        autofocus: false,
        decoration: new InputDecoration(
            hintText: 'Email',
            icon: new Icon(
              Icons.mail,
              color: Colors.grey,
            )),
        validator: (value) => value.isEmpty ? 'Email can\'t be empty' : null,
        onSaved: (value) => _email = value.trim(),
      ),
    );
  }

  Widget showPasswordInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new TextFormField(
        maxLines: 1,
        obscureText: true,
        autofocus: false,
        decoration: new InputDecoration(
            hintText: 'Password',
            icon: new Icon(
              Icons.lock,
              color: Colors.grey,
            )),
        validator: (value) => value.isEmpty ? 'Password can\'t be empty' : null,
        onSaved: (value) => _password = value.trim(),
      ),
    );
  }

  Widget showPrimaryButton() {
    return new Padding(
        padding: EdgeInsets.fromLTRB(0.0, 45.0, 0.0, 0.0),
        child: SizedBox(
          height: 40.0,
          child: new RaisedButton(
            elevation: 5.0,
            shape: new RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(30.0)),
            color: Colors.blueAccent,
            child: new Text('Login',
                style: new TextStyle(fontSize: 20.0, color: Colors.white)),
            onPressed: validateAndSubmit,
          ),
        ));
  }
  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: Text('Login'),
  //       backgroundColor: Colors.pink,
  //     ),
  //     body: ListView(padding: const EdgeInsets.all(2), children: <Widget>[
  //       GestureDetector(
  //         onTap: () {
  //           Navigator.push(
  //             context,
  //             MaterialPageRoute(
  //                 builder: (context) => new TeacherRootPage(
  //                       auth: new Auth(),
  //                     )),
  //           );
  //         },
  //         child: Padding(
  //           padding: const EdgeInsets.all(80.0),
  //           child: Container(
  //             height: 150,
  //             width: 100,
  //             decoration: BoxDecoration(
  //               shape: BoxShape.circle,
  //               color: Colors.orange,
  //             ),
  //             margin: EdgeInsets.all(10.0),
  //             child: const Center(
  //                 child: Text(' Login as \nTEACHER',
  //                     style: TextStyle(
  //                       color: Colors.white,
  //                       fontWeight: FontWeight.bold,
  //                       fontSize: 18.0,
  //                     ))),
  //           ),
  //         ),
  //       ),
  //       GestureDetector(
  //         onTap: () {
  //           Navigator.push(
  //             context,
  //             MaterialPageRoute(
  //                 builder: (context) => new StudentRootPage(
  //                       auth: new Auth(),
  //                     )),
  //           );
  //         },
  //         child: Container(
  //           height: 150,
  //           width: 100,
  //           decoration: BoxDecoration(
  //             shape: BoxShape.circle,
  //             color: Colors.purple,
  //           ),
  //           margin: EdgeInsets.all(10.0),
  //           child: const Center(
  //             child: Text(' Login as \nSTUDENT',
  //                 style: TextStyle(
  //                     fontWeight: FontWeight.bold,
  //                     fontSize: 18.0,
  //                     color: Colors.white)),
  //           ),
  //         ),
  //       ),
  //     ]),
  //   );
}
