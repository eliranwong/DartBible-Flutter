import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:photo_view/photo_view.dart';
import 'config.dart';
import 'Bibles.dart';
import 'Helpers.dart';
import 'BibleSearchDelegate.dart';
import 'BibleParser.dart';
import 'HtmlWrapper.dart';

class NotePad extends StatefulWidget {
  final Config _config;
  final Bibles _bibles;
  final List _bcvList;
  final Database _noteDB;
  final String _content;

  NotePad(this._config, this._bibles, this._bcvList, this._noteDB, this._content);

  @override
  NotePadState createState() => NotePadState(this._config, this._bibles, this._bcvList, this._noteDB, this._content);
}


class NotePadState extends State<NotePad> {
  final Config _config;
  final Bibles _bibles;
  final List _bcvList;
  final Database _noteDB;
  String _content;
  bool _isNew;

  //final myController = TextEditingController();
  final Map interface = {
    "ENG": ["Note", "Type here ..."],
    "TC": ["筆記", "在這裡輸入文字 ..."],
    "SC": ["笔记", "在这里输入文字 ..."],
  };

  NotePadState(this._config, this._bibles, this._bcvList, this._noteDB, this._content) {
    _isNew = _content.isEmpty;
  }

  /*@override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    myController.dispose();
    super.dispose();
  }*/

  Future _saveNote(BuildContext context) async {
    //print(myController.text);
    if ((_content.isEmpty) && (!_isNew)) {
      _deleteNote(context);
    } else {
      if (_isNew) {
        // save new record
        await _noteDB.transaction((txn) async {
          int id1 = await txn.rawInsert(
              "INSERT INTO Notes(book, chapter, verse, content) VALUES(?, ?, ?, ?)", [..._bcvList, _content]
          );
          if (id1 != null) _isNew = !_isNew;
        });
      } else {
        // update current record
        await _noteDB.rawUpdate(
            "UPDATE Notes SET content = ? WHERE book = ? AND chapter = ? AND verse = ?",
            [_content, ..._bcvList]);
      }
    }
  }

  Future _deleteNote(BuildContext context) async {
    int count = await _noteDB.rawDelete("DELETE FROM Notes WHERE book = ? AND chapter = ? AND verse = ?", _bcvList);
    if (count == 1) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    List<Bible> bibleList = [_bibles.bible1, _bibles.bible2, _bibles.iBible];
    List<Widget> verseList = bibleList.map((bible) => _buildVerseRow(context, bible.openSingleVerse(_bcvList), bible.module)).toList();

    //myController.text = _content;

    return Theme(
      data: _config.mainTheme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(interface[_config.abbreviations].first),
          actions: <Widget>[
            IconButton(icon: Icon(Icons.save), onPressed: () => _saveNote(context)),
            IconButton(icon: Icon(Icons.delete_forever), onPressed: () => _deleteNote(context)),
          ],
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ExpansionTile(
                  title: Text(
                    BibleParser(_config.abbreviations).bcvToVerseReference(_bcvList),
                    style: TextStyle(
                      color: _config.myColors["black"],
                    ),
                  ),
                  initiallyExpanded: false,
                  backgroundColor: Theme.of(context).accentColor.withOpacity(0.025),
                  children: verseList,
                ),
                Row(
                  children: <Widget>[
                    SizedBox(width: 20),
                    Expanded(
                      child: TextFormField(
                        //controller: myController,
                        style: _config.verseTextStyle["verseFont"],
                        decoration: InputDecoration(
                          //border: OutlineInputBorder(),
                          hintText: interface[_config.abbreviations][1],
                          //labelText: "label",
                          //labelStyle: _config.verseTextStyle["verseFont"],
                          //helperText: "helper",
                          //helperStyle:  _config.verseTextStyle["verseFont"],
                        ),
                        initialValue: _content,
                        //readOnly: false,
                        scrollPadding: EdgeInsets.all(20.0),
                        keyboardType: TextInputType.multiline,
                        maxLines: 99999,
                        autofocus: true,
                        onChanged: (String content) {
                          _content = content;
                        },
                      ),
                    ),
                    SizedBox(width: 20),
                  ],
                )
              ],
            ),
          ),
        ),
        resizeToAvoidBottomInset: true,
      ),
    );
  }

  Widget _buildVerseRow(
      BuildContext context, String text, String module) {
    int book = _bcvList[0];
    TextDirection verseDirection = ((_config.hebrewBibles.contains(module)) && (_bcvList.first < 40)) ? TextDirection.rtl : TextDirection.ltr;
    TextStyle verseFont;
    if ((_config.hebrewBibles.contains(module)) && (_bcvList.first < 40)) {
      verseFont = _config.verseTextStyle["verseFontHebrew"];
    } else if (_config.greekBibles.contains(module)) {
      verseFont = _config.verseTextStyle["verseFontGreek"];
    } else {
      verseFont = _config.verseTextStyle["verseFont"];
    }
    List<TextSpan> wordSpans = (_config.interlinearBibles.contains(module))
        ? InterlinearHelper(_config.verseTextStyle)
        .getInterlinearSpan(text, book)
        : <TextSpan>[TextSpan(text: text, style: verseFont)];
    return ListTile(
      title: RichText(
        text: TextSpan(
          //style: DefaultTextStyle.of(context).style,
          children: wordSpans,
        ),
        textDirection: verseDirection,
      ),
      subtitle: Text(
        "[$module]",
        style: TextStyle(
          color: _config.myColors["blue"],
        ),
      ),
      onTap: () {
        Navigator.pop(context, [_bcvList, "", module]);
      },
    );
  }

}

