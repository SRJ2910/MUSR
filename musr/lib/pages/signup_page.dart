import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:musr/pages/register_page.dart';
import 'package:musr/services/authentication.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class Signuppage extends StatefulWidget {
  Signuppage({Key? key}) : super(key: key);

  @override
  State<Signuppage> createState() => _SignuppageState();
}

class _SignuppageState extends State<Signuppage> {
  final _formKey = GlobalKey<FormState>();

  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  String? _name;
  String? _email;
  String? _password;
  String? _errorMessage;
  String? _role;
  String? _id;
  String? _batch;

  bool _isLoading = false;
  bool _isStudent = false;

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
      String userId = "";
      try {
        BaseAuth auth = new Auth();
        SharedPreferences prefs = await SharedPreferences.getInstance();

        userId = await auth.signUp(_email!, _password!);
        prefs.setString('userID', userId);

//add student to database
        if (_isStudent) {
          await _firebaseFirestore.collection('user').doc(userId).set({
            'email': _email,
            'role': _role,
            'name': _name,
            'batch': _batch,
            'id': _id,
            'access': false,
          });
        } else {
          await _firebaseFirestore.collection('user').doc(userId).set({
            'email': _email,
            'role': _role,
            'name': _name,
            'access': false,
          });
        }
        print("User Added Successfully");
        setState(() {
          _isLoading = false;
        });

        if (userId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Registration()),
          );
        }
      } catch (e) {
        print('Error: $e');
        setState(() {
          _isLoading = false;
          // _errorMessage = e.message;
          _formKey.currentState!.reset();
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    _errorMessage = "";
    _isLoading = false;
    super.initState();
  }

  void resetForm() {
    _formKey.currentState!.reset();
    _errorMessage = "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
      child: Column(
        children: <Widget>[
          _showForm(),
          privacy_terms(),
          // _showCircularProgress(),
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

  Widget _showForm() {
    return Container(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              showLogo(),
              showNameInput(),
              showEmailInput(),
              showPasswordInput(),
              showDropDown(),
              showID(),
              showBatch(),
              showPrimaryButton(),
              showErrorMessage(),
            ],
          ),
        ));
  }

  Widget showID() {
    if (_isStudent) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
        child: TextFormField(
          maxLines: 1,
          keyboardType: TextInputType.number,
          autofocus: false,
          decoration: const InputDecoration(
            hintText: 'Institute ID',
            icon: Icon(
              Icons.view_comfortable_outlined,
              color: Colors.grey,
            ),
          ),
          validator: (value) => value!.isEmpty ? 'ID can\'t be empty' : null,
          onSaved: (value) => _id = value!.trim(),
        ),
      );
    } else {
      return Container(
        height: 0.0,
      );
    }
  }

  Widget showBatch() {
    if (_isStudent) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
        child: TextFormField(
          maxLines: 1,
          keyboardType: TextInputType.number,
          autofocus: false,
          decoration: const InputDecoration(
            hintText: 'Batch start year (eg. 2020) ',
            icon: Icon(
              Icons.calendar_month_rounded,
              color: Colors.grey,
            ),
          ),
          validator: (value) => value!.isEmpty ? 'Batch can\'t be empty' : null,
          onSaved: (value) => _batch = value!.trim(),
        ),
      );
    } else {
      return Container(
        height: 0.0,
      );
    }
  }

  Widget showDropDown() {
    List<DropdownMenuItem<String?>> role = [];
    role.add(const DropdownMenuItem(
      value: "Teacher",
      child: Text("Teacher"),
    ));
    role.add(const DropdownMenuItem(
      value: "Student",
      child: Text("Student"),
    ));
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: Row(
        children: [
          const Icon(
            Icons.person,
            color: Colors.black,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: DropdownButton<String?>(
                items: role,
                value: _role,
                iconEnabledColor: Colors.grey,
                isExpanded: true,
                hint: const Text("Select Role"),
                onChanged: (value) {
                  print(value);
                  if (value == "Student") {
                    setState(() {
                      _isStudent = true;
                    });
                  } else {
                    setState(() {
                      _isStudent = false;
                    });
                  }
                  setState(() {
                    _role = value;
                  });
                }),
          ),
        ],
      ),
    );
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
      return Container(
        height: 0.0,
      );
    }
  }

  Widget showLogo() {
    return Hero(
      tag: 'hero',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0.0, 25.0, 0.0, 0.0),
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
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
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

  Widget showNameInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 80.0, 0.0, 0.0),
      child: TextFormField(
        maxLines: 1,
        keyboardType: TextInputType.text,
        autofocus: false,
        decoration: const InputDecoration(
            hintText: 'Name',
            icon: Icon(
              Icons.person,
              color: Colors.black,
            )),
        validator: (value) => value!.isEmpty ? 'Name can\'t be empty' : null,
        onSaved: (value) => _name = value!.trim(),
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
        padding: const EdgeInsets.fromLTRB(0.0, 45.0, 0.0, 0.0),
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
                    ),
                  )
                : Text('Register',
                    style: TextStyle(fontSize: 20.0, color: Colors.white)),
          ),
        ));
  }

  Widget privacy_terms() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        GestureDetector(
            child: const Text(
              '''Terms of service''',
              style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w300,
                  decoration: TextDecoration.underline,
                  color: Colors.deepPurple),
            ),
            onTap: () async {
              await launchUrl(
                Uri.parse(
                    'https://doc-hosting.flycricket.io/musr-smart-attendance-system-terms-of-use/b31021e8-8d86-4ad4-84a7-ddeedb442dc8/terms'),
                mode: LaunchMode.inAppWebView,
              );
            }),
        const Text(
          '''&''',
          textScaleFactor: 1.2,
          style:
              TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
        ),
        GestureDetector(
            child: const Text(
              '''Privacy Policy''',
              style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w300,
                  decoration: TextDecoration.underline,
                  color: Colors.deepPurple),
            ),
            onTap: () async {
              await launchUrl(
                Uri.parse(
                    'https://doc-hosting.flycricket.io/musr-smart-attendance-system-privacy-policy/e02edcb1-0fe2-473c-ae79-f238c8ef5fee/privacy'),
                mode: LaunchMode.inAppWebView,
              );
            }),
      ],
    );
  }
}
