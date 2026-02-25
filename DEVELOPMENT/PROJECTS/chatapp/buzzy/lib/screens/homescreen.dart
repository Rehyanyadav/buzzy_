import 'package:buzzy/pages/ChatPage.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _controller;
  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 4, vsync: this, initialIndex: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: Text("Buzzy"),
        actions: [
          IconButton(icon: Icon(Icons.search), onPressed: () {}),
          PopupMenuButton<String>(
            onSelected: (value) {},
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(value: "new group", child: Text("new group")),
                PopupMenuItem(
                  value: "new broadcast",
                  child: Text("new broadcast"),
                ),
                PopupMenuItem(
                  value: "whatsappweb",
                  child: Text("whatsapp web"),
                ),
                PopupMenuItem(
                  value: "staared message",
                  child: Text("staared message"),
                ),
                PopupMenuItem(value: "seetings", child: Text("settings")),
              ];
            },
          ),
        ],
        bottom: TabBar(
          controller: _controller,
          indicatorColor: const Color.fromARGB(255, 0, 0, 0),
          tabs: [
            Tab(icon: Icon(Icons.camera_alt)),
            Tab(text: "Chats"),
            Tab(text: "Status"),
            Tab(text: "Calls"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _controller,
        children: [Text("camera"), Chatpage(), Text("status"), Text("calls")],
      ),
    );
  }
}
