// ignore_for_file: deprecated_member_use

import 'package:buzzy/models/ChatModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Individualpage extends StatefulWidget {
  const Individualpage({super.key, required this.chatModel});
  final ChatModel chatModel;
  @override
  State<Individualpage> createState() => _IndividualpageState();
}

class _IndividualpageState extends State<Individualpage> {
  bool show = false;
  FocusNode focusNode = FocusNode();
  late final TextEditingController _controller = TextEditingController();
  @override
  void initState() {
    super.initState();

    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        setState(() {
          show = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.amber,
        leadingWidth: 70,
        titleSpacing: 0,
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_back, size: 24),
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blueGrey,
                child: SvgPicture.asset(
                  widget.chatModel.isGroup
                      ? "assets/group.svg"
                      : "assets/person.svg",
                  // ignore: deprecated_member_use
                  color: Colors.white,
                  height: 36,
                  width: 36,
                ),
              ),
            ],
          ),
        ),
        title: Container(
          margin: EdgeInsets.all(5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.chatModel.name,
                style: TextStyle(fontSize: 18.5, fontWeight: FontWeight.bold),
              ),
              Text("last seen today at 2:0", style: TextStyle(fontSize: 11)),
            ],
          ),
        ),
        actions: [
          IconButton(icon: Icon(Icons.videocam), onPressed: () {}),
          IconButton(onPressed: () {}, icon: Icon(Icons.call)),
          PopupMenuButton<String>(
            onSelected: (value) {},
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: "View contact ",
                  child: Text("View contact"),
                ),
                PopupMenuItem(
                  value: "Media,links and docs ",
                  child: Text("Media, links and docs"),
                ),
                PopupMenuItem(
                  value: "whatsappweb",
                  child: Text("whatsapp web"),
                ),
                PopupMenuItem(value: "search", child: Text("search")),
                PopupMenuItem(
                  value: "Mute notification",
                  child: Text("Mute notification"),
                ),
                PopupMenuItem(value: "wallaper", child: Text("wallpaper")),
              ];
            },
          ),
        ],
      ),

      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.height,
        child: WillPopScope(
          child: Stack(
            children: [
              ListView(),
              Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width - 55,

                          child: Card(
                            margin: EdgeInsets.only(
                              left: 10,
                              right: 1,
                              bottom: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: TextFormField(
                              controller: _controller,
                              focusNode: focusNode,
                              textAlignVertical: TextAlignVertical.center,
                              keyboardType: TextInputType.multiline,
                              maxLines: 5,
                              minLines: 1,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "type text ",
                                prefixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      focusNode.unfocus();
                                      focusNode.canRequestFocus = false;

                                      show = !show;
                                    });
                                  },
                                  icon: Icon(Icons.emoji_emotions),
                                ),

                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        showModalBottomSheet(
                                          context: context,
                                          builder: (builder) => bottomsheet(),
                                        );
                                      },
                                      icon: Icon(Icons.attach_file),
                                    ),
                                    IconButton(
                                      onPressed: () {},
                                      icon: Icon(Icons.camera_alt),
                                    ),
                                  ],
                                ),
                                contentPadding: EdgeInsets.all(5),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, right: 2),
                          child: CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.amber,
                            child: IconButton(
                              onPressed: () {},
                              icon: Icon(Icons.mic),
                            ),
                          ),
                        ),
                      ],
                    ),
                    show ? emojiSelect() : Container(),
                  ],
                ),
              ),
            ],
          ),
          onWillPop: () {
            if (show) {
              setState(() {
                show = false;
              });
            } else {
              Navigator.pop(context);
            }
            return Future.value(false);
          },
        ),
      ),
    );
  }

  // Widget emojiSelect() {
  //   return EmojiPicker(
  //     onEmojiSelected: (emoji, category) {
  //       print(emoji);
  //       setState(() {
  //         _controller.text = _controller.text + emoji.emoji;
  //       });
  //     },
  //   );
  // }

  Widget bottomsheet() {
    return Container();
  }

  Widget emojiSelect() {
    return EmojiPicker(
      onEmojiSelected: (category, emoji) {
        if (!mounted) return;

        setState(() {
          _controller.text += emoji.emoji;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        });
      },
    );
  }
}
