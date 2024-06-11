import 'package:chat_allah_akbr/pdf.dart';
import 'package:chat_allah_akbr/url.dart';
import 'package:flutter/material.dart';

import 'chat_allah_akbr.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Navigation Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
      routes: {
        '/page1': (context) => ChatPage1(),
        //'/page2': (context) => ChatPage2(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الصفحة الرئيسية'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/page1');
              },
              child: Text('PDF'),
            ),
            ElevatedButton(
              onPressed: () async {
                String? url = await _getUrlFromUser(context);
                if (url != null && url.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage2(url: url),
                    ),
                  );
                }
              },
              child: Text('URL'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _getUrlFromUser(BuildContext context) async {
    TextEditingController urlController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter URL'),
          content: TextField(
            controller: urlController,
            decoration: InputDecoration(hintText: "Enter URL here"),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(urlController.text);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

