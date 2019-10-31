import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:share/share.dart';
import 'BibleParser.dart';
import 'config.dart';
import 'Helpers.dart';
import 'Bibles.dart';
import 'HtmlWrapper.dart';
import 'BibleLocations.dart';

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
    "ENG": ["Open in Workspace"],
    "TC": ["在工作間顯示"],
    "SC": ["在工作间显示"],
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
            .getInterlinearSpan(verseModule, verseContent, verseData[0][0]);
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
    if (verseData.first.isNotEmpty) {
      String ref = BibleParser(this.abbreviations).bcvToVerseReference(verseData.first);
      var copiedText = await Clipboard.getData('text/plain');
      switch (await showDialog<DialogAction>(
          context: context,
          builder: (BuildContext context) {
            return SimpleDialog(
              title: Text(ref),
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.share),
                  title: Text(_interfaceDialog[this.abbreviations][1]),
                  onTap: () => Navigator.pop(context, DialogAction.share),
                ),
                ListTile(
                  leading: Icon(Icons.content_copy),
                  title: Text(_interfaceDialog[this.abbreviations][2]),
                  onTap: () => Navigator.pop(context, DialogAction.copy),
                ),
                ListTile(
                  leading: Icon(Icons.playlist_add),
                  title: Text(_interfaceDialog[this.abbreviations][3]),
                  onTap: () => Navigator.pop(context, DialogAction.addCopy),
                ),
                /*SimpleDialogOption(
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
              ),*/
              ],
            );
          })) {
        case DialogAction.share:
          Share.share("${verseData[1]} ($ref, ${verseData.last})");
          break;
        case DialogAction.copy:
          Clipboard.setData(ClipboardData(text: "${verseData[1]} ($ref, ${verseData.last})"));
          break;
        case DialogAction.addCopy:
          var combinedText = copiedText.text;
          combinedText += "\n${verseData[1]} ($ref, ${verseData.last})";
          Clipboard.setData(ClipboardData(text: combinedText));
          break;
        default:
      }
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

class TopicTablet extends StatefulWidget {

  final List _data;
  final Config _config;
  final Bibles _bibles;

  TopicTablet(this._data, this._config, this._bibles);

  @override
  TopicTabletState createState() => TopicTabletState(this._data, this._config, this._bibles);
}

class TopicTabletState extends State<TopicTablet> {

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List _data;
  final Config _config;
  final Bibles _bibles;
  String abbreviations;
  List _topicEntries = [];

  Map interface = {
    "ENG": ["Clear", "Search ", "Bible Topics"],
    "TC": ["清空", "搜索", "聖經主題"],
    "SC": ["清空", "搜索", "圣经主题"],
  };

  TopicTabletState(this._data, this._config, this._bibles) {
    this.abbreviations = _config.abbreviations;
  }

  Widget _buildSearchBox() {
    return Container(
      alignment: Alignment.centerLeft,
      color: Colors.white,
      child: TextField(
        decoration:
        InputDecoration(border: InputBorder.none, hintText: "${interface[this.abbreviations][1]}${interface[this.abbreviations].last}"),
        onSubmitted: (String value) {
          if (value.isNotEmpty) _fetch(value);
        },
        //onChanged: ,
        //onTap: ,
        //onEditingComplete: ,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _config.mainTheme,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: _buildSearchBox(),
          /*actions: <Widget>[
            IconButton(
              tooltip: "",
              icon: const Icon(Icons.add_to_home_screen),
              onPressed: () {
                //;
              },
            ),
          ],*/
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

  Widget _wrap(Widget widget, int flex) {
    return Expanded(
      flex: flex,
      child: widget,
    );
  }

  Widget _buildDivider() {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: _config.myColors["grey"])
      ),
    );
  }

  List<Widget> _buildLayoutWidgets(BuildContext context) {
    return <Widget>[
      _wrap(_buildItems(context), 1),
      _buildDivider(),
      _wrap(_buildCardList(context), 1),
    ];
  }