class ToolMenu extends StatelessWidget {
  final Map _title;
  final String _module;
  final List _data;
  final Config _config;
  final Bible _bible;
  final Icon _icon;
  final Map _interfaceDialog;

  ToolMenu(this._title, this._module, this._data, this._config, this._bible,
      this._icon, this._interfaceDialog);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _config.mainTheme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_title[_config.abbreviations]),
        ),
        body: _buildItems(context),
      ),
    );
  }

  Widget _buildItems(BuildContext context) {
    return ListView.builder(
        padding: const EdgeInsets.all(10.0),
        itemCount: _data.length,
        itemBuilder: (context, i) {
          return _buildItemRow(context, i);
        });
  }

  Widget _buildItemRow(BuildContext context, int i) {
    String itemData = _data[i];
    return ListTile(
      leading: _icon,
      title: Text(itemData, style: _config.verseTextStyle["verseFont"]),
      onTap: () {
        _openTool(context, i);
      },
    );
  }

  Future _openTool(BuildContext context, int tool) async {
    final Database db = await SqliteHelper(_config).initToolsDb();
    var statement =
        "SELECT Topic, Passages FROM $_module WHERE Tool = ? ORDER BY Number";
    List<Map> tools = await db.rawQuery(statement, [tool]);
    db.close();

    final selected = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ToolView(_data[tool], tools, _config, _bible,
              _interfaceDialog, _icon)),
    );
    if (selected != null) Navigator.pop(context, selected);
  }
}

class ToolView extends StatelessWidget {
  final String _title;
  final List _data;
  final Config _config;
  final Bible _bible;
  final Map _interfaceDialog;
  final Icon _icon;

  ToolView(this._title, this._data, this._config, this._bible,
      this._interfaceDialog, this._icon);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _config.mainTheme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_title),
        ),
        body: _buildItems(context),
      ),
    );
  }

  Widget _buildItems(BuildContext context) {
    return ListView.builder(
        padding: const EdgeInsets.all(10.0),
        itemCount: _data.length,
        itemBuilder: (context, i) {
          return _buildItemRow(context, i);
        });
  }

  Widget _buildItemRow(BuildContext context, int i) {
    Map itemData = _data[i];
    String topic = itemData["Topic"].replaceAll("％", "\n");
    return ListTile(
      leading: _icon,
      title: Text(topic, style: _config.verseTextStyle["verseFont"]),
      onTap: () {
        _openPassages(context, itemData);
      },
    );
  }

  Future _openPassages(BuildContext context, Map itemData) async {
    String topic = itemData["Topic"].replaceAll("％", "\n");
    List bcvLists = BibleParser(_config.abbreviations)
        .extractAllReferences(itemData["Passages"]);
    List passages = _bible.openMultipleVerses(bcvLists, topic);
    final List selected = await showSearch(
        context: context,
        delegate: BibleSearchDelegate(
            context, _bible, _interfaceDialog, _config, passages));
    if (selected != null) Navigator.pop(context, selected);
  }
}

class Relationship extends StatefulWidget {
  final String _title;
  final List _data;
  final Config _config;
  final Bible _bible;
  final Map _interfaceDialog;
  final List _bcvList;

  Relationship(this._title, this._data, this._config, this._bible,
      this._interfaceDialog, this._bcvList);

  @override
  RelationshipState createState() => RelationshipState(this._title, this._data,
      this._config, this._bible, this._interfaceDialog, this._bcvList);
}

class RelationshipState extends State<Relationship> {
  String _title;
  List _data;
  final Config _config;
  final Bible _bible;
  final Map _interfaceDialog;
  final List _bcvList;
  final Map interface = {
    "ENG": ["Search"],
    "TC": ["搜索"],
    "SC": ["搜索"],
  };

