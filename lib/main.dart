import 'dart:async';

import 'package:battery/battery.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_icons/flutter_icons.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      darkTheme: ThemeData(
          primaryColor: Color(0xFFfff),
          canvasColor: Color(0xFF16131f),
          iconTheme: IconThemeData(color: Colors.white),
          textTheme:
              Theme.of(context).textTheme.apply(bodyColor: Colors.white)),
      title: 'VibeWithMe',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Battery _battery = Battery();

  var battLevel = 0;

  BatteryState? _batteryState;
  late StreamSubscription<BatteryState> _batteryStateSubscription;

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  final TextEditingController _controller = TextEditingController();

  CollectionReference users = FirebaseFirestore.instance.collection('users');

  DateTime now = new DateTime.now();

  var data;

  Color _cardColor = Color(0xff221f2b);

  var _colorMode;

  Future<void> addUser() {
    // Call the user's CollectionReference to add a new user
    return users
        .add({'Message': _controller.text, 'Time': now, 'battery': battLevel});
  }

  final firestoreInstance = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    setCardColor(_colorMode);
    _batteryStateSubscription =
        _battery.onBatteryStateChanged.listen((BatteryState state) {
      setState(() {
        _batteryState = state;
      });
    });
    setData();
  }

  showData() {
    //swap to greater than or equal to
    if (battLevel <= 90) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Stack(
          children: <Widget>[
            Align(
              alignment: Alignment.topRight,
              child: Text(
                '$battLevel',
                style: TextStyle(fontSize: 40),
              ),
            ),
            Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Ionicons.ios_battery_full,
                  size: 100,
                ),
                SizedBox(
                  height: 0,
                ),
                Text(
                  "Unable To Chat",
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  "Battery must be greater than 90% and cannot be plugged in",
                  textAlign: TextAlign.center,
                ),
              ],
            )),
          ],
        ),
      );
    }

    //swap to less than or equal to
    if (battLevel >= 0) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Text(
                '$battLevel',
                style: TextStyle(fontSize: 40),
              ),
            ),
            Expanded(
              child: _buildBody(context),
            ),
            Expanded(
                child: Stack(
              children: [
                Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                        child: Row(
                          children: [
                            Expanded(
                                child: SizedBox(
                                    height: 60.0,
                                    child: TextField(
                                        controller: _controller,
                                        style: TextStyle(fontSize: 17),
                                        decoration: InputDecoration(
                                          contentPadding:
                                              EdgeInsets.only(top: 10),
                                          border: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          errorBorder: InputBorder.none,
                                          disabledBorder: InputBorder.none,
                                          // add padding to adjust text
                                          isDense: true,
                                          hintText: "Say Something",
                                        )))),
                            GestureDetector(
                              onTap: () async => addUser(),
                              child: Icon(Feather.send),
                            )
                          ],
                        ),
                      ),
                      height: 60,
                      width: MediaQuery.of(context).size.width - 40,
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    )),
              ],
            )),
          ],
        ),
      );
    }
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Ionicons.ios_battery_dead,
          size: 100,
        ),
        SizedBox(
          height: 20,
        ),
        Text(
          "Unable To Chat",
          style: TextStyle(fontSize: 20),
        ),
        SizedBox(
          height: 10,
        ),
        Text(
          "Battery must be less than 10% and cannot be plugged in",
          textAlign: TextAlign.center,
        ),
      ],
    ));
  }

  Future setData() async {
    final int batteryLevel = await _battery.batteryLevel;
    setState(() {
      battLevel = batteryLevel;
      print(battLevel);
    });
  }

  setCardColor(mode) {
    if (_colorMode == Brightness.dark) {
      setState(() {
        _cardColor = Color(0xFF221f2b);
      });
    }
    // if (_colorMode == Brightness.light) {
    //   setState(() {
    //     _cardColor = Color(0xFFe4e1e4);
    //   });
    // }
  }

  @override
  Widget build(BuildContext context) {
    var mode = MediaQuery.of(context).platformBrightness;

    setState(() {
      _colorMode = mode;
      print(_colorMode);
    });

    return Scaffold(
      body: Container(
        child: SafeArea(
            child: Column(
          children: [
            Expanded(
              child: showData(),
            ),
          ],
        )),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('Time', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text("Nothing to see here");
        } else {
          return _buildList(context, snapshot.data!.docs);
        }
      },
    );
  }
}

Widget _buildListItem(
    BuildContext context, DocumentSnapshot data, String topElement) {
  final record = Message.fromSnapshot(data);

  return Padding(
    key: ValueKey(record.message),
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0), color: Color(0xFF221f2b)),
      child: ListTile(
        title: Text(
          record.message,
          style: new TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
        ),
        trailing: Text(
          record.battery.toString(),
          style: new TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold),
        ),
      ),
    ),
  );
}

Widget _buildList(
  BuildContext context,
  List<DocumentSnapshot> snapshot,
) {
  String topElement = snapshot.elementAt(0).data.toString();
  return ListView(
    children: snapshot
        .map((data) => _buildListItem(context, data, topElement))
        .toList(),
  );
}

class Message {
  final String message;
  final int battery;
  final String time;
  final DocumentReference reference;

  Message.fromMap(Map<String, dynamic> map, {required this.reference})
      : assert(map['Message'] != null),
        assert(map['battery'] != null),
        assert(map['Time'] != null),
        message = map['Message'],
        battery = map['battery'],
        time = map['Time'].toString();

  Message.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data()!, reference: snapshot.reference);

  @override
  String toString() => "Record<$message:$battery:$time>";
}
