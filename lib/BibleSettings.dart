import 'package:flutter/material.dart';
import 'BibleParser.dart';
import 'Bibles.dart';

class BibleSettings extends StatefulWidget {
  final _bible;
  final _bcvList;

  BibleSettings(this._bible, this._bcvList);

  @override
  BibleSettingsState createState() => BibleSettingsState(_bible, _bcvList);
}

class BibleSettingsState extends State<BibleSettings> {

  Bible _bible;

  BibleParser _parser;
  Map _abbreviations;
  List _bookList, _chapterList, _verseList;
  String _moduleValue, _bookValue, _chapterValue, _verseValue;

  BibleSettingsState(Bible bible, List bcvList) {
    this._parser = BibleParser();
    this._abbreviations = this._parser.standardAbbreviation;

    this._bible = bible;
    this._moduleValue = this._bible.module;

    this._bookValue = this._abbreviations[bcvList[0].toString()];
    this._chapterValue = bcvList[1].toString();
    this._verseValue = bcvList[2].toString();

    updateSettingsValues();
  }

  Future onModuleChanged(String module) async {
    this._bible = Bible(module);
    this._moduleValue = this._bible.module;
    await this._bible.loadData();

    setState(() {
      updateSettingsValues();
    });
  }

  void updateSettingsValues() {
    this._bookList = this._bible.bookList;
    this._bookList = this._bookList.map((i) => this._abbreviations[(i).toString()]).toList();
    if (!(this._bookList.contains(this._bookValue))) {
      this._bookValue = this._bookList[0];
      this._chapterValue = "1";
      this._verseValue = "1";
    }

    var bookNoString = getBookNo();

    this._chapterList = this._bible.directGetChapterList(int.parse(bookNoString));
    this._chapterList = this._chapterList.map((i) => (i).toString()).toList();
    if (!(this._chapterList.contains(this._chapterValue))) this._chapterValue = this._chapterList[0];

    this._verseList = this._bible.directGetVerseList(int.parse(bookNoString), int.parse(this._chapterValue));
    this._verseList = this._verseList.map((i) => (i).toString()).toList();
    if (!(this._verseList.contains(this._verseValue))) this._verseValue = this._verseList[0];
  }

  String getBookNo() {
    if (this._parser.bibleBookNo.keys.contains(this._bookValue)) {
      return this._parser.bibleBookNo[this._bookValue];
    } else if (this._parser.bibleBookNo.keys.contains("${this._bookValue}.")) {
      return this._parser.bibleBookNo["${this._bookValue}."];
    }
    return null;
  }

  @override
  build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bible Settings'),

        actions: <Widget>[
          IconButton(
            tooltip: 'Go',
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, [this._moduleValue, this._bookValue, getBookNo(), this._chapterValue, this._verseValue]);
            },
          ),
        ],
      ),
      body: _bibleSettings(context),
    );
  }

  Widget _bibleSettings(BuildContext context) {

    List moduleList = Bibles().getALLBibleList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          ListTile(
            title: const Text('Bible'),
            trailing: DropdownButton<String>(
              value: this._moduleValue,
              onChanged: (String newValue) {
                if (this._moduleValue != newValue) {
                  onModuleChanged(newValue);
                }
              },
              items: <String>[...moduleList].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          ListTile(
            title: const Text('Book'),
            trailing: DropdownButton<String>(
              value: this._bookValue,
              onChanged: (String newValue) {
                if (this._bookValue != newValue) {
                  setState(() {
                    this._bookValue = newValue;
                    this._chapterValue = "1";
                    this._verseValue = "1";
                  });
                }
              },
              items: <String>[...this._bookList].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          ListTile(
            title: const Text('Chapter'),
            trailing: DropdownButton<String>(
              value: this._chapterValue,
              onChanged: (String newValue) {
                if (this._chapterValue != newValue) {
                  setState(() {
                    this._chapterValue = newValue;
                    this._verseValue = "1";
                  });
                }
              },
              items: <String>[...this._chapterList].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          ListTile(
            title: const Text('Verse'),
            trailing: DropdownButton<String>(
              value: this._verseValue,
              onChanged: (String newValue) {
                if (this._verseValue != newValue) {
                  setState(() {
                    this._verseValue = newValue;
                  });
                }
              },
              items: <String>[...this._verseList].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

}