  RelationshipState(this._title, this._data, this._config, this._bible,
      this._interfaceDialog, this._bcvList);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _config.mainTheme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_title),
        ),
        body: _buildItems(context),
      ),
    );
  }

  Widget _buildItems(BuildContext context) {
    return ListView.builder(
        padding: const EdgeInsets.all(10.0),
        itemCount: _data.length,
        itemBuilder: (context, i) {
          return _buildItemRow(context, i);
        });
  }

  Widget _buildItemRow(BuildContext context, int i) {
    Map itemData = _data[i];
    Icon icon = (itemData["Sex"] == "F")
        ? Icon(
            Icons.person_outline,
            color: _config.myColors["black"],
          )
        : Icon(
            Icons.person,
            color: _config.myColors["black"],
          );
    return ListTile(
      leading: icon,
      title: Text(itemData["Name"], style: _config.verseTextStyle["verseFont"]),
      subtitle: Text(itemData["Relationship"],
          style: TextStyle(
            fontSize: _config.fontSize - 4,
            color: _config.myColors["grey"],
          )),
      trailing: IconButton(
        tooltip: interface[_config.abbreviations][0],
        icon: Icon(
          Icons.search,
          color: _config.myColors["black"],
        ),
        onPressed: () {
          Navigator.pop(context, itemData["PersonID"]);
        },
      ),
      onTap: () {
        _updateRelationship(context, itemData);
      },
    );
  }

  Future _updateRelationship(BuildContext context, Map itemData) async {
    final Database db = await SqliteHelper(_config).initToolsDb();
    var statement =
        "SELECT PersonID, Name, Sex, Relationship FROM PEOPLERELATIONSHIP WHERE RelatedPersonID = ? AND Relationship != '[Reference]' ORDER BY RelationshipOrder";
    List<Map> tools = await db.rawQuery(statement, [itemData["PersonID"]]);
    db.close();
    setState(() {
      _title = itemData["Name"];
      _data = tools;
    });
  }

}

class Timeline extends StatefulWidget {
  final String _file;
  final String _title;
  final List _timelines;
  final Config _config;

  Timeline(this._file, this._title, this._timelines, this._config);

  @override
  TimelineState createState() =>
      TimelineState(this._file, this._title, this._timelines, this._config);
}

class TimelineState extends State<Timeline> {
  String _file;
  String _title;
  final Config _config;
  final List _timelines;
  final Map interface = {
    "ENG": ["Previous", "Next"],
    "TC": ["上一個", "下一個"],
    "SC": ["上一个", "下一个"],
  };

  TimelineState(this._file, this._title, this._timelines, this._config);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _config.mainTheme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_title),
          actions: <Widget>[
            IconButton(
              tooltip: "Previous",
              icon: const Icon(Icons.keyboard_arrow_left),
              onPressed: () {
                int newIndex = int.parse(_file) - 1;
                if (newIndex >= 0) {
                  setState(() {
                    _file = newIndex.toString();
                    _title = _timelines[newIndex][1];
                  });
                }
              },
            ),
            IconButton(
              tooltip: "Next",
              icon: const Icon(Icons.keyboard_arrow_right),
              onPressed: () {
                int newIndex = int.parse(_file) + 1;
                if (newIndex < _timelines.length) {
                  setState(() {
                    _file = newIndex.toString();
                    _title = _timelines[newIndex][1];
                  });
                }
              },
            ),
          ],
        ),
        body: Container(
            child: PhotoView(
          imageProvider: AssetImage("assets/timelines/$_file.png"),
          minScale: PhotoViewComputedScale.contained * 0.8,
        )),
      ),
    );
  }
}

/*
class TopicView extends StatefulWidget {
  final List _topicEntries;
  final Config _config;
  final Bibles _bibles;

  TopicView(this._config, this._topicEntries, this._bibles);

  @override
  TopicViewState createState() => TopicViewState(this._config, this._topicEntries, this._bibles);
}

class TopicViewState extends State<TopicView> {

  final List _topicEntries;
  final Config _config;
  final Bibles _bibles;

  Map interface = {
    "ENG": ["Bible Topic"],
    "TC": ["聖經主題"],
    "SC": ["聖經主題"],
  };

  TopicViewState(this._config, this._topicEntries, this._bibles);
*/

class TopicView extends StatelessWidget {
  final List _topicEntries;
  final Config _config;
  final Bibles _bibles;

  final Map interface = {
    "ENG": ["Bible Topic"],
    "TC": ["聖經主題"],
    "SC": ["聖經主題"],
  };

  TopicView(this._config, this._topicEntries, this._bibles);

  List<Widget> formatItem(BuildContext context, Map item) {
    HtmlWrapper _wrapper = HtmlWrapper(_bibles, _config);

    String _entry = item["Entry"];
    String _content = item["Content"];

    Widget headingRichText = Text(
      _entry,
      style: TextStyle(color: _config.myColors["grey"]),
    );
    Widget contentRichText = _wrapper.buildRichText(context, _content);

    return [headingRichText, contentRichText];
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _config.mainTheme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(interface[_config.abbreviations][0]),
        ),
        body: _buildCardList(context),
      ),
    );
  }

  Widget _buildCardList(BuildContext context) {
    return ListView.builder(
        padding: const EdgeInsets.all(10.0),
        itemCount: _topicEntries.length,
        itemBuilder: (context, i) {
          return _buildCard(context, i);
        });
  }

  Widget _buildCard(BuildContext context, int i) {
    final wordItem = _topicEntries[i];
    final wordData = formatItem(context, wordItem);
    return Center(
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              title: wordData[1],
              subtitle: wordData[0],
            )
          ],
        ),
      ),
    );
  }
}
