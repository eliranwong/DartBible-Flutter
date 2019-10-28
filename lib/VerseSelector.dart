import 'package:flutter/material.dart';
//import 'dart:io';
import 'BibleParser.dart';
import 'BibleSettings.dart';
import 'Bibles.dart';
import 'config.dart';

class VerseSelector extends StatefulWidget {
  final Bible _bible;
  final List _bcvList;
  final Map _favouriteActionMap;
  final Config _config;
  final bool _version;

  VerseSelector(
      this._bible, this._bcvList, this._favouriteActionMap, this._config, [this._version = true]);

  @override
  VerseSelectorState createState() => VerseSelectorState(
      this._bible, this._bcvList, this._favouriteActionMap, this._config, this._version);
}

class VerseSelectorState extends State<VerseSelector> {
  List _interface;

  String abbreviations;
  Map interfaceBibleSettings = {
    "ENG": [
      "Select a Verse",
      "Interface",
      "Primary Bible",
      "Book",
      "Chapter",
      "Verse",
      "Font Size",
      "Version Abbreviations",
      "Favourite Action",
      "Instant Action",
      "Save",
      "Background Brightness",
      "English Aduio",
      "Chinese Aduio",
      "Speech Rate",
      "Normal",
      "Greek Speech",
      "Big Screen Mode",
      "Secondary Bible",
    ],
    "TC": [
      "選擇經文",
      "介面語言",
      "首選聖經",
      "書卷",
      "章",
      "節",
      "字體大小",
      "版本簡寫註解",
      "常用功能",
      "即時功能",
      "存檔",
      "背景顏色深淺",
      "英語發聲",
      "中文發聲",
      "發聲速度",
      "正常",
      "希臘語發聲",
      "大屏幕模式",
      "次選聖經",
    ],
    "SC": [
      "选择经文",
      "接口语言",
      "首选圣经",
      "书卷",
      "章",
      "节",
      "字体大小",
      "版本简写注解",
      "常用功能",
      "即时功能",
      "存档",
      "背景颜色深浅",
      "英语发声",
      "中文发声",
      "发声速度",
      "正常",
      "希腊语发声",
      "大屏幕模式",
      "次选圣经",
    ],
  };

  Bible _bible;

  BibleParser _parser;
  Map _abbreviations;
  List _bookList, _chapterList, _verseList;
  List<String> _compareBibleList;
  String _moduleValue,
      _moduleValue2,
      _bookValue,
      _chapterValue,
      _verseValue,
      _fontSizeValue,
      _interfaceValue,
      _colorDegreeValue,
      _ttsChineseValue,
      _ttsEnglishValue,
      _ttsGreekValue;

  List fontSizeList = [
    "7",
    "8",
    "9",
    "10",
    "11",
    "12",
    "13",
    "14",
    "15",
    "16",
    "17",
    "18",
    "19",
    "20",
    "21",
    "22",
    "23",
    "24",
    "25",
    "26",
    "27",
    "28",
    "29",
    "30",
    "31",
    "32",
    "33",
    "34",
    "35",
    "36",
    "37",
    "38",
    "39",
    "40"
  ];

  List colorDegree = [
    "0",
    "100",
    "200",
    "300",
    "400",
    "500",
    "600",
    "700",
    "800",
    "900"
  ];

  //bool _bigScreenValue;
  double _speechRateValue;

  Map interfaceMap = {"English": "ENG", "繁體中文": "TC", "简体中文": "SC"};

  Map _instantActionMap = {
    "ENG": ["Tips", "Interlinear"],
    "TC": ["提示", "原文逐字翻譯"],
    "SC": ["提示", "原文逐字翻译"],
  };
  Map _favouriteActionMap;
  List _instantActionList, _favouriteActionList;
  int _instantAction, _favouriteAction;
  Config _config;
  bool _version;

  VerseSelectorState(
      Bible bible, List bcvList, this._favouriteActionMap, this._config, this._version) {
    // The following line is used instead of "_compareBibleList = compareBibleList";
    // Reason: To avoid direct update of original config settings
    // This allows users to cancel the changes made by pressing the "back" button
    _compareBibleList = List<String>.from(_config.compareBibleList);

    //_bigScreenValue = _config.bigScreen;
    _fontSizeValue = _config.fontSize
        .toString()
        .substring(0, (_config.fontSize.toString().length - 2));
    this.abbreviations = _config.abbreviations;
    _interface = interfaceBibleSettings[this.abbreviations];
    var interfaceMapReverse = {"ENG": "English", "TC": "繁體中文", "SC": "简体中文"};
    _interfaceValue = interfaceMapReverse[this.abbreviations];
    _colorDegreeValue = _config.backgroundColor.toString();

    _parser = BibleParser(this.abbreviations);
    _abbreviations = _parser.standardAbbreviation;

    _bible = bible;
    _moduleValue = _bible.module;
    _moduleValue2 = _config.bible2;

    _bookValue = _abbreviations[bcvList[0].toString()];
    _chapterValue = bcvList[1].toString();
    _verseValue = bcvList[2].toString();

    _favouriteActionList = _favouriteActionMap[this.abbreviations].sublist(4);
    _favouriteActionList.insert(0, "---");
    _favouriteAction = _config.favouriteAction + 1;

    _instantActionList = _instantActionMap[this.abbreviations];
    _instantActionList.insert(0, "---");
    _instantAction = _config.instantAction + 1;

    _speechRateValue = _config.speechRate;
    _ttsChineseValue = _config.ttsChinese;
    _ttsEnglishValue = _config.ttsEnglish;
    _ttsGreekValue = _config.ttsGreek;

    updateSettingsValues();
  }

