// Copyright 2019 Eliran Wong. All rights reserved.

import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unique Bible App',
      home: UniqueBible(),
    );
  }
}

class UniqueBible extends StatefulWidget {
  @override
  UniqueBibleState createState() => UniqueBibleState();
}

class UniqueBibleState extends State<UniqueBible> {
  final List<dynamic>_fetchResults = [
    {
      "bNo": 0,
      "cNo": 0,
      "vNo": 0,
      "vText": "King James Version"
    },
    {
      "bNo": 1,
      "cNo": 1,
      "vNo": 1,
      "vText": "In the beginning God created the heaven and the earth."
    },
    {
      "bNo": 1,
      "cNo": 1,
      "vNo": 2,
      "vText": "And the earth was without form, and void; and darkness [was] upon the face of the deep. And the Spirit of God moved upon the face of the waters."
    },
    {
      "bNo": 1,
      "cNo": 1,
      "vNo": 3,
      "vText": "And God said, Let there be light: and there was light."
    },
    {
      "bNo": 1,
      "cNo": 1,
      "vNo": 4,
      "vText": "And God saw the light, that [it was] good: and God divided the light from the darkness."
    },
    {
      "bNo": 1,
      "cNo": 1,
      "vNo": 5,
      "vText": "And God called the light Day, and the darkness he called Night. And the evening and the morning were the first day."
    }
  ];
  final _bibleFont = const TextStyle(fontSize: 18.0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Unique Bible App'),
      ),
      body: _buildVerses(),
    );
  }

  Widget _buildVerses() {
    return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemBuilder: (context, i) {
          if (i < _fetchResults.length) return _buildRow(_fetchResults[i]["vText"]);
        });
  }

  Widget _buildRow(String verseText) {
    return ListTile(
      title: Text(
        verseText,
        style: _bibleFont,
      ),
    );
  }

}