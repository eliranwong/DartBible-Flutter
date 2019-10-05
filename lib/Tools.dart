import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:share/share.dart';
import 'config.dart';
import 'Bibles.dart';
import 'Helpers.dart';
import 'BibleSearchDelegate.dart';
import 'BibleParser.dart';
import 'HtmlWrapper.dart';

class Tool extends StatefulWidget {
  final Map _title;
  final String _module;
  final List _menuData;
  final List _toolData = [];
  final Config _config;
  final Bible _bible;
  final Icon _icon;
  final Map _interfaceDialog;

  Tool(this._title, this._module, this._menuData, this._config, this._bible, this._icon, this._interfaceDialog);

  @override
  ToolState createState() => ToolState(this._title, this._module, this._menuData, this._config, this._bible, this._icon, this._interfaceDialog);
}

class ToolState extends State<Tool> {
  final Map _title;
  final String _module;
  final List _menuData;
  List _toolData = [];
  List displayData = [];
  final Config _config;
  final Bible _bible;
  final Icon _icon;
  final Map _interfaceDialog;
  TextStyle _verseNoFont, _verseFont, _verseFontHebrew, _verseFontGreek;
  String abbreviations;

  final Map interface = {
    "ENG": ["Add to Home Screen"],
    "TC": ["加增到主頁"],
    "SC": ["加增到主页"],
  };

  ToolState(this._title, this._module, this._menuData, this._config, this._bible, this._icon, this._interfaceDialog) {
    this.abbreviations = _config.abbreviations;
    _setTextStyle();
  }

  void _setTextStyle() {
    _verseNoFont = _config.verseTextStyle["verseNoFont"];
    _verseFont = _config.verseTextStyle["verseFont"];
    _verseFontHebrew = _config.verseTextStyle["verseFontHebrew"];
    _verseFontGreek = _config.verseTextStyle["verseFontGreek"];
    //_activeVerseNoFont = _config.verseTextStyle["activeVerseNoFont"];
    //_activeVerseFont = _config.verseTextStyle["activeVerseFont"];
    //_activeVerseFontHebrew = _config.verseTextStyle["activeVerseFontHebrew"];
    //_activeVerseFontGreek = _config.verseTextStyle["activeVerseFontGreek"];
    //_interlinearStyle = _config.verseTextStyle["interlinearStyle"];
    //_interlinearStyleDim = _config.verseTextStyle["interlinearStyleDim"];
  }