  Future onModuleChanged(String module) async {
    _bible = Bible(module, this.abbreviations);
    _moduleValue = _bible.module;
    await _bible.loadData();

    setState(() {
      updateSettingsValues();
    });
  }

  void updateSettingsValues() {
    _bookList = _bible.bookList;
    _bookList = _bookList.map((i) => _abbreviations[(i).toString()]).toList();
    if (!(_bookList.contains(_bookValue))) {
      _bookValue = _bookList[0];
      _chapterValue = "1";
      _verseValue = "1";
    }

    var bookNoString = getBookNo();

    _chapterList = _bible.getChapterList(int.parse(bookNoString));
    _chapterList = _chapterList.map((i) => (i).toString()).toList();
    if (!(_chapterList.contains(_chapterValue)))
      _chapterValue = _chapterList[0];

    _verseList = this
        ._bible
        .getVerseList(int.parse(bookNoString), int.parse(_chapterValue));
    _verseList = _verseList.map((i) => (i).toString()).toList();
    if (!(_verseList.contains(_verseValue))) _verseValue = _verseList[0];
  }

  void updateInterface(String newValue) {
    var bookIndex = _bookList.indexOf(_bookValue);

    _interfaceValue = newValue;
    this.abbreviations = this.interfaceMap[newValue];

    _interface = interfaceBibleSettings[this.abbreviations];
    _abbreviations = BibleParser(this.abbreviations).standardAbbreviation;
    _bookList = _bible.bookList;
    _bookList = _bookList.map((i) => _abbreviations[(i).toString()]).toList();
    _bookValue = _bookList[bookIndex];

    _favouriteActionList = _favouriteActionMap[this.abbreviations].sublist(3);
    _favouriteActionList.insert(0, "---");

    _instantActionList = _instantActionMap[this.abbreviations];
    _instantActionList.insert(0, "---");
  }

  String getBookNo() {
    if (_parser.bibleBookNo.keys.contains(_bookValue)) {
      return _parser.bibleBookNo[_bookValue];
    } else if (_parser.bibleBookNo.keys.contains("$_bookValue.")) {
      return _parser.bibleBookNo["$_bookValue."];
    }
    return null;
  }

