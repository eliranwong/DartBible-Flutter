import 'package:flutter/material.dart';
import 'dart:io';
import 'BibleParser.dart';
import 'Bibles.dart';
import 'config.dart';

class BibleSettings extends StatefulWidget {
  final Bible _bible;
  final List _bcvList;
  final Map _favouriteActionMap;
  final Config _config;

  BibleSettings(
      this._bible, this._bcvList, this._favouriteActionMap, this._config);

  @override
  BibleSettingsState createState() => BibleSettingsState(
      this._bible, this._bcvList, this._favouriteActionMap, this._config);
}

class BibleSettingsState extends State<BibleSettings> {
  List _interface;

  String abbreviations;
  Map interfaceBibleSettings = {
    "ENG": [
      "Settings",
      "Interface",
      "Primary Bible",
      "Book",
      "Chapter",
      "Verse",
      "Font Size",
      "Versions for Comparison",
      "Favourite Action",
      "Instant Action",
      "Save",
      "Background Brightness",
      "English Audio",
      "Chinese Audio",
      "Speech Rate",
      "Normal",
      "Greek Speech",
      "Big Screen Mode",
      "Secondary Bible",
      "Default Marvel Bible",
      "Instant Interlinear",
      "Show Heading Verse No.",
      "Open Marvel.Bible Externally",
    ],
    "TC": [
      "設定",
      "介面語言",
      "首選聖經",
      "書卷",
      "章",
      "節",
      "字體大小",
      "版本比較選項",
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
      "預設 Marvel.Bible",
      "即時原文逐字翻譯",
      "在標題前顯示節數",
      "使用外置瀏覽器開啟 Marvel.Bible",
    ],
    "SC": [
      "设定",
      "接口语言",
      "首选圣经",
      "书卷",
      "章",
      "节",
      "字体大小",
      "版本比较选项",
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
      "预设 Marvel.Bible",
      "即时原文逐字翻译",
      "在标题前显示节数",
      "使用外置浏览器开启 Marvel.Bible",
    ],
  };

  Bible _bible;

  BibleParser _parser;
  Map _abbreviations;
  List _bookList, _chapterList, _verseList;
  List<String> _compareBibleList;
  String _moduleValue,
      _moduleValue2,
      _marvelBible,
      _marvelCommentary,
      _iBible,
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

  bool _showHeadingVerseNoValue;
  bool _alwaysOpenMarvelBibleExternallyValue;
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

