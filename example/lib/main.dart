import 'package:flutter/material.dart';
import 'package:pdf_to_book/pdf_to_book.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: Scaffold(body: MyHomePage()),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final String url =
        "https://firebasestorage.googleapis.com/v0/b/gentry-publishing-app.appspot.com/o/books%2FAnna%20and%20Liz%3A%20The%20Lemonade%20Stand-1597771231928?alt=media&token=67b3baa2-76f6-4a5f-a5b2-bc9099ff4918";
    final String filename = "wildwoodbunch.pdf";

    return PdfBook(
      pdfUrl: url,
      filename: filename,
    );
  }
}