  Widget _wrap(Widget widget, int flex) {
    return Expanded(
      flex: flex,
      child: widget,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _config.mainTheme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_title[_config.abbreviations]),
          actions: <Widget>[
            IconButton(
              tooltip: this.interface[this.abbreviations].first,
              icon: const Icon(Icons.add_to_home_screen),
              onPressed: () async {
                Navigator.pop(context, [displayData, "display"]);
              },
            ),
          ],
        ),
        body: OrientationBuilder(
          builder: (context, orientation) {
            List<Widget> layoutWidgets = _buildLayoutWidgets(context);
            return (orientation == Orientation.portrait)
                ? Column(children: layoutWidgets)
                : Row(children: layoutWidgets);
          },
        ),
      ),
    );
  }

  List<Widget> _buildLayoutWidgets(BuildContext context) {
    return <Widget>[
      _wrap(_buildMenuItems(context), 1),
      _buildDivider(),
      _wrap(_buildItems(context), 1),
      (displayData.isEmpty) ? Container() : _buildDivider(),
      (displayData.isEmpty) ? Container() : _wrap(_buildVerses(context), 1),
    ];
  }

  Widget _buildDivider() {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: _config.myColors["grey"])
      ),
    );
  }

  Widget _buildVerses(BuildContext context) {
    return Container(
      color: Colors.blueGrey[_config.backgroundColor],
      child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: displayData.length,
          itemBuilder: (context, i) {
            return _buildDisplayVerseRow(context, i);
          }),
    );
  }

  Widget _buildDisplayVerseRow(BuildContext context, int i) {
    var verseData = displayData[i];
    return ListTile(
      title: _buildVerseText(context, verseData),
      onTap: () {
        Navigator.pop(context, [verseData, "open"]);
      },
      onLongPress: () {
        _longPressedVerse(context, displayData[i]);
      },
    );
  }

  // This function gives RichText widget with search items highlighted.
  Widget _buildVerseText(BuildContext context, List verseData) {
    var verseDirection = TextDirection.ltr;
    var verseFont = _verseFont;
    //var activeVerseFont = _activeVerseFont;
    var versePrefix = "";
    var verseContent = "";
    var verseModule = verseData[2];

    if ((_config.hebrewBibles.contains(verseModule)) && (verseData[0][0] < 40)) {
      verseFont = _verseFontHebrew;
      //activeVerseFont = _activeVerseFontHebrew;
      verseDirection = TextDirection.rtl;
    } else if (_config.greekBibles.contains(verseModule)) {
      verseFont = _verseFontGreek;
      //activeVerseFont = _activeVerseFontGreek;
    }
    var verseText = verseData[1];
    var tempList = verseText.split("]");

    if (tempList.isNotEmpty) versePrefix = "${tempList[0]}]";
    if (tempList.length > 1) verseContent = tempList.sublist(1).join("]");

    List<TextSpan> textContent = [
      TextSpan(text: versePrefix, style: _verseNoFont)
    ];
    try {
      if (_config.interlinearBibles.contains(verseModule)) {
        List<TextSpan> interlinearSpan = InterlinearHelper(_config.verseTextStyle)
            .getInterlinearSpan(verseContent, verseData[0][0]);
        textContent = interlinearSpan
          ..insert(0, TextSpan(text: versePrefix, style: _verseNoFont));
      } else {
        textContent.add(TextSpan(text: verseContent, style: verseFont));
      }
    } catch (e) {
      textContent.add(TextSpan(text: verseContent, style: verseFont));
    }

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: textContent,
      ),
      textDirection: verseDirection,
    );
  }

  Future<void> _longPressedVerse(BuildContext context, List verseData) async {
    var copiedText = await Clipboard.getData('text/plain');
    switch (await showDialog<DialogAction>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: Text(_interfaceDialog[this.abbreviations][0]),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, DialogAction.share);
                },
                child: Text(_interfaceDialog[this.abbreviations][1]),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, DialogAction.copy);
                },
                child: Text(_interfaceDialog[this.abbreviations][2]),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, DialogAction.addCopy);
                },
                child: Text(_interfaceDialog[this.abbreviations][3]),
              ),
            ],
          );
        })) {
      case DialogAction.share:
        Share.share(verseData[1]);
        break;
      case DialogAction.copy:
        Clipboard.setData(ClipboardData(text: verseData[1]));
        break;
      case DialogAction.addCopy:
        var combinedText = copiedText.text;
        combinedText += "\n${verseData[1]}";
        Clipboard.setData(ClipboardData(text: combinedText));
        break;
      default:
    }
  }

  Widget _buildMenuItems(BuildContext context) {
    return ListView.builder(
        padding: const EdgeInsets.all(10.0),
        itemCount: _menuData.length,
        itemBuilder: (context, i) {
          return _buildMenuItemRow(context, i);
        });
  }

  Widget _buildMenuItemRow(BuildContext context, int i) {
    String itemData = _menuData[i];
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

    setState(() {
      _toolData = tools;
    });
  }

  Widget _buildItems(BuildContext context) {
    return ListView.builder(
        padding: const EdgeInsets.all(10.0),
        itemCount: _toolData.length,
        itemBuilder: (context, i) {
          return _buildItemRow(context, i);
        });
  }

  Widget _buildItemRow(BuildContext context, int i) {
    Map itemData = _toolData[i];
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
    setState(() {
      displayData = passages;
    });
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