  BibleSettingsState(
      Bible bible, List bcvList, this._favouriteActionMap, this._config) {
    // The following line is used instead of "_compareBibleList = compareBibleList";
    // Reason: To avoid direct update of original config settings
    // This allows users to cancel the changes made by pressing the "back" button
    _compareBibleList = List<String>.from(_config.compareBibleList);

    _showHeadingVerseNoValue = _config.showHeadingVerseNo;
    _alwaysOpenMarvelBibleExternallyValue = _config.alwaysOpenMarvelBibleExternally;
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
    Map marvelBibles = {
      "MAB": "Annotated",
      "MIB": "Interlinear",
      "MOB": "Original",
      "MPB": "Parallel",
      "MTB": "Trilingual",
    };
    _marvelBible = marvelBibles[_config.marvelBible];
    _marvelCommentary = _config.marvelCommentary.substring(1);
    _iBible = _config.iBible;

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
                      _marvelBible,
                      _iBible,
                      _showHeadingVerseNoValue,
                      _alwaysOpenMarvelBibleExternallyValue,
                      _marvelCommentary,
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
    Map<String, String> marvelCommentaries = {
      "Barnes": "Notes on the Old and New Testaments (Barnes) [26 vol.]",
      "Benson": "Commentary on the Old and New Testaments (Benson) [5 vol.]",
      "BI": "Biblical Illustrator (Exell) [58 vol.]",
      "Brooks": "Complete Summary of the Bible (Brooks) [2 vol.]",
      "Calvin": "John Calvin's Commentaries (Calvin) [22 vol.]",
      "Clarke": "Commentary on the Bible (Clarke) [6 vol.]",
      "CBSC": "Cambridge Bible for Schools and Colleges (Cambridge) [57 vol.]",
      "CECNT": "Critical And Exegetical Commentary on the NT (Meyer) [20 vol.]",
      "CGrk": "Cambridge Greek Testament for Schools and Colleges (Cambridge) [21 vol.]",
      "CHP": "Church Pulpit Commentary (Nisbet) [12 vol.]",
      "CPBST": "College Press Bible Study Textbook Series (College) [59 vol.]",
      "EBC": "Expositor's Bible Commentary (Nicoll) [49 vol.]",
      "ECER": "Commentary for English Readers (Ellicott) [8 vol.]",
      "EGNT": "Expositor's Greek New Testament (Nicoll) [5 vol.]",
      "GCT": "Greek Testament Commentary (Alford) [4 vol.]",
      "Gill": "Exposition of the Entire Bible (Gill) [9 vol.]",
      "Henry": "Exposition of the Old and New Testaments (Henry) [6 vol.]",
      "HH": "Horæ Homileticæ (Simeon) [21 vol.]",
      "ICCNT": "International Critical Commentary, NT (1896-1929) [16 vol.]",
      "JFB": "Jamieson, Fausset, and Brown Commentary (JFB) [6 vol.]",
      "KD": "Commentary on the Old Testament (Keil & Delitzsch) [10 vol.]",
      "Lange": "Commentary on the Holy Scriptures: Critical, Doctrinal, and Homiletical (Lange) [25 vol.]",
      "MacL": "Expositions of Holy Scripture (MacLaren) [32 vol.]",
      "PHC": "Preacher's Complete Homiletical Commentary (Exell) [37 vol.]",
      "Pulpit": "Pulpit Commentary (Spence) [23 vol.]",
      "Rob": "Word Pictures in the New Testament (Robertson) [6 vol.]",
      "Spur": "Spurgeon's Expositions on the Bible (Spurgeon) [3 vol.]",
      "Vincent": "Word Studies in the New Testament (Vincent) [4 vol.]",
      "Wesley": "John Wesley's Notes on the Whole Bible (Wesley) [3 vol.]",
      "Whedon": "Commentary on the Old and New Testaments (Whedon) [14 vol.]",
    };
    List<String> commentaryAbb = marvelCommentaries.keys.toList()..sort();

    TextStyle style = (int.parse(_colorDegreeValue) >= 500)
        ? TextStyle(color: Colors.grey[300])
        : TextStyle(color: Colors.black);

    TextStyle subtitleStyle = TextStyle(color: (int.parse(_colorDegreeValue) >= 700) ? Colors.grey[400] : _config.myColors["grey"],);

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
    List<Widget> versionRowList = moduleList
        .map((i) => _buildVersionRow(context, i, dropdownBackground))
        .toList();

    return Container(
      color: Colors.blueGrey[int.parse(_colorDegreeValue)],
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: <Widget>[
            /*ListTile(
              title: Text(_interface[17], style: style),
              trailing: Switch(
                  value: _bigScreenValue,
                  onChanged: (!_config.plus)
                      ? null
                      : (bool value) {
                    setState(() {
                      _bigScreenValue = value;
                    });
                  }
                  ),
            ),*/
            ListTile(
              title: Text(_interface[1], style: style),
              trailing: DropdownButton<String>(
                style: style,
                underline: dropdownUnderline,
                iconDisabledColor: dropdownDisabled,
                iconEnabledColor: dropdownEnabled,
                value: _interfaceValue,
                onChanged: (String newValue) {
                  if (_interfaceValue != newValue) {
                    setState(() {
                      this.updateInterface(newValue);
                    });
                  }
                },
                items: <String>[...interfaceMap.keys.toList()]
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
            ListTile(
              title: Text(_interface[11], style: style),
              trailing: DropdownButton<String>(
                style: style,
                underline: dropdownUnderline,
                iconDisabledColor: dropdownDisabled,
                iconEnabledColor: dropdownEnabled,
                value: _colorDegreeValue,
                onChanged: (String newValue) {
                  if (_colorDegreeValue != newValue) {
                    setState(() {
                      _colorDegreeValue = newValue;
                    });
                  }
                },
                items: <String>[...colorDegree]
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
            ListTile(
              title: Text(_interface[6], style: style),
              trailing: DropdownButton<String>(
                style: style,
                underline: dropdownUnderline,
                iconDisabledColor: dropdownDisabled,
                iconEnabledColor: dropdownEnabled,
                value: _fontSizeValue,
                onChanged: (String newValue) {
                  if (_verseValue != newValue) {
                    setState(() {
                      _fontSizeValue = newValue;
                    });
                  }
                },
                items: <String>[...fontSizeList]
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
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
            ListTile(
              title: Text(_interface[18], style: style),
              trailing: DropdownButton<String>(
                style: style,
                underline: dropdownUnderline,
                iconDisabledColor: dropdownDisabled,
                iconEnabledColor: dropdownEnabled,
                value: _moduleValue2,
                onChanged: (String newValue) {
                  if (_moduleValue2 != newValue) {
                    setState(() {
                      _moduleValue2 = newValue;
                    });
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
            /*ListTile(
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
            ),*/
            ExpansionTile(
              title: Text(_interface[7], style: style),
              backgroundColor: Theme.of(context).accentColor.withOpacity(0.025),
              children: versionRowList,
            ),
            ListTile(
              title: Text(_interface[21], style: style),
              trailing: Switch(
                  value: _showHeadingVerseNoValue,
                  onChanged: (bool value) {
                    setState(() {
                      _showHeadingVerseNoValue = value;
                    });
                  }
              ),
            ),
            ListTile(
              title: Text(_interface[20], style: style),
              trailing: DropdownButton<String>(
                style: style,
                underline: dropdownUnderline,
                iconDisabledColor: dropdownDisabled,
                iconEnabledColor: dropdownEnabled,
                value: _iBible,
                onChanged: (String newValue) {
                  if (_iBible != newValue) {
                    setState(() {
                      _iBible = newValue;
                    });
                  }
                },
                items: _config.interlinearBibles
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
            ListTile(
              title: Text(_interface[9], style: style),
              trailing: DropdownButton<String>(
                style: style,
                underline: dropdownUnderline,
                iconDisabledColor: dropdownDisabled,
                iconEnabledColor: dropdownEnabled,
                value: _instantActionList[_instantAction],
                onChanged: (String newValue) {
                  if (_instantActionList[_instantAction] != newValue) {
                    setState(() {
                      _instantAction = _instantActionList.indexOf(newValue);
                    });
                  }
                },
                items: <String>[..._instantActionList]
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
            ListTile(
              title: Text(
                _interface[8],
                style: style,
              ),
              trailing: DropdownButton<String>(
                style: style,
                underline: dropdownUnderline,
                iconDisabledColor: dropdownDisabled,
                iconEnabledColor: dropdownEnabled,
                value: _favouriteActionList[_favouriteAction],
                onChanged: (String newValue) {
                  if (_favouriteActionList[_favouriteAction] != newValue) {
                    setState(() {
                      _favouriteAction = _favouriteActionList.indexOf(newValue);
                    });
                  }
                },
                items: <String>[..._favouriteActionList]
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
            ListTile(
              title: Text(
                _interface[14],
                style: style,
              ),
              trailing: IconButton(
                tooltip: _interface[15],
                icon: Icon(Icons.settings_backup_restore,
                    color: (int.parse(_colorDegreeValue) >= 500)
                        ? Colors.blueAccent[100]
                        : Colors.blueAccent[700]),
                onPressed: () {
                  setState(() {
                    _speechRateValue = (Platform.isAndroid) ? 1.0 : 0.5;
                  });
                },
              ),
            ),
            Slider(
              activeColor: (int.parse(_colorDegreeValue) >= 500)
                  ? Colors.blueAccent[100]
                  : Colors.blueAccent[700],
              min: 0.1,
              max: (Platform.isAndroid) ? 3.0 : 1.0,
              onChanged: (newValue) {
                setState(() {
                  _speechRateValue = num.parse(newValue.toStringAsFixed(1));
                });
              },
              value: _speechRateValue,
            ),
            ListTile(
              title: Text(_interface[12], style: style),
              trailing: DropdownButton<String>(
                style: style,
                underline: dropdownUnderline,
                iconDisabledColor: dropdownDisabled,
                iconEnabledColor: dropdownEnabled,
                value: _ttsEnglishValue,
                onChanged: (String newValue) {
                  if (_ttsEnglishValue != newValue) {
                    setState(() {
                      _ttsEnglishValue = newValue;
                    });
                  }
                },
                items: <String>["en-GB", "en-US"]
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
            ListTile(
              title: Text(_interface[13], style: style),
              trailing: DropdownButton<String>(
                style: style,
                underline: dropdownUnderline,
                iconDisabledColor: dropdownDisabled,
                iconEnabledColor: dropdownEnabled,
                value: _ttsChineseValue,
                onChanged: (String newValue) {
                  if (_ttsChineseValue != newValue) {
                    setState(() {
                      _ttsChineseValue = newValue;
                    });
                  }
                },
                items: <String>[
                  "zh-CN",
                  (Platform.isAndroid) ? "yue-HK" : "zh-HK"
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
            /*ListTile(
              title: Text(_interface[16], style: style),
              trailing: DropdownButton<String>(
                style: style,
                underline: dropdownUnderline,
                iconDisabledColor: dropdownDisabled,
                iconEnabledColor: dropdownEnabled,
                value: _ttsGreekValue,
                onChanged: (String newValue) {
                  if (_ttsGreekValue != newValue) {
                    setState(() {
                      _ttsGreekValue = newValue;
                    });
                  }
                },
                items: <String>["modern", "Erasmian"]
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),*/
            ListTile(
              title: Text(_interface[19], style: style),
              subtitle: Text("Marvel $_marvelBible Bible", style: subtitleStyle),
              trailing: DropdownButton<String>(
                style: style,
                underline: dropdownUnderline,
                iconDisabledColor: dropdownDisabled,
                iconEnabledColor: dropdownEnabled,
                value: _marvelBible,
                onChanged: (String newValue) {
                  if (_marvelBible != newValue) {
                    setState(() {
                      _marvelBible = newValue;
                    });
                  }
                },
                items: <String>["Annotated", "Interlinear", "Original", "Parallel", "Trilingual"]
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
            ListTile(
              title: Text(_interface[19], style: style),
              subtitle: Text(marvelCommentaries[_marvelCommentary], style: subtitleStyle),
              trailing: DropdownButton<String>(
                style: style,
                underline: dropdownUnderline,
                iconDisabledColor: dropdownDisabled,
                iconEnabledColor: dropdownEnabled,
                value: _marvelCommentary,
                onChanged: (String newValue) {
                  if (_marvelCommentary != newValue) {
                    setState(() {
                      _marvelCommentary = newValue;
                    });
                  }
                },
                items: commentaryAbb.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
            ListTile(
              title: Text(_interface[22], style: style),
              trailing: Switch(
                  value: _alwaysOpenMarvelBibleExternallyValue,
                  onChanged: (!_config.plus)
                      ? null
                      : (bool value) {
                    setState(() {
                      _alwaysOpenMarvelBibleExternallyValue = value;
                    });
                  }
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionRow(
      BuildContext context, String version, Color dropdownBackground) {
    return Container(
      color: dropdownBackground,
      child: CheckboxListTile(
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
      ),
    );
  }
}

class BibleSettingsParser {
  final String module,
      module2,
      _book,
      _chapter,
      _verse,
      abbreviations,
      _fontSize,
      _backgroundColor,
      ttsEnglish,
      ttsChinese,
      ttsGreek;
  final double speechRate;
  final List<String> _compareBibleList;
  final int _instantAction, _quickAction;
  int book, chapter, verse, instantAction, favouriteAction, backgroundColor;
  double fontSize;
  List<String> compareBibleList;
  String marvelBible, marvelCommentary;
  String iBible;
  bool showHeadingVerseNo;
  bool alwaysOpenMarvelBibleExternally;

  BibleSettingsParser(
      this.module,
      this.module2,
      this._book,
      this._chapter,
      this._verse,
      this.abbreviations,
      this._fontSize,
      this._compareBibleList,
      this._quickAction,
      this._instantAction,
      this._backgroundColor,
      this.ttsEnglish,
      this.ttsChinese,
      this.speechRate,
      this.ttsGreek,
      [this.marvelBible = "Annotated", this.iBible = "OHGBi", this.showHeadingVerseNo = false, this.alwaysOpenMarvelBibleExternally = false, this.marvelCommentary = "CBSC"]) {
    this.book = int.parse(_book);
    this.chapter = int.parse(_chapter);
    this.verse = int.parse(_verse);
    this.fontSize = double.parse(_fontSize);
    this.compareBibleList = _compareBibleList..sort();
    this.favouriteAction = _quickAction - 1;
    this.instantAction = _instantAction - 1;
    this.backgroundColor = int.parse(_backgroundColor);
    Map marvelBibles = {
      "Annotated": "MAB",
      "Interlinear": "MIB",
      "Original": "MOB",
      "Parallel": "MPB",
      "Trilingual": "MTB",
    };
    this.marvelBible = marvelBibles[this.marvelBible];
    this.marvelCommentary = "c${this.marvelCommentary}";
  }
}
