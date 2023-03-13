import 'dart:collection';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_barcodes/barcodes.dart';

class QrGenerator extends StatefulWidget {
  String courseName;
  String courseId;
  String batch;
  QrGenerator({Key key, this.courseId, this.courseName, this.batch})
      : super(key: key);

  @override
  State<QrGenerator> createState() => _QrGeneratorState();
}

class _QrGeneratorState extends State<QrGenerator> {
  List<String> _qrValue = [];
  int globalIndex = 0;

  @override
  void initState() {
    randomvaluegenerator();
    clearcurrentattandance();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<String> _participants = [
      'student_1',
      'student_2',
      'student_3',
      'student_4',
      'student_5',
      'student_6'
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink,
        title: Text(
          "${widget.courseId}",
          overflow: TextOverflow.visible,
          softWrap: true,
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              // _textBox(widget.courseName, widget.courseId),
              _qrBox(),
              // submitButton(),
              // _presenceBox(_participants)
              _presentBox()
            ],
          ),
        ),
      ),
    );
  }

  Widget _textBox(String _courseName, String _courseID) {
    return SafeArea(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _courseID + " : ",
            textScaleFactor: 1.5,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            _courseName,
            textScaleFactor: 1.5,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _qrBox() {
    return StreamBuilder(
        stream: Firestore.instance
            .collection('QRcode')
            .document(widget.courseId)
            .collection(widget.courseId)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (snapshot.hasData) {
            snapshot.data.documents.forEach((doc) {
              _qrValue.add(doc['qr']);
            });
          } else if (!snapshot.hasData) {
            return CircularProgressIndicator();
          }

          if (_qrValue.length == 1) {
            randomvaluegenerator();
            return CircularProgressIndicator();
          } else {
            String curr = _qrValue[0];
            _qrValue.clear();
            return Container(
              margin: EdgeInsets.all(10.0),
              child: Center(
                  child: SfBarcodeGenerator(
                // showValue: true,
                value: curr,
                symbology: QRCode(),
              )),
            );
          }
        });
  }

  List<String> present_student_ID = [];
  List<String> present_student_Name = [];
  Widget _presentBox() {
    return StreamBuilder(
      stream: Firestore.instance
          .collection('course')
          .document(widget.courseId)
          .collection(widget.batch)
          .document('classtaken')
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData) {
          return CircularProgressIndicator();
        } else if (snapshot.hasData) {
          try {
            Map<dynamic, dynamic> data = snapshot.data['currentAttendance'];
            SplayTreeMap<dynamic, dynamic> sortedMap =
                SplayTreeMap<dynamic, dynamic>.from(data);
            present_student_ID =
                sortedMap.keys.map((element) => element.toString()).toList();
            present_student_Name =
                sortedMap.values.map((element) => element.toString()).toList();
          } catch (e) {
            print("NO Data");
          }

          // print(present_student_ID);
          // print(present_student_Name);
        }

        return Column(
          children: [
            Align(
              child: Padding(
                padding: const EdgeInsets.only(right: 10, left: 10),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text("Batch : "),
                          Text(
                            widget.batch,
                            textScaleFactor: 1.5,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text("Total : "),
                          Text(
                            present_student_ID.length.toString(),
                            textScaleFactor: 1.5,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  decoration: BoxDecoration(
                      // color: Colors.pinkAccent,
                      borderRadius: BorderRadius.all(Radius.circular(20))),
                ),
              ),
              alignment: Alignment.centerRight,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                height: 250,
                child: ListView.builder(
                  itemCount: present_student_ID.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      // focusColor: Colors.amber,
                      iconColor: Colors.black,
                      leading: Icon(Icons.person),
                      title: Text(present_student_Name[index]),
                      subtitle: Text(present_student_ID[index]),
                      trailing: Icon(
                        Icons.check,
                        color: Colors.green,
                      ),
                      onTap: () {},
                    );
                  },
                ),
              ),
            ),
          ],
        );
        // return Column(
        //   children: [
        //     Text(widget.batch),
        //     Container(
        //       height: MediaQuery.of(context).size.height - 600,
        //       width: MediaQuery.of(context).size.width - 25,
        //       decoration: BoxDecoration(
        //         color: Colors.green,
        //       ),
        //       margin: EdgeInsets.all(10.0),
        //       child: GridView.count(
        //         crossAxisCount: 5,
        //         children: List.generate(present_student_ID.length, (index) {
        //           return Container(
        //             decoration: BoxDecoration(
        //               shape: BoxShape.rectangle,
        //               color: Colors.white,
        //               borderRadius: BorderRadius.circular(10),
        //             ),
        //             margin:
        //                 EdgeInsets.only(top: 10, bottom: 10, left: 5, right: 5),
        //             child: Center(
        //               child: Text(
        //                 '${present_student_ID[index]}',
        //                 style: TextStyle(fontSize: 10),
        //               ),
        //             ),
        //           );
        //         }), // Enable gridlines
        //       ),
        //     ),
        //   ],
        // );
      },
    );
  }

  Widget _presenceBox(List<String> participants) {
    return Column(
      children: [
        Text(widget.batch),
        Container(
          height: MediaQuery.of(context).size.height - 600,
          width: MediaQuery.of(context).size.width - 25,
          decoration: BoxDecoration(
            color: Colors.green,
          ),
          margin: EdgeInsets.all(10.0),
          child: GridView.count(
            crossAxisCount: 5,
            children: List.generate(participants.length, (index) {
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: EdgeInsets.only(top: 10, bottom: 10, left: 5, right: 5),
                child: Center(
                  child: Text(
                    '${participants[index]}',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              );
            }), // Enable gridlines
          ),
        ),
      ],
    );
  }

  // emptyListChecker() {
  //   final collectionReference = Firestore.instance.collection('QRcode');
  //   final stream = collectionReference.snapshots();

  //   stream.listen((querySnapshot) {
  //     querySnapshot.documents.forEach((documentSnapshot) {
  //       if (documentSnapshot.exists) {
  //         // Do something with the data
  //         print(documentSnapshot.data);
  //       } else
  //         print("EMPTYYYYYYYYYYYYYYYYYY");
  //     });
  //   });
  // }
  classTaken() async {
    final DocumentReference docRef = Firestore.instance
        .collection('course')
        .document(widget.courseId)
        .collection(widget.batch)
        .document('classtaken');

    String date =
        // "22-02-2023";
        DateTime.now().day.toString() +
            '-' +
            DateTime.now().month.toString() +
            '-' +
            DateTime.now().year.toString();

    try {
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        // If the document doesn't exist, create a new one
        await docRef.setData({
          'date': [date]
        }).then((value) => print("New document added successfully"));
      } else {
        // If the document exists, update it
        await docRef.updateData({
          'date': FieldValue.arrayUnion([date])
        }).then((value) =>
            print("$date added to the existing document successfully"));
      }
    } catch (e) {
      print(e.toString());
    }
  }

  randomvaluegenerator() async {
    for (int i = 0; i < 2; i++) {
      String val = randomvalue();
      print(val);
      try {
        await Firestore.instance
            .collection('QRcode')
            .document(widget.courseId)
            .collection(widget.courseId)
            .document(val)
            .setData({'qr': val});
      } catch (e) {
        print(e.toString());
      }
    }
  }

  randomvalue() {
    return widget.courseId +
        widget.batch +
        Random().nextInt(999999).toString() +
        widget.courseName.substring(0, 3) +
        Random().nextInt(999999).toString();
  }

  clearcurrentattandance() async {
    final DocumentReference docRef = Firestore.instance
        .collection('course')
        .document(widget.courseId)
        .collection(widget.batch)
        .document('classtaken');

    try {
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        // If the document doesn't exist, create a new one
        print("already deleted");
      } else {
        // If the document exists, update it
        final updateData = {'currentAttendance': FieldValue.delete()};
        docRef
            .updateData(updateData)
            .then((value) => print('Field deleted successfully'))
            .catchError((error) => print('Failed to delete field: $error'));
      }

      classTaken();
    } catch (e) {
      print(e.toString());
    }
  }
}
