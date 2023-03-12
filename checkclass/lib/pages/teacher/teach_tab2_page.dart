import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:miniproject/services/authentication.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as syexcel;

class TeacherBasicSecPage extends StatefulWidget {
  TeacherBasicSecPage({Key key, this.auth, this.userId, this.logoutCallback})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback logoutCallback;

  final String userId;

  @override
  State<StatefulWidget> createState() => new _TeacherBasicSecPageState();
}

class _TeacherBasicSecPageState extends State<TeacherBasicSecPage> {
  //final FirebaseDatabase _database = FirebaseDatabase.instance;
  final GlobalKey<FormState> _formKey2 = GlobalKey<FormState>();

  //final _textEditingController = TextEditingController();
  //bool _isEmailVerified = false;
  String subject;
  String month;
  String year;
  String str;
  String userId = '';
  int shows = 0;

  bool _loading = false;

  String subjectcode;
  String batch;
  Map<String, List<String>> list = {};
  List<String> class_list = [];
  int totalStrength = 0;

  bool validateAndSave() {
    final form = _formKey2.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  @override
  void initState() {
    userId = widget.userId;
    super.initState();
    //_checkEmailVerification();
  }

  @override
  Widget build(BuildContext context) {
    if (shows == 0) {
      return showEntryPage();
    } else {
      return showDataPage();
    }
  }

  Widget showEntryPage() {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          resizeToAvoidBottomInset: false,
          body: SingleChildScrollView(
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        enterDetails(),
                        formInput(),
                        GestureDetector(
                          onTap: () async {
                            if (validateAndSave()) {
                              // setState(() {
                              //   shows = 1;
                              // });
                              print(batch);
                              print(subjectcode);
                              // showDataPage();
                              setState(() {
                                _loading = true;
                              });
                              await fetchdata(batch, subjectcode);
                            }
                          },
                          child: Container(
                            margin: EdgeInsets.all(70),
                            width: 300,
                            height: 40,
                            //color:Colors.pink,
                            decoration: BoxDecoration(
                                color: Colors.pink,
                                shape: BoxShape.rectangle,
                                //borderRadius: BorderRadius.circular(10),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(25))),
                            child: Center(
                              child: _loading
                                  ? CircularProgressIndicator()
                                  : Text(
                                      'View',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )),
    );
  }

  fetchdata(String batch, String subjectCode) async {
    list.clear();
    List<String> date_list = [];
    List<String> id_list = [];

    final CollectionReference docRef = Firestore.instance
        .collection('course')
        .document(subjectCode)
        .collection(batch);

    try {
      final docSnapshot = await docRef.getDocuments();

      for (int i = 0; i < docSnapshot.documents.length; i++) {
        id_list.add(docSnapshot.documents[i].documentID);
      }

      // print(id_list);
      for (int i = 0; i < id_list.length; i++) {
        DocumentReference docRef1 = docRef.document(id_list[i]);
        List<dynamic> dateDynamic = (await docRef1.get()).data['date'];
        List<String> dateString = dateDynamic.map((e) => e as String).toList();
        list.addAll({id_list[i]: dateString});
      }
      print(list);
      await getStrength();
      await getClassDaysList();
      await make_excel();
    } catch (e) {
      setState(() {
        _loading = false;
      });
      print("Error on fatechdata()");
    }
  }

  getStrength() async {
    final DocumentReference docRef =
        Firestore.instance.collection('detail').document(batch);

    try {
      await docRef.get().then((docSnapshot) {
        if (docSnapshot.exists) {
          print(docSnapshot.data['strength'].runtimeType);
          setState(() {
            totalStrength = docSnapshot.data['strength'];
          });
        }
      });

      class_list.clear();
      for (int i = 1; i <= totalStrength; i++) {
        String val = "$batch" + "11";

        if (i < 10)
          val = val + '00' + i.toString();
        else if (i >= 10 && i < 100)
          val = val + '0' + i.toString();
        else
          val = val + i.toString();

        class_list.add(val);
      }
    } catch (e) {
      print("Error on getStrength()");
    }
  }

  List<String> totalClassDays = [];
  getClassDaysList() async {
    totalClassDays.clear();
    final DocumentReference docRef = Firestore.instance
        .collection('course')
        .document(subjectcode)
        .collection(batch)
        .document('classtaken');

    List<dynamic> dateDynamic = (await docRef.get()).data['date'];
    List<String> dateString = dateDynamic.map((e) => e as String).toList();
    totalClassDays.addAll(dateString);
  }

  ListSorting() {
    totalClassDays.sort((a, b) => DateFormat('d-M-yyyy')
        .parse(a)
        .compareTo(DateFormat('d-M-yyyy').parse(b)));
  }

  make_excel() async {
    //sorting the list
    ListSorting();

    //printing the list
    print("Total Classes till now list {totalClassDays} :" +
        totalClassDays.toString());
    print("Total Strength :" + totalStrength.toString());
    print("Total ID {class_list} :" + class_list.toString());
    print("Fetched Map {list} :" + list.toString());

    final syexcel.Workbook workbook = syexcel.Workbook();
    await write_excel(workbook);
    setState(() {
      _loading = false;
    });
    print("goooooooo");
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final String path = (await getApplicationSupportDirectory()).path;
    final String append = batch + "_" + subjectcode;
    final String fileName = '$path/$append.xlsx';
    final File file = File(fileName);
    await file.writeAsBytes(bytes, flush: true);
    OpenFile.open(fileName);
  }

  write_excel(syexcel.Workbook workbook) async {
    final syexcel.Worksheet sheet = workbook.worksheets[0];

    sheet.getRangeByIndex(1, 1).setText("Student ID");
    for (int i = 0; i < class_list.length; i++)
      sheet.getRangeByIndex(i + 2, 1).setText(class_list[i]);

    for (int i = 0; i < totalClassDays.length; i++)
      sheet.getRangeByIndex(1, i + 3).setText(totalClassDays[i]);

    for (int i = 0; i < class_list.length; i++) {
      for (int j = 0; j < totalClassDays.length; j++) {
        if (list[class_list[i]] != null &&
            list[class_list[i]].contains(totalClassDays[j])) {
          sheet.getRangeByIndex(i + 2, j + 3).setText("Present");
        } else {
          sheet.getRangeByIndex(i + 2, j + 3).setText("A");
        }
      }
    }
  }

  Widget formInput() {
    return SingleChildScrollView(
      child: new Container(
          //padding: EdgeInsets.all(2.0),
          child: new Form(
        key: _formKey2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: new ListView(
            shrinkWrap: true,
            children: <Widget>[
              subjCodeInput(),
              batchInput(),
              // yearInput(),
            ],
          ),
        ),
      )),
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

  Widget subjCodeInput() {
    return new TextFormField(
      maxLines: 1,
      textAlign: TextAlign.center,
      decoration: new InputDecoration(
        hintText: 'Enter Subject Code',
      ),
      keyboardType: TextInputType.text,
      autofocus: false,
      validator: (value) => value.isEmpty ? 'Enter Subject Code' : null,
      onSaved: (value) => subjectcode = value.trim(),
    );
  }

  Widget dateInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 0.0),
      child: new TextFormField(
        maxLines: 1,
        decoration: new InputDecoration(
          hintText: 'Enter Month',
        ),
        textAlign: TextAlign.center,
        keyboardType: TextInputType.datetime,
        autofocus: false,
        validator: (value) => value.isEmpty ? 'Enter Month first' : null,
        onSaved: (value) => batch = value.trim(),
      ),
    );
  }

  Widget batchInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 0.0),
      child: new TextFormField(
        maxLines: 1,
        decoration: new InputDecoration(
          hintText: 'Enter Batch Year',
        ),
        textAlign: TextAlign.center,
        keyboardType: TextInputType.datetime,
        autofocus: false,
        validator: (value) => value.isEmpty ? 'Enter batch first' : null,
        onSaved: (value) => batch = value.trim(),
      ),
    );
  }

  Widget yearInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new TextFormField(
        maxLines: 1,
        decoration: new InputDecoration(
          hintText: 'Enter Year',
        ),
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        autofocus: false,
        validator: (value) => value.isEmpty ? 'Enter Year first' : null,
        onSaved: (value) => year = value.trim(),
      ),
    );
  }

  Widget showDataPage() {
    //Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => TeachDetails()));
    return Scaffold(
      body: Container(
        child: FutureBuilder(
            future: getData(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.data == null) {
                return Scaffold(
                  body: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        alignment: Alignment.center,
                        child: CircularProgressIndicator(),
                      ),
                      SizedBox(height: 10),
                      Text('Loading'),
                    ],
                  ),
                );
                //return Center(child: Container(child: Text('Loading Data',style: TextStyle(fontSize: 30,fontWeight: FontWeight.bold),),));
              }

              return SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    DataTable(
                        sortColumnIndex: 0,
                        sortAscending: true,
                        columns: [
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Attended'), numeric: true)
                        ],
                        rows: snapshot.data.entries.map<DataRow>((entry) {
                          return DataRow(cells: [
                            DataCell(Text(entry.key)),
                            DataCell(Text(entry.value.toString())),
                          ]);
                        }).toList()),
                    Center(
                      child: Container(
                        margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
                        child: RaisedButton(
                            color: Colors.indigo,
                            textColor: Colors.white,
                            onPressed: () {
                              setState(() {
                                shows = 0;
                              });
                            },
                            child: Text('Return')),
                      ),
                    ),
                  ],
                ),
              );
            }),
      ),
    );
  }

  Future<Map> getData() async {
    var attendance = new Map();
    int subCount = 0;
    String queryMonth = month.toString() + '.' + year.toString();
    var j1;
    var users = await Firestore.instance.collection('users').getDocuments();
    var idList = users.documents;
    for (int i = 0; i < idList.length; i++) {
      if (idList[i].data['role'] == 'student') {
        var y = await Firestore.instance
            .collection('users')
            .document(idList[i].documentID)
            .collection(subject)
            .document(queryMonth)
            .get();
        for (int j = 1; j <= 30; j++) {
          if (j < 10)
            j1 = j.toString().padLeft(2, '0');
          else
            j1 = j.toString();
          try {
            subCount += y.data[j1]['count'];
          } catch (e) {
            continue;
          }
        }
        attendance[idList[i].data['Name']] = subCount;
        subCount = 0;
      }
    }
    //print(attendance);
    return attendance;
  }
}