  Widget _buildItems(BuildContext context) {
    return Container(
      color: Colors.blueGrey[_config.backgroundColor],
      child: ListView.builder(
          padding: const EdgeInsets.all(10.0),
          itemCount: _data.length,
          itemBuilder: (context, i) {
            return _buildItemRow(i, context);
          }),
    );
  }

  Widget _buildItemRow(int i, BuildContext context) {
    var itemData = _data[i];

    return ListTile(
      leading: Icon(
        Icons.title,
        color: _config.myColors["black"],
      ),
      title:
      Text(itemData["Topic"], style: _config.verseTextStyle["verseFont"]),
      subtitle: Text(itemData["Tool"],
          style: TextStyle(
            fontSize: (_config.fontSize - 5),
            color: _config.myColors["grey"],
          )),
      trailing: IconButton(
        tooltip: this.interface[this.abbreviations][1],
        icon: Icon(
          Icons.search,
          color: _config.myColors["black"],
        ),
        onPressed: () {
          //close(context, [itemData["Entry"], "search"]);
          Navigator.pop(context, [itemData["Entry"], "search"]);
        },
      ),
      onTap: () {
        //close(context, [itemData["Entry"], "open"]);
        //Navigator.pop(context, [itemData["Entry"], "open"]);
        _loadTopicView(context, itemData["Entry"]);
      },
    );
  }

  Future _fetch(String searchItem) async {
    final Database db = await SqliteHelper(_config).initToolsDb();
    var statement = "SELECT Tool, Entry, Topic FROM EXLBT WHERE Topic LIKE ?";
    List<Map> tools = await db.rawQuery(statement, ['%$searchItem%']);
    db.close();
    setState(() {
      _data = distinctMapList(tools);
    });
  }

  List<Map> distinctMapList(List<Map> mapList) {
    List<String> entries = <String>[];
    List<Map> filteredMapList = <Map>[];
    for (var tool in mapList) {
      String entry = tool["Entry"];
      if (!(entries.contains(entry))) {
        entries.add(entry);
        filteredMapList.add(tool);
      }
    }
    return filteredMapList;
  }

  // functions - loading topic content

  Future _loadTopicView(BuildContext context, String entry) async {
    List entries = await SqliteHelper(_config).getTopic(entry);
    setState(() {
      _topicEntries = entries;
    });
  }

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

class LocationTablet extends StatefulWidget {

  final List _data;
  final List _data2;
  final Config _config;

  LocationTablet(this._data, this._data2, this._config);

  @override
  LocationTabletState createState() => LocationTabletState(this._data, this._data2, this._config);
}

class LocationTabletState extends State<LocationTablet> {

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Map interface = {
    "ENG": ["Clear", "Search ", "Bible Locations"],
    "TC": ["清空", "搜索", "聖經地點"],
    "SC": ["清空", "搜索", "圣经地点"],
  };

  List locations = BibleLocations().locations;

  List _data;
  final List _data2;
  final Config _config;
  String abbreviations;
  BibleParser _parser;

  LocationTabletState(this._data, this._data2, this._config) {
    this.abbreviations = _config.abbreviations;
    _parser = BibleParser(this.abbreviations);
  }

  Widget _buildSearchBox() {
    return Container(
      alignment: Alignment.centerLeft,
      color: Colors.white,
      child: TextField(
        decoration:
        InputDecoration(border: InputBorder.none, hintText: "${interface[this.abbreviations][1]}${interface[this.abbreviations].last}"),
        onSubmitted: (String value) {
          if (value.isNotEmpty) _fetch(value);
        },
        //onChanged: ,
        //onTap: ,
        //onEditingComplete: ,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _config.mainTheme,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: _buildSearchBox(),
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

  Widget _wrap(Widget widget, int flex) {
    return Expanded(
      flex: flex,
      child: widget,
    );
  }

  Widget _buildDivider() {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: _config.myColors["grey"])
      ),
    );
  }

  List<Widget> _buildLayoutWidgets(BuildContext context) {
    return <Widget>[
      _wrap(_buildItems(context), 1),
      _buildDivider(),
      _wrap(_buildItems2(context), 1),
    ];
  }

