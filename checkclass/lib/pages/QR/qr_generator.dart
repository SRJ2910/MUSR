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
        title: Text('QR Generator'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _textBox(widget.courseName, widget.courseId),
              _qrBox(),
              // submitButton(),
              _presenceBox(_participants)
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
        stream: Firestore.instance.collection('QRcode').snapshots(),
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
                showValue: true,
                value: curr,
                symbology: QRCode(),
              )),
            );
          }
        });
  }

  Widget submitButton() {
    return GestureDetector(
      child: Container(
        // height: 50,
        // width: 200,
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          color: Colors.pink,
        ),
        // margin: EdgeInsets.all(10.0),
        child: Center(
            child: Text('Submit',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ))),
      ),
      onTap: () {
        setState(() {
          globalIndex++;
        });
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

  randomvaluegenerator() async {
    for (int i = 0; i < 2; i++) {
      String val = randomvalue();
      print(val);
      try {
        await Firestore.instance
            .collection('QRcode')
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
}
