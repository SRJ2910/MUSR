import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:miniproject/pages/register_page.dart';
import 'package:miniproject/services/authentication.dart';

class Signuppage extends StatefulWidget {
  Signuppage({Key key}) : super(key: key);

  @override
  State<Signuppage> createState() => _SignuppageState();
}

class _SignuppageState extends State<Signuppage> {
  final _formKey = new GlobalKey<FormState>();

  String _name;
  String _email;
  String _password;
  String _errorMessage;
  String _role;
  String _id;
  String _batch;

  bool _isLoading;
  bool _isStudent = false;

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
        userId = await auth.signUp(_email, _password);

//add all user to database
        await Firestore.instance.collection('user').document(userId).setData({
          'email': _email,
          'role': _role,
          'name': _name,
        });

//add student to database
        if (_isStudent) {
          await Firestore.instance
              .collection('student')
              .document(_batch)
              .setData({
            'email': _email,
            'name': _name,
            'id': _id,
          });
        }
        print("User Added Successfully");
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

        if (userId.length > 0 && userId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Registration()),
          );
        }
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

  @override
  void initState() {
    _errorMessage = "";
    _isLoading = false;
    super.initState();
  }

  void resetForm() {
    _formKey.currentState.reset();
    _errorMessage = "";
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        body: Stack(
      children: <Widget>[
        _showForm(),
        _showCircularProgress(),
      ],
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

  Widget _showForm() {
    return new Container(
        padding: EdgeInsets.all(16.0),
        child: new Form(
          key: _formKey,
          child: new ListView(
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
          decoration: InputDecoration(
            hintText: 'Institute ID',
            icon: Icon(
              Icons.view_comfortable_outlined,
              color: Colors.grey,
            ),
          ),
          validator: (value) => value.isEmpty ? 'ID can\'t be empty' : null,
          onSaved: (value) => _id = value.trim(),
        ),
      );
    } else {
      return new Container(
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
          decoration: InputDecoration(
            hintText: 'Batch start year (eg. 2020) ',
            icon: Icon(
              Icons.calendar_month_rounded,
              color: Colors.grey,
            ),
          ),
          validator: (value) => value.isEmpty ? 'Batch can\'t be empty' : null,
          onSaved: (value) => _batch = value.trim(),
        ),
      );
    } else {
      return new Container(
        height: 0.0,
      );
    }
  }

  Widget showDropDown() {
    List<DropdownMenuItem<String>> role = [];
    role.add(DropdownMenuItem(
      child: Text("Teacher"),
      value: "Teacher",
    ));
    role.add(DropdownMenuItem(
      child: Text("Student"),
      value: "Student",
    ));
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: Row(
        children: [
          Icon(
            Icons.person,
            color: Colors.grey,
          ),
          SizedBox(width: 15),
          Expanded(
            child: DropdownButton(
                items: role,
                value: _role,
                iconEnabledColor: Colors.grey,
                isExpanded: true,
                hint: Text("Select Role"),
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
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
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

  Widget showNameInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 80.0, 0.0, 0.0),
      child: new TextFormField(
        maxLines: 1,
        keyboardType: TextInputType.text,
        autofocus: false,
        decoration: new InputDecoration(
            hintText: 'Name',
            icon: new Icon(
              Icons.person,
              color: Colors.grey,
            )),
        validator: (value) => value.isEmpty ? 'Name can\'t be empty' : null,
        onSaved: (value) => _name = value.trim(),
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
            child: new Text('Register',
                style: new TextStyle(fontSize: 20.0, color: Colors.white)),
            onPressed: validateAndSubmit,
          ),
        ));
  }
}
