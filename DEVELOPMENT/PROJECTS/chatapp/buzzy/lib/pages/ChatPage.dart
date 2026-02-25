import 'package:buzzy/CustomUI/customcard.dart';
import 'package:buzzy/models/ChatModel.dart';
import 'package:flutter/material.dart';

class Chatpage extends StatefulWidget {
  const Chatpage({super.key});

  @override
  State<Chatpage> createState() => _ChatpageState();
}

class _ChatpageState extends State<Chatpage> {
  List<ChatModel> chats = [
    ChatModel(
      name: "rehyan yadav",
      isGroup: false,
      currentMessage: "hi everyone",
      time: "4:08",
      icon: 'person.svg',
    ),
    ChatModel(
      name: "rehyan yadav",
      isGroup: true,
      currentMessage: "hi everyone",
      time: "4:08",
      icon: 'person.svg',
    ),
    ChatModel(
      name: "rehyan yadav",
      isGroup: false,
      currentMessage: "hi everyone",
      time: "4:08",
      icon: 'person.svg',
    ),
    ChatModel(
      name: "rehyan yadav",
      isGroup: true,
      currentMessage: "hi everyone",
      time: "4:08",
      icon: 'person.svg',
    ),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: Icon(Icons.chat),
      ),
      body: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) =>
            CustomCard(chatModel: chats[index], key: Key("")),
      ),
    );
  }
}
