import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; // إضافة حزمة spinkit

class ChatPage1 extends StatefulWidget {
  static const routeName = '/chat';

  const ChatPage1({super.key});

  @override
  State<ChatPage1> createState() => _ChatPage1State();
}

class _ChatPage1State extends State<ChatPage1> with TickerProviderStateMixin {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _chatHistory = [];
  bool _isProcessing = false; // متغير للتحكم في حالة المعالجة
  bool _isUploading = false; // متغير للتحكم في حالة رفع الملف

  File? pdf;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _showInstructionsDialog();
    });
  }

  Future<void> pickedFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      final file = result.files.first;

      setState(() {
        pdf = File(file.path!);
        _isUploading = true; // إظهار مؤشر التحميل عند بدء رفع الملف
      });
      uploadFile(pdf!);
    }
  }

  void openFile(PlatformFile file) {
    OpenFile.open(file.path);
  }

  Future<void> uploadFile(File file) async {
    var request = http.MultipartRequest(
        'POST', Uri.parse('https://api-chat-with-docs.onrender.com/upload/'));
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    try {
      final streamedResponse = await request.send();
      if (streamedResponse.statusCode == 200) {
        // File uploaded successfully
        print('File uploaded');
        setState(() {
          _isUploading = false; // إخفاء مؤشر التحميل عند انتهاء الرفع
        });
      } else {
        // Handle error
        print('Error uploading file: ${streamedResponse.reasonPhrase}');
        setState(() {
          _isUploading = false; // إخفاء مؤشر التحميل عند حدوث خطأ
        });
      }
    } catch (e) {
      // Handle error
      print('Error uploading file: $e');
      setState(() {
        _isUploading = false; // إخفاء مؤشر التحميل عند حدوث خطأ
      });
    }
  }

  Future<void> questionFromUser(String question) async {
    final uri = Uri.parse("https://api-chat-with-docs.onrender.com/chatpdf/");

    Map<String, dynamic> request = {
      "question": question,
    };

    print("Request data: ${jsonEncode(request)}"); // Print request data

    setState(() {
      _isProcessing = true; // إظهار المؤشر عند بدء الإرسال
    });

    try {
      final response = await http.post(uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(request));

      if (response.statusCode == 200) {
        print("Question sent successfully");
        var responseData = jsonDecode(response.body);
        // Convert response to UTF-8 before displaying
        String decodedResponse =
        utf8.decode(responseData["response"].runes.toList());
        print("Response data: $decodedResponse"); // Print decoded response
        setState(() {
          _chatHistory.add({"message": decodedResponse, "isSender": false});
          _isProcessing = false; // إخفاء المؤشر عند انتهاء المعالجة
        });
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      } else {
        print("Failed to send question: ${response.reasonPhrase}");
        print(
            "Response body: ${response.body}"); // Print response body for more details
        setState(() {
          _isProcessing = false; // إخفاء المؤشر عند حدوث خطأ
        });
      }
    } catch (e) {
      print("Error sending question: $e");
      setState(() {
        _isProcessing = false; // إخفاء المؤشر عند حدوث خطأ
      });
    }
  }

  void _showInstructionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Welcome to Chat"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Here's how to use this page:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text("1. To send a PDF file, tap the attachment button."),
              Text("2. To send a message, type your message and tap send."),
              SizedBox(height: 8),
              Text("Feel free to ask any questions!"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Got it"),
            ),
          ],
        );
      },
    );
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
              itemCount: _chatHistory.length + (_isProcessing ? 1 : 0),
              shrinkWrap: false,
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                if (_isProcessing && index == _chatHistory.length) {
                  return Container(
                    padding: EdgeInsets.only(left: 14, right: 14, top: 10, bottom: 10),
                    child: Align(
                      alignment: Alignment.topLeft,
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
                          color: Colors.white,
                        ),
                        padding: EdgeInsets.all(16),
                        child: TypingIndicator(),
                      ),
                    ),
                  );
                }
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
                            ? Color(0xFFF69170)
                            : Colors.white),
                      ),
                      padding: EdgeInsets.all(16),
                      child: Text(
                        _chatHistory[index]["message"] ?? '',
                        style: TextStyle(
                            fontSize: 15,
                            color: _chatHistory[index]["isSender"]
                                ? Colors.white
                                : Colors.black),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isUploading) // عرض المؤشر عند رفع الملف
            Container(
              color: Colors.black45,
              child: Center(
                child: SpinKitCircle(
                  color: Colors.white,
                  size: 50.0,
                ),
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
                  SizedBox(width: 4.0),
                  MaterialButton(
                    onPressed: () {
                      pickedFile();
                    },
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(80.0)),
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
                            minWidth: 70.0, minHeight: 36.0),
                        // min sizes for Material buttons
                        alignment: Alignment.center,
                        child: IconButton(
                          onPressed: () {
                            pickedFile();
                          },
                          icon: Icon(Icons.attach_file, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
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
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  MaterialButton(
                    onPressed: () {
                      setState(() {
                        if (_chatController.text.isNotEmpty) {
                          String question = _chatController.text;
                          _chatHistory.add({
                            "message": question,
                            "isSender": true,
                          });
                          _chatController.clear();
                          questionFromUser(
                              question); // Send the question to the server
                        }
                      });
                      _scrollController
                          .jumpTo(_scrollController.position.maxScrollExtent);
                    },
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(80.0)),
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
                            minWidth: 70.0, minHeight: 36.0),
                        // min sizes for Material buttons
                        alignment: Alignment.center,
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              if (_chatController.text.isNotEmpty) {
                                String question = _chatController.text;
                                _chatHistory.add({
                                  "message": question,
                                  "isSender": true,
                                });
                                _chatController.clear();
                                questionFromUser(
                                    question); // Send the question to the server
                              }
                            });
                            _scrollController.jumpTo(
                                _scrollController.position.maxScrollExtent);
                          },
                          icon: Icon(Icons.send, color: Colors.white),
                        ),
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

class TypingIndicator extends StatefulWidget {
  @override
  _TypingIndicatorState createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _dotController;
  late Animation<double> _dotAnimation;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _dotAnimation = CurvedAnimation(parent: _dotController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _dotAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: index == 0
                  ? _dotAnimation.value
                  : (index == 1
                  ? _dotAnimation.value * 0.5
                  : _dotAnimation.value * 0.25),
              child: child,
            );
          },
          child: DotWidget(),
        );
      }),
    );
  }
}

class DotWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: Container(
        width: 8.0,
        height: 8.0,
        decoration: BoxDecoration(
          color: Colors.grey,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
