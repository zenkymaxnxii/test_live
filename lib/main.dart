import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'broadcast_page.dart';

void main() => runApp(const MaterialApp(home: MyApp()));

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TextEditingController _controllerChannelName = TextEditingController();

  Future<void> onJoin({required bool isBroadCaster}) async {
    await [Permission.microphone, Permission.camera].request();
    // ignore: use_build_context_synchronously
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BroadCastPage(
            channelName: _controllerChannelName.text,
            isBroadCaster: isBroadCaster),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Agora Livestream"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ignore: prefer_const_constructors
              TextField(
                controller: _controllerChannelName,
                // ignore: prefer_const_constructors
                decoration: InputDecoration(
                  // ignore: prefer_const_constructors
                  border: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.blue)),
                  enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue)),
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue)),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              GestureDetector(
                onTap: () async {
                  await onJoin(isBroadCaster: false);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      "Just Watch",
                      style: TextStyle(color: Colors.blue, fontSize: 20),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Icon(
                      Icons.remove_red_eye_outlined,
                      color: Colors.blue,
                    )
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              GestureDetector(
                onTap: () async {
                  await onJoin(isBroadCaster: true);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      "Broadcast",
                      style: TextStyle(color: Colors.pink, fontSize: 20),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Icon(
                      Icons.video_collection_outlined,
                      color: Colors.pink,
                    )
                  ],
                ),
              )
            ]),
      ),
    );
  }
}