  void _fetch(String query) {
    setState(() {
      _data = locations.where((i) => i["Name"].contains(query)).toList();
    });
  }

  Widget _buildItems(BuildContext context) {
    return Container(
      color: Colors.blueGrey[_config.backgroundColor],
      child: ListView.builder(
          padding: const EdgeInsets.all(10.0),
          itemCount: _data.length,
          itemBuilder: (context, i) {
            return _buildItemRow(i, context);
          }),
    );
  }

  Widget _buildItemRow(int i, BuildContext context) {
    var itemData = _data[i];
    List bcvList = [itemData["Book"], itemData["Chapter"], itemData["Verse"]];
    String ref = _parser.bcvToVerseReference(bcvList);

    return ListTile(
      leading: Icon(
        Icons.pin_drop,
        color: _config.myColors["black"],
      ),
      title: Text(itemData["Name"], style: _config.verseTextStyle["verseFont"]),
      subtitle: (ref == "BOOK 0:0") ? null : Text(ref, style: TextStyle(color: _config.myColors["grey"])),
      trailing: IconButton(
        tooltip: this.interface[this.abbreviations][1],
        icon: Icon(
          Icons.search,
          color: _config.myColors["black"],
        ),
        onPressed: () {
          //close(context, [itemData["LocationID"]]);
          Navigator.pop(context, [itemData["LocationID"]]);
        },
      ),
      onTap: () {
        _launchMarvelEXLBL(itemData["LocationID"]);
      },
    );
  }

  Widget _buildItems2(BuildContext context) {
    return Container(
      color: Colors.blueGrey[_config.backgroundColor],
      child: ListView.builder(
          padding: const EdgeInsets.all(10.0),
          itemCount: _data2.length,
          itemBuilder: (context, i) {
            return _buildItemRow2(i, context);
          }),
    );
  }

  Widget _buildItemRow2(int i, BuildContext context) {
    var itemData = _data2[i];
    List bcvList = [itemData["Book"], itemData["Chapter"], itemData["Verse"]];
    String ref = _parser.bcvToVerseReference(bcvList);

    return ListTile(
      leading: Icon(
        Icons.pin_drop,
        color: _config.myColors["black"],
      ),
      title: Text(itemData["Name"], style: _config.verseTextStyle["verseFont"]),
      subtitle: (ref == "BOOK 0:0") ? null : Text(ref, style: TextStyle(color: _config.myColors["grey"])),
      trailing: IconButton(
        tooltip: this.interface[this.abbreviations][1],
        icon: Icon(
          Icons.search,
          color: _config.myColors["black"],
        ),
        onPressed: () {
          //close(context, [itemData["LocationID"]]);
          Navigator.pop(context, [itemData["LocationID"]]);
        },
      ),
      onTap: () {
        _launchMarvelEXLBL(itemData["LocationID"]);
      },
    );
  }

  Future _launchMarvelEXLBL(String locationID) async {
    String url = 'https://marvel.bible/tool.php?exlbl=$locationID';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

}

class PeopleTablet extends StatefulWidget {

  final List _data;
  final Config _config;

  PeopleTablet(this._data, this._config);

  @override
  PeopleTabletState createState() => PeopleTabletState(this._data, this._config);
}

class PeopleTabletState extends State<PeopleTablet> {

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List _data;
  List _data2 = [];
  final Config _config;
  String abbreviations;
  BibleParser _parser;

  Map interface = {
    "ENG": ["Clear", "Search ", "Bible People"],
    "TC": ["清空", "搜索", "聖經人物"],
    "SC": ["清空", "搜索", "圣经人物"],
  };

  PeopleTabletState(this._data, this._config) {
    this.abbreviations = _config.abbreviations;
    _parser = BibleParser(this.abbreviations);
  }

