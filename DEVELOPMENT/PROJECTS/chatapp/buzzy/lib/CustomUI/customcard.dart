import 'package:buzzy/models/ChatModel.dart';
import 'package:buzzy/screens/individualPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CustomCard extends StatelessWidget {
  const CustomCard({required Key key, required this.chatModel})
    : super(key: key);
  final ChatModel chatModel;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Individualpage(chatModel: chatModel),
          ),
        );
      },
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blueGrey,
              child: SvgPicture.asset(
                chatModel.isGroup ? "assets/group.svg" : "assets/person.svg",
                // ignore: deprecated_member_use
                color: Colors.white,
                height: 37,
                width: 37,
              ),
            ),
            title: Text(
              chatModel.name,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Row(
              children: [
                Icon(Icons.done_all),

                SizedBox(width: 3),
                Text(chatModel.currentMessage, style: TextStyle(fontSize: 13)),
              ],
            ),
            trailing: Text(chatModel.time),
          ),

          Padding(
            padding: const EdgeInsets.only(right: 20, left: 80),
            child: Divider(thickness: 1),
          ),
        ],
      ),
    );
  }
}
