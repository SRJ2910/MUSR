import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:musr/pages/signup_page.dart';
import 'package:musr/pages/student/student_home_page.dart';
import 'package:musr/pages/teacher/teach_home_page.dart';
import 'package:musr/services/authentication.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Registration extends StatefulWidget {
  State<StatefulWidget> createState() {
    return _RegistrationState();
  }
}

class _RegistrationState extends State<Registration> {
  final _formKey = GlobalKey<FormState>();

  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  // String? _name;
  String? _email;
  String? _password;
  String? _errorMessage;
  // String? _role;

  bool _isLoading = false;

  // Check if form is valid before perform login or signup
  bool validateAndSave() {
    final form = _formKey.currentState;
    if (form!.validate()) {
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
      String? userId = "";
      try {
        BaseAuth auth = new Auth();
        userId = await auth.signIn(_email!, _password!);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('userID', userId);

        var result =
            await _firebaseFirestore.collection('user').doc(userId).get();
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
          _errorMessage = e.toString();
          _formKey.currentState!.reset();
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchStudentData(String? userID) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await _firebaseFirestore
        .collection('user')
        .doc(userID)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      print(documentSnapshot.get('batch'));
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

  Future<void> fetchTeacherData(String? userID) async {
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
  void initState() {
    _errorMessage = "";
    _isLoading = false;
    // checkUser();
    super.initState();
  }

  void resetForm() {
    _formKey.currentState!.reset();
    _errorMessage = "";
  }

  checkUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userID = prefs.getString('userID');
    final DocumentReference docRef =
        _firebaseFirestore.collection('user').doc(userID);

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
    return Scaffold(
        body: SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: <Widget>[_showForm()],
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
      return const Center(child: CircularProgressIndicator());
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
            child: const Text(
              '''Register here''',
              style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w300,
                  decoration: TextDecoration.underline,
                  color: Colors.deepPurple),
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
    return Container(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
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
    if (_errorMessage!.isNotEmpty && _errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(10.0),
        child: Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(
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
    return Hero(
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
      child: TextFormField(
        maxLines: 1,
        keyboardType: TextInputType.emailAddress,
        autofocus: false,
        decoration: const InputDecoration(
            hintText: 'Email',
            icon: Icon(
              Icons.mail,
              color: Colors.black,
            )),
        validator: (value) => value!.isEmpty ? 'Email can\'t be empty' : null,
        onSaved: (value) => _email = value!.trim(),
      ),
    );
  }

  Widget showPasswordInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: TextFormField(
        maxLines: 1,
        obscureText: true,
        autofocus: false,
        decoration: const InputDecoration(
            hintText: 'Password',
            icon: Icon(
              Icons.lock,
              color: Colors.black,
            )),
        validator: (value) =>
            value!.isEmpty ? 'Password can\'t be empty' : null,
        onSaved: (value) => _password = value!.trim(),
      ),
    );
  }

  Widget showPrimaryButton() {
    return Padding(
        padding: EdgeInsets.fromLTRB(0.0, 45.0, 0.0, 0.0),
        child: SizedBox(
          height: 40.0,
          child: ElevatedButton(
            style: ButtonStyle(
              elevation: MaterialStateProperty.all(5.0),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              backgroundColor: MaterialStateProperty.all(Colors.deepPurple), 
            ),
            onPressed: validateAndSubmit,
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                    color: Colors.white,
                  ))
                : Text('Login',
                    style: TextStyle(fontSize: 20.0, color: Colors.white)),
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
