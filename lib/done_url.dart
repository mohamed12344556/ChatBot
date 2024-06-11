import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class ChatPage2 extends StatefulWidget {
  static const routeName = '/chat';

  const ChatPage2({Key? key}) : super(key: key);

  @override
  State<ChatPage2> createState() => _ChatPage2State();
}

class _ChatPage2State extends State<ChatPage2> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _chatHistory = [];

  Future<void> questionFromUserWithUrl(String question, String url) async {
    final uri =
    Uri.parse("https://api-chat-with-docs.onrender.com/chaturl/?url=$url");

    Map<String, dynamic> request = {
      "question": question,
      "url": url,
    };

    print("Question: $question"); // طباعة السؤال
    print("URL: $url"); // طباعة الرابط
    print("Request data: ${jsonEncode(request)}"); // طباعة بيانات الطلب

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request),
      );

      if (response.statusCode == 200) {
        print("Question sent successfully");
        var responseData = jsonDecode(response.body);
        // تحويل الرد إلى UTF-8 قبل عرضه
        String decodedResponse =
        utf8.decode(responseData["response"].runes.toList());
        print("Response data: $decodedResponse"); // طباعة الرد بعد تحويله
        setState(() {
          _chatHistory.add({"message": question, "isSender": true});
          _chatHistory.add({"message": decodedResponse, "isSender": false});
        });
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      } else {
        print("Failed to send question: ${response.reasonPhrase}");
        print(
            "Response body: ${response.body}"); // طباعة جسم الرد لمزيد من التفاصيل
      }
    } catch (e) {
      print("Error sending question: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Chat",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height - 160,
            child: ListView.builder(
              itemCount: _chatHistory.length,
              shrinkWrap: false,
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return Container(
                  padding:
                  EdgeInsets.only(left: 14, right: 14, top: 10, bottom: 10),
                  child: Align(
                    alignment: (_chatHistory[index]["isSender"]
                        ? Alignment.topRight
                        : Alignment.topLeft),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        color: (_chatHistory[index]["isSender"]
                            ? const Color(0xFFF69170)
                            : Colors.white),
                      ),
                      padding: EdgeInsets.all(16),
                      child: Text(
                        _chatHistory[index]["message"] ?? '',
                        style: TextStyle(
                          fontSize: 15,
                          color: _chatHistory[index]["isSender"]
                              ? Colors.white
                              : Colors.black,
                        ),
                        textAlign: (_chatHistory[index]["isSender"]
                            ? TextAlign.left
                            : TextAlign.right),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              height: 60,
              width: double.infinity,
              color: Colors.white,
              child: Row(
                children: [
                  const SizedBox(width: 4.0),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(50.0)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: "Type a message",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(8.0),
                          ),
                          controller: _chatController,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  MaterialButton(
                    onPressed: () {
                      setState(() {
                        if (_chatController.text.isNotEmpty) {
                          String inputText = _chatController.text;
                          // البحث عن العلامة المحددة لفصل الرابط عن السؤال
                          String question = "";
                          String url = "";
                          final separatorIndex = inputText.indexOf("؟؟؟") != -1
                              ? inputText.indexOf("؟؟؟")
                              : inputText.indexOf("???");
                          if (separatorIndex != -1) {
                            url = inputText.substring(0, separatorIndex).trim();
                            question =
                                inputText.substring(separatorIndex + 3).trim();
                          } else {
                            // إذا لم يتم العثور على العلامة "؟؟؟" أو "???"، افترض أن النص كامل هو السؤال
                            question = inputText;
                          }
                          _chatHistory.add({
                            "message": inputText,
                            "isSender": true,
                          });
                          _chatController.clear();
                          questionFromUserWithUrl(
                              question, url); // إرسال السؤال والرابط إلى الخادم
                        }
                      });
                      _scrollController
                          .jumpTo(_scrollController.position.maxScrollExtent);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(80.0),
                    ),
                    padding: const EdgeInsets.all(0.0),
                    child: Ink(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFF69170),
                            Color(0xFF7D96E6),
                          ],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(50.0)),
                      ),
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 70.0,
                          minHeight: 36.0,
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.send, color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

/*
طريقة الادخال هي :

Link ؟؟؟ question or Link ??? question
*/
