import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buzzy/features/chat/presentation/chat_bubble.dart';
import 'package:buzzy/features/chat/data/message_model.dart';

void main() {
  testWidgets('Chat List Stress Test - 1000 Bubbles', (
    WidgetTester tester,
  ) async {
    final messages = List.generate(
      1000,
      (index) => MessageModel(
        id: 'msg_$index',
        senderId: index % 2 == 0 ? 'me' : 'partner',
        receiverId: index % 2 == 0 ? 'partner' : 'me',
        content: 'Stress test message number $index',
        timestamp: DateTime.now().subtract(Duration(minutes: index)),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) => ChatBubble(
              message: messages[index],
              isMe: index % 2 == 0,
              allMessages: messages,
            ),
          ),
        ),
      ),
    );

    // Initial render
    expect(find.byType(ChatBubble), findsWidgets);

    // Scroll to the end
    await tester.drag(find.byType(ListView), const Offset(0, -5000));
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, -5000));
    await tester.pump();

    // Verify it didn't crash
    expect(find.byType(ChatBubble), findsWidgets);
  });
}