  Widget _buildSearchBox() {
    return Container(
      alignment: Alignment.centerLeft,
      color: Colors.white,
      child: TextField(
        decoration:
        InputDecoration(border: InputBorder.none, hintText: "${interface[this.abbreviations][1]}${interface[this.abbreviations].last}"),
        onSubmitted: (String value) {
          if (value.isNotEmpty) _fetch(value);
        },
        //onChanged: ,
        //onTap: ,
        //onEditingComplete: ,
      ),
    );
  }

  Future _fetch(String searchItem) async {
    final Database db = await SqliteHelper(_config).initToolsDb();
    var statement =
        "SELECT PersonID, Name, Sex FROM PEOPLERELATIONSHIP WHERE Name LIKE ? AND Relationship = '[Reference]'";
    List people = await db.rawQuery(statement, ['%$searchItem%']);
    db.close();
    setState(() {
      _data = people;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _config.mainTheme,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: _buildSearchBox(),
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

  Widget _wrap(Widget widget, int flex) {
    return Expanded(
      flex: flex,
      child: widget,
    );
  }

  Widget _buildDivider() {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: _config.myColors["grey"])
      ),
    );
  }

  List<Widget> _buildLayoutWidgets(BuildContext context) {
    return <Widget>[
      _wrap(_buildItems(context), 1),
      _buildDivider(),
      _wrap(_buildItems2(context), 1),
    ];
  }

  Widget _buildItems(BuildContext context) {
    return Container(
      color: Colors.blueGrey[_config.backgroundColor],
      child: ListView.builder(
          padding: const EdgeInsets.all(10.0),
          itemCount: _data.length,
          itemBuilder: (context, i) {
            return _buildItemRow(context, i);
          }),
    );
  }

  Widget _buildItemRow(BuildContext context, int i) {
    var itemData = _data[i];
    Icon icon = (itemData["Sex"] == "F")
        ? Icon(
      Icons.person_outline,
      color: _config.myColors["black"],
    )
        : Icon(
      Icons.person,
      color: _config.myColors["black"],
    );

    List bcvList = [itemData["Book"], itemData["Chapter"], itemData["Verse"]];
    String ref = _parser.bcvToVerseReference(bcvList);

    return ListTile(
      leading: icon,
      title: Text(itemData["Name"], style: _config.verseTextStyle["verseFont"]),
      subtitle: (ref == "BOOK 0:0") ? null : Text(ref, style: TextStyle(color: _config.myColors["grey"])),
      trailing: IconButton(
        tooltip: interface[this.abbreviations][1],
        icon: Icon(
          Icons.search,
          color: _config.myColors["black"],
        ),
        onPressed: () {
          //close(context, [1, itemData["PersonID"]]);
          Navigator.pop(context, itemData["PersonID"]);
        },
      ),
      onTap: () {
        //close(context, [0, itemData["PersonID"], itemData["Name"]]);
        _loadRelationship(itemData["PersonID"], itemData["Name"]);
      },
    );
  }

  Future _loadRelationship(int personID, String name) async {
    final Database db = await SqliteHelper(_config).initToolsDb();
    var statement = "SELECT PersonID, Name, Sex, Relationship FROM PEOPLERELATIONSHIP WHERE RelatedPersonID = ? ORDER BY RelationshipOrder";
    List<Map> tools = await db.rawQuery(statement, [personID]);
    db.close();
    setState(() {
      _data2 = tools;
    });
  }

  Widget _buildItems2(BuildContext context) {
    return ListView.builder(
        padding: const EdgeInsets.all(10.0),
        itemCount: _data2.length,
        itemBuilder: (context, i) {
          return _buildItemRow2(context, i);
        });
  }

  Widget _buildItemRow2(BuildContext context, int i) {
    Map itemData = _data2[i];
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
        "SELECT PersonID, Name, Sex, Relationship FROM PEOPLERELATIONSHIP WHERE RelatedPersonID = ? ORDER BY RelationshipOrder";
    List<Map> tools = await db.rawQuery(statement, [itemData["PersonID"]]);
    db.close();
    setState(() {
      //_title = itemData["Name"];
      _data2 = tools;
    });
  }

}