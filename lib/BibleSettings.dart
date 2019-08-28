import 'package:flutter/material.dart';
import 'BibleParser.dart';
import 'Bibles.dart';
import 'config.dart';

class BibleSettings extends StatefulWidget {
  final _bible;
  final _bcvList;
  final _fontSize;
  final _abbreviations;

  BibleSettings(this._bible, this._bcvList, this._fontSize, this._abbreviations);

  @override
  BibleSettingsState createState() => BibleSettingsState(_bible, _bcvList, _fontSize, _abbreviations);
}

class BibleSettingsState extends State<BibleSettings> {

  List _interface;

  String abbreviations;
  Bible _bible;

  BibleParser _parser;
  Map _abbreviations;
  List _bookList, _chapterList, _verseList;
  String _moduleValue, _bookValue, _chapterValue, _verseValue, _fontSizeValue, _interfaceValue;

  List fontSizeList = ["7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30"];
  Map interfaceMap = {"English": "ENG", "繁體中文": "TC", "简体中文": "SC"};

  BibleSettingsState(Bible bible, List bcvList, double fontSize, String abbreviations) {
    this._fontSizeValue = fontSize.toString().substring(0, (fontSize.toString().length - 2));
    this.abbreviations = abbreviations;
    this._interface = Config().interfaceBibleSettings[this.abbreviations];
    var interfaceMapReverse = {"ENG": "English", "TC": "繁體中文", "SC": "简体中文"};
    this._interfaceValue = interfaceMapReverse[this.abbreviations];

    this._parser = BibleParser(this.abbreviations);
    this._abbreviations = this._parser.standardAbbreviation;

    this._bible = bible;
    this._moduleValue = this._bible.module;

    this._bookValue = this._abbreviations[bcvList[0].toString()];
    this._chapterValue = bcvList[1].toString();
    this._verseValue = bcvList[2].toString();

    updateSettingsValues();
  }

  Future onModuleChanged(String module) async {
    this._bible = Bible(module, this.abbreviations);
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

  void updateInterface(String newValue) {
    var bookIndex = this._bookList.indexOf(this._bookValue);

    this._interfaceValue = newValue;
    this.abbreviations = this.interfaceMap[newValue];

    this._interface = Config().interfaceBibleSettings[this.abbreviations];
    this._abbreviations = BibleParser(this.abbreviations).standardAbbreviation;
    this._bookList = this._bible.bookList;
    this._bookList = this._bookList.map((i) => this._abbreviations[(i).toString()]).toList();
    this._bookValue = this._bookList[bookIndex];
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
        title: Text(this._interface[0]),

        actions: <Widget>[
          IconButton(
            tooltip: 'Go',
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, [this._moduleValue, this._bookValue, getBookNo(), this._chapterValue, this._verseValue, this._fontSizeValue, this.interfaceMap[this._interfaceValue]]);
            },
          ),
        ],
      ),
      body: _bibleSettings(context),
    );
  }

  Widget _bibleSettings(BuildContext context) {

    List moduleList = Bibles(this.abbreviations).getALLBibleList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ListView(
        children: <Widget>[
          ListTile(
            title: Text(this._interface[1]),
            trailing: DropdownButton<String>(
              value: this._interfaceValue,
              onChanged: (String newValue) {
                if (this._interfaceValue != newValue) {
                  setState(() {
                    this.updateInterface(newValue);
                  });
                }
              },
              items: <String>[...interfaceMap.keys.toList()].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          ListTile(
            title: Text(this._interface[2]),
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
            title: Text(this._interface[3]),
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
            title: Text(this._interface[4]),
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
            title: Text(this._interface[5]),
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
          ListTile(
            title: Text(this._interface[6]),
            trailing: DropdownButton<String>(
              value: this._fontSizeValue,
              onChanged: (String newValue) {
                if (this._verseValue != newValue) {
                  setState(() {
                    this._fontSizeValue = newValue;
                  });
                }
              },
              items: <String>[...fontSizeList].map<DropdownMenuItem<String>>((String value) {
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