  @override
  build(BuildContext context) {
    return Theme(
      data: ThemeData(
        canvasColor: (int.parse(_colorDegreeValue) >= 500)
            ? Colors.blueGrey[int.parse(_colorDegreeValue) - 200]
            : Colors.blueGrey[int.parse(_colorDegreeValue)],
        unselectedWidgetColor: (int.parse(_colorDegreeValue) >= 500)
            ? Colors.blue[300]
            : Colors.blue[700],
        accentColor: (int.parse(_colorDegreeValue) >= 500)
            ? Colors.blueAccent[100]
            : Colors.blueAccent[700],
        dividerColor: (int.parse(_colorDegreeValue) >= 500)
            ? Colors.grey[400]
            : Colors.grey[700],
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: (int.parse(_colorDegreeValue) >= 500)
              ? Colors.blueGrey[int.parse(_colorDegreeValue) - 200]
              : Colors.blue[600],
          title: Text(_interface[0]),
          actions: <Widget>[
            IconButton(
              tooltip: _interface[10],
              icon: const Icon(Icons.check),
              onPressed: () {
                Navigator.pop(
                    context,
                    BibleSettingsParser(
                      _moduleValue,
                      _moduleValue2,
                      getBookNo(),
                      _chapterValue,
                      _verseValue,
                      this.interfaceMap[_interfaceValue],
                      _fontSizeValue,
                      _compareBibleList,
                      _favouriteAction,
                      _instantAction,
                      _colorDegreeValue,
                      _ttsEnglishValue,
                      _ttsChineseValue,
                      _speechRateValue,
                      _ttsGreekValue,
                      //_bigScreenValue,
                    ));
              },
            ),
          ],
        ),
        body: _bibleSettings(context),
      ),
    );
  }

  Widget _bibleSettings(BuildContext context) {
    TextStyle style = (int.parse(_colorDegreeValue) >= 500)
        ? TextStyle(color: Colors.grey[300])
        : TextStyle(color: Colors.black);

    Color dropdownBackground = (int.parse(_colorDegreeValue) >= 500)
        ? Colors.blueGrey[int.parse(_colorDegreeValue) - 200]
        : Colors.blueGrey[int.parse(_colorDegreeValue)];
    Color dropdownBorder = (int.parse(_colorDegreeValue) >= 500)
        ? Colors.grey[400]
        : Colors.grey[700];
    Color dropdownDisabled = (int.parse(_colorDegreeValue) >= 500)
        ? Colors.blueAccent[100]
        : Colors.blueAccent[700];
    Color dropdownEnabled = (int.parse(_colorDegreeValue) >= 500)
        ? Colors.blueAccent[100]
        : Colors.blueAccent[700];

    Widget dropdownUnderline = Container(
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: dropdownBorder))),
    );

    List moduleList = Bibles(this.abbreviations).getALLBibleList();
    List<Widget> versionRowList = moduleList.map((i) => _buildVersionRow(context, i, dropdownBackground)).toList();

    List<Widget> options = <Widget>[
      ListTile(
        title: Text(_interface[3], style: style),
        trailing: DropdownButton<String>(
          style: style,
          underline: dropdownUnderline,
          iconDisabledColor: dropdownDisabled,
          iconEnabledColor: dropdownEnabled,
          value: _bookValue,
          onChanged: (String newValue) {
            if (_bookValue != newValue) {
              setState(() {
                _bookValue = newValue;
                _chapterList =
                    _bible.getChapterList(int.parse(getBookNo()));
                _chapterList =
                    _chapterList.map((i) => (i).toString()).toList();
                _chapterValue = "1";
                _verseList = _bible.getVerseList(
                    int.parse(getBookNo()), int.parse(_chapterValue));
                _verseList =
                    _verseList.map((i) => (i).toString()).toList();
                _verseValue = "1";
              });
            }
          },
          items: <String>[..._bookList]
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
      ListTile(
        title: Text(_interface[4], style: style),
        trailing: DropdownButton<String>(
          style: style,
          underline: dropdownUnderline,
          iconDisabledColor: dropdownDisabled,
          iconEnabledColor: dropdownEnabled,
          value: _chapterValue,
          onChanged: (String newValue) {
            if (_chapterValue != newValue) {
              setState(() {
                _chapterValue = newValue;
                _verseList = _bible.getVerseList(
                    int.parse(getBookNo()), int.parse(_chapterValue));
                _verseList =
                    _verseList.map((i) => (i).toString()).toList();
                _verseValue = "1";
              });
            }
          },
          items: <String>[..._chapterList]
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
      ListTile(
        title: Text(_interface[5], style: style),
        trailing: DropdownButton<String>(
          style: style,
          underline: dropdownUnderline,
          iconDisabledColor: dropdownDisabled,
          iconEnabledColor: dropdownEnabled,
          value: _verseValue,
          onChanged: (String newValue) {
            if (_verseValue != newValue) {
              setState(() {
                _verseValue = newValue;
              });
            }
          },
          items: <String>[..._verseList]
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    ];

    if (_version) {
      options.insert(
        0,
        ListTile(
          title: Text(_interface[2], style: style),
          trailing: DropdownButton<String>(
            style: style,
            underline: dropdownUnderline,
            iconDisabledColor: dropdownDisabled,
            iconEnabledColor: dropdownEnabled,
            value: _moduleValue,
            onChanged: (String newValue) {
              if (_moduleValue != newValue) {
                onModuleChanged(newValue);
              }
            },
            items: <String>[...moduleList]
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ),
      );
      options.insert(
        4,
        ExpansionTile(
          title: Text(_interface[7], style: style),
          backgroundColor: Theme.of(context).accentColor.withOpacity(0.025),
          children: versionRowList,
        ),
      );
    }

    return Container(
      color: Colors.blueGrey[int.parse(_colorDegreeValue)],
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: options,
        ),
      ),
    );
  }

  Widget _buildVersionRow(
      BuildContext context, String version, Color dropdownBackground) {
    return Container(
      color: dropdownBackground,
      child: ListTile(
        title: Text(
          "$version = ${_config.allBibleMap[version]}",
          style: TextStyle(
              color: (int.parse(_colorDegreeValue) >= 700)
                  ? Colors.blue[300]
                  : Colors.blue[700]),
        ),
      ),
      /*child: CheckboxListTile(
        title: Text(
          _config.allBibleMap[version],
          style: TextStyle(
              color: (int.parse(_colorDegreeValue) >= 700)
                  ? Colors.blue[300]
                  : Colors.blue[700]),
        ),
        subtitle: Text(
          version,
          style: TextStyle(
            color: (int.parse(_colorDegreeValue) >= 700)
                ? Colors.grey[400]
                : _config.myColors["grey"],
          ),
        ),
        value: (_compareBibleList.contains(version)),
        onChanged: (bool value) {
          setState(() {
            if (value) {
              _compareBibleList.add(version);
            } else {
              var versionIndex = _compareBibleList.indexOf(version);
              _compareBibleList.removeAt(versionIndex);
            }
          });
        },
      ),*/
    );
  }
}
