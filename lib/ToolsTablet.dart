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

  List locations = [
    {"LocationID": "BL1", "Name": "Abana"},
    {"LocationID": "BL2", "Name": "Abarim"},
    {"LocationID": "BL3", "Name": "Abdon"},
    {"LocationID": "BL4", "Name": "Abel"},
    {"LocationID": "BL5", "Name": "Abel-Beth-Maachah"},
    {"LocationID": "BL7", "Name": "Abel-Maim"},
    {"LocationID": "BL8", "Name": "Abel-Meholah/Abelmeholah"},
    {"LocationID": "BL9", "Name": "Abel-Mizraim"},
    {"LocationID": "BL10", "Name": "Abel-Shittim"},
    {"LocationID": "BL12", "Name": "Abilene"},
    {"LocationID": "BL13", "Name": "Ebronah"},
    {"LocationID": "BL14", "Name": "Accad"},
    {"LocationID": "BL15", "Name": "Accho"},
    {"LocationID": "BL16", "Name": "Achaia"},
    {"LocationID": "BL17", "Name": "Achshaph"},
    {"LocationID": "BL18", "Name": "Achzib"},
    {"LocationID": "BL19", "Name": "Achzib"},
    {"LocationID": "BL20", "Name": "Adadah"},
    {"LocationID": "BL21", "Name": "Adam"},
    {"LocationID": "BL22", "Name": "Adamah"},
    {"LocationID": "BL23", "Name": "Adami/Nekeb"},
    {"LocationID": "BL24", "Name": "Adar"},
    {"LocationID": "BL25", "Name": "Addon"},
    {"LocationID": "BL26", "Name": "Adithaim"},
    {"LocationID": "BL27", "Name": "Admah"},
    {"LocationID": "BL28", "Name": "Adoraim"},
    {"LocationID": "BL29", "Name": "Adramyttium"},
    {"LocationID": "BL30", "Name": "Adria"},
    {"LocationID": "BL31", "Name": "Adullam"},
    {"LocationID": "BL32", "Name": "Adummim"},
    {"LocationID": "BL33", "Name": "Aenon"},
    {"LocationID": "BL34", "Name": "Ahava"},
    {"LocationID": "BL35", "Name": "Ahlab"},
    {"LocationID": "BL36", "Name": "Hai/Ai"},
    {"LocationID": "BL37", "Name": "Ai"},
    {"LocationID": "BL38", "Name": "Aiath"},
    {"LocationID": "BL39", "Name": "Aija"},
    {"LocationID": "BL40", "Name": "Ajalon/Aijalon"},
    {"LocationID": "BL41", "Name": "Ain"},
    {"LocationID": "BL42", "Name": "Ain"},
    {"LocationID": "BL43", "Name": "Aceldama"},
    {"LocationID": "BL44", "Name": "Akrabbim/Maaleh-Acrabbim"},
    {"LocationID": "BL45", "Name": "Alemeth"},
    {"LocationID": "BL46", "Name": "Alexandria"},
    {"LocationID": "BL47", "Name": "Alammelech"},
    {"LocationID": "BL48", "Name": "Allon-Bachuth"},
    {"LocationID": "BL49", "Name": "Almon"},
    {"LocationID": "BL50", "Name": "Almon-Diblathaim"},
    {"LocationID": "BL51", "Name": "Alush"},
    {"LocationID": "BL52", "Name": "Amad"},
    {"LocationID": "BL53", "Name": "Amalek"},
    {"LocationID": "BL54", "Name": "Amam"},
    {"LocationID": "BL55", "Name": "Amana"},
    {"LocationID": "BL57", "Name": "Ammah"},
    {"LocationID": "BL58", "Name": "Ammon"},
    {"LocationID": "BL59", "Name": "Amphipolis"},
    {"LocationID": "BL60", "Name": "Anab"},
    {"LocationID": "BL61", "Name": "Anaharath"},
    {"LocationID": "BL62", "Name": "Ananiah"},
    {"LocationID": "BL63", "Name": "Anathoth"},
    {"LocationID": "BL64", "Name": "Anem"},
    {"LocationID": "BL65", "Name": "Aner"},
    {"LocationID": "BL67", "Name": "Anim"},
    {"LocationID": "BL68", "Name": "Antioch"},
    {"LocationID": "BL69", "Name": "Antioch"},
    {"LocationID": "BL70", "Name": "Antipatris"},
    {"LocationID": "BL71", "Name": "Aphek"},
    {"LocationID": "BL72", "Name": "Aphek"},
    {"LocationID": "BL73", "Name": "Aphek"},
    {"LocationID": "BL74", "Name": "Aphekah"},
    {"LocationID": "BL75", "Name": "Aphik"},
    {"LocationID": "BL76", "Name": "Apollonia"},
    {"LocationID": "BL77", "Name": "Ar"},
    {"LocationID": "BL78", "Name": "Arab"},
    {"LocationID": "BL80", "Name": "Arabia"},
    {"LocationID": "BL81", "Name": "Arad"},
    {"LocationID": "BL82", "Name": "Aram/Syria"},
    {"LocationID": "BL83", "Name": "Syria-Maachah"},
    {"LocationID": "BL84", "Name": "Aramnaharaim"},
    {"LocationID": "BL85", "Name": "Aramzobah"},
    {"LocationID": "BL86", "Name": "Ararat"},
    {"LocationID": "BL87", "Name": "Areopagus/Mars Hill"},
    {"LocationID": "BL88", "Name": "Argob"},
    {"LocationID": "BL89", "Name": "Ariel"},
    {"LocationID": "BL90", "Name": "Arimathaea"},
    {"LocationID": "BL91", "Name": "Armageddon"},
    {"LocationID": "BL92", "Name": "Arnon"},
    {"LocationID": "BL93", "Name": "Aroer"},
    {"LocationID": "BL94", "Name": "Aroer"},
    {"LocationID": "BL95", "Name": "Aroer"},
    {"LocationID": "BL96", "Name": "Arpad/Arphad"},
    {"LocationID": "BL97", "Name": "Aruboth"},
    {"LocationID": "BL98", "Name": "Arumah"},
    {"LocationID": "BL99", "Name": "Arvad"},
    {"LocationID": "BL100", "Name": "Ashan"},
    {"LocationID": "BL101", "Name": "Ashdod"},
    {"LocationID": "BL102", "Name": "Ashdod"},
    {"LocationID": "BL103", "Name": "Askelon/Ashkelon"},
    {"LocationID": "BL105", "Name": "Ashnah"},
    {"LocationID": "BL106", "Name": "Astaroth/Ashtaroth"},
    {"LocationID": "BL107", "Name": "Karnaim"},
    {"LocationID": "BL108", "Name": "Asia/Achaia"},
    {"LocationID": "BL109", "Name": "Asshur/Assur"},
    {"LocationID": "BL110", "Name": "Assos"},
    {"LocationID": "BL111", "Name": "Asshur/Assyria/Assur"},
    {"LocationID": "BL112", "Name": "Atad"},
    {"LocationID": "BL113", "Name": "Ataroth"},
    {"LocationID": "BL114", "Name": "Ataroth"},
    {"LocationID": "BL115", "Name": "Ataroth-Addar"},
    {"LocationID": "BL116", "Name": "Athach"},
    {"LocationID": "BL117", "Name": "spies"},
    {"LocationID": "BL118", "Name": "Athens"},
    {"LocationID": "BL119", "Name": "Atroth/Shophan"},
    {"LocationID": "BL120", "Name": "Attalia"},
    {"LocationID": "BL121", "Name": "Aven"},
    {"LocationID": "BL122", "Name": "Avith"},
    {"LocationID": "BL123", "Name": "Ava"},
    {"LocationID": "BL124", "Name": "Avim"},
    {"LocationID": "BL125", "Name": "Gaza"},
    {"LocationID": "BL126", "Name": "Azal"},
    {"LocationID": "BL128", "Name": "Azekah"},
    {"LocationID": "BL129", "Name": "Azmaveth"},
    {"LocationID": "BL130", "Name": "Azmon"},
    {"LocationID": "BL131", "Name": "Aznoth-Tabor"},
    {"LocationID": "BL132", "Name": "Azotus"},
    {"LocationID": "BL133", "Name": "Baal"},
    {"LocationID": "BL134", "Name": "Baalah"},
    {"LocationID": "BL135", "Name": "Baalah"},
    {"LocationID": "BL136", "Name": "Baalath"},
    {"LocationID": "BL137", "Name": "Baalath"},
    {"LocationID": "BL138", "Name": "Baalath-Beer"},
    {"LocationID": "BL139", "Name": "Baale"},
    {"LocationID": "BL140", "Name": "Baal-Gad"},
    {"LocationID": "BL141", "Name": "Baal-Hamon"},
    {"LocationID": "BL142", "Name": "Baal-Hazor"},
    {"LocationID": "BL143", "Name": "Baal-Hermon"},
    {"LocationID": "BL144", "Name": "Baal-Meon"},
    {"LocationID": "BL146", "Name": "Baal-Perazim"},
    {"LocationID": "BL147", "Name": "Baal-Shalisha"},
    {"LocationID": "BL148", "Name": "Baal-Tamar"},
    {"LocationID": "BL149", "Name": "Baal-Zephon"},
    {"LocationID": "BL150", "Name": "Babel"},
    {"LocationID": "BL151", "Name": "Babylon/Sheshach"},
    {"LocationID": "BL152", "Name": "Babylon"},
    {"LocationID": "BL153", "Name": "Baharumite"},
    {"LocationID": "BL154", "Name": "Bahurim"},
    {"LocationID": "BL155", "Name": "Balah"},
    {"LocationID": "BL156", "Name": "Bamah"},
    {"LocationID": "BL157", "Name": "Bamoth"},
    {"LocationID": "BL158", "Name": "Bamoth-Baal"},
    {"LocationID": "BL159", "Name": "Bashan"},
    {"LocationID": "BL160", "Name": "Bath-Rabbim"},
    {"LocationID": "BL161", "Name": "Bealoth"},
    {"LocationID": "BL162", "Name": "Aloth"},
    {"LocationID": "BL164", "Name": "Beer"},
    {"LocationID": "BL165", "Name": "Beer"},
    {"LocationID": "BL166", "Name": "Beer-Elim"},
    {"LocationID": "BL167", "Name": "Lahai-Roi"},
    {"LocationID": "BL168", "Name": "Beeroth"},
    {"LocationID": "BL169", "Name": "Beeroth"},
    {"LocationID": "BL170", "Name": "Beer-Sheba"},
    {"LocationID": "BL171", "Name": "Beesh-Terah"},
    {"LocationID": "BL172", "Name": "Bela"},
    {"LocationID": "BL173", "Name": "Bene-Berak"},
    {"LocationID": "BL174", "Name": "Bene-Jaakan"},
    {"LocationID": "BL175", "Name": "Benjamin"},
    {"LocationID": "BL176", "Name": "Beon"},
    {"LocationID": "BL177", "Name": "Berea"},
    {"LocationID": "BL178", "Name": "Bered"},
    {"LocationID": "BL179", "Name": "Berothah"},
    {"LocationID": "BL180", "Name": "Berothai"},
    {"LocationID": "BL181", "Name": "Besor"},
    {"LocationID": "BL182", "Name": "Betah"},
    {"LocationID": "BL183", "Name": "Beten"},
    {"LocationID": "BL184", "Name": "Beth-Anath"},
    {"LocationID": "BL185", "Name": "Beth-Anoth"},
    {"LocationID": "BL186", "Name": "Bethany"},
    {"LocationID": "BL187", "Name": "Bethabara"},
    {"LocationID": "BL188", "Name": "Beth-Arabah"},
    {"LocationID": "BL189", "Name": "Beth-Arbel"},
    {"LocationID": "BL190", "Name": "Ashbea"},
    {"LocationID": "BL191", "Name": "Beth-Aven"},
    {"LocationID": "BL192", "Name": "Beth-Azmaveth"},
    {"LocationID": "BL193", "Name": "Beth-Baal-Meon"},
    {"LocationID": "BL194", "Name": "Beth-Barah"},
    {"LocationID": "BL195", "Name": "Beth-Birei"},
    {"LocationID": "BL196", "Name": "Beth-Car"},
    {"LocationID": "BL197", "Name": "Beth-Dagon"},
    {"LocationID": "BL198", "Name": "Beth-Dagon"},
    {"LocationID": "BL199", "Name": "Beth-Diblathaim"},
    {"LocationID": "BL200", "Name": "Eden"},
    {"LocationID": "BL202", "Name": "Beth-El"},
    {"LocationID": "BL203", "Name": "Beth-El"},
    {"LocationID": "BL204", "Name": "Beth-Emek"},
    {"LocationID": "BL205", "Name": "Bethesda"},
    {"LocationID": "BL206", "Name": "Beth-Ezel"},
    {"LocationID": "BL207", "Name": "Beth-Gamul"},
    {"LocationID": "BL208", "Name": "Gilgal"},
    {"LocationID": "BL209", "Name": "Beth-Haccerem"},
    {"LocationID": "BL211", "Name": "Beth-Aram"},
    {"LocationID": "BL212", "Name": "Beth-Haran"},
    {"LocationID": "BL213", "Name": "Beth-Hogla/Beth-Hoglah"},
    {"LocationID": "BL214", "Name": "Beth-Horon"},
    {"LocationID": "BL215", "Name": "Beth-Jesimoth/Beth-Jeshimoth"},
    {"LocationID": "BL216", "Name": "Aphrah"},
    {"LocationID": "BL217", "Name": "Beth-Lebaoth"},
    {"LocationID": "BL218", "Name": "Beth-Lehem/Bethlehem"},
    {"LocationID": "BL219", "Name": "Beth-Lehem"},
    {"LocationID": "BL220", "Name": "Ephratah"},
    {"LocationID": "BL221", "Name": "Beth-Maachah"},
    {"LocationID": "BL222", "Name": "Beth-Marcaboth"},
    {"LocationID": "BL223", "Name": "Beth-Meon"},
    {"LocationID": "BL224", "Name": "Millo"},
    {"LocationID": "BL225", "Name": "Beth-Nimrah"},
    {"LocationID": "BL226", "Name": "Beth-Pazzez"},
    {"LocationID": "BL227", "Name": "Beth-Palet/Beth-Phelet"},
    {"LocationID": "BL228", "Name": "Beth-Peor"},
    {"LocationID": "BL229", "Name": "Bethphage"},
    {"LocationID": "BL230", "Name": "Beth-Rehob"},
    {"LocationID": "BL231", "Name": "Bethsaida"},
    {"LocationID": "BL232", "Name": "Beth-Shan"},
    {"LocationID": "BL233", "Name": "Beth-Shean"},
    {"LocationID": "BL234", "Name": "Beth-Shemesh"},
    {"LocationID": "BL235", "Name": "Beth-Shemesh"},
    {"LocationID": "BL236", "Name": "Beth-Shemesh"},
    {"LocationID": "BL237", "Name": "Beth-Shittah"},
    {"LocationID": "BL238", "Name": "Beth-Tappuah"},
    {"LocationID": "BL239", "Name": "Togarmah"},
    {"LocationID": "BL240", "Name": "Bethuel"},
    {"LocationID": "BL241", "Name": "Bethul"},
    {"LocationID": "BL242", "Name": "Beth-Zur"},
    {"LocationID": "BL243", "Name": "Betonim"},
    {"LocationID": "BL245", "Name": "Bezek"},
    {"LocationID": "BL246", "Name": "Bezek"},
    {"LocationID": "BL247", "Name": "Bezer"},
    {"LocationID": "BL248", "Name": "Bileam"},
    {"LocationID": "BL249", "Name": "Bilhah"},
    {"LocationID": "BL250", "Name": "Bithynia"},
    {"LocationID": "BL251", "Name": "Bizjothjah"},
    {"LocationID": "BL252", "Name": "Bochim"},
    {"LocationID": "BL253", "Name": "Chorashan"},
    {"LocationID": "BL254", "Name": "Bozez"},
    {"LocationID": "BL255", "Name": "Bozkath/Boscath"},
    {"LocationID": "BL256", "Name": "Bozrah"},
    {"LocationID": "BL257", "Name": "Bozrah"},
    {"LocationID": "BL259", "Name": "Egypt/Nile"},
    {"LocationID": "BL262", "Name": "Buz"},
    {"LocationID": "BL263", "Name": "Cabbon"},
    {"LocationID": "BL264", "Name": "Cabul"},
    {"LocationID": "BL265", "Name": "Cabul"},
    {"LocationID": "BL266", "Name": "Caesarea"},
    {"LocationID": "BL267", "Name": "Caesarea-Philippi"},
    {"LocationID": "BL268", "Name": "Calah"},
    {"LocationID": "BL269", "Name": "Calneh"},
    {"LocationID": "BL270", "Name": "Calno"},
    {"LocationID": "BL271", "Name": "Cana"},
    {"LocationID": "BL272", "Name": "Canaan/Chanaan"},
    {"LocationID": "BL273", "Name": "Canneh"},
    {"LocationID": "BL274", "Name": "Capernaum"},
    {"LocationID": "BL275", "Name": "Caphtor"},
    {"LocationID": "BL276", "Name": "Cappadocia"},
    {"LocationID": "BL277", "Name": "Carchemish"},
    {"LocationID": "BL278", "Name": "Carmel"},
    {"LocationID": "BL279", "Name": "Casiphia"},
    {"LocationID": "BL280", "Name": "Clauda"},
    {"LocationID": "BL281", "Name": "Cenchrea"},
    {"LocationID": "BL282", "Name": "Chaldeans/Chaldea"},
    {"LocationID": "BL283", "Name": "Chebar"},
    {"LocationID": "BL285", "Name": "Chephirah"},
    {"LocationID": "BL286", "Name": "Cherith"},
    {"LocationID": "BL287", "Name": "Cherub"},
    {"LocationID": "BL288", "Name": "Chesalon"},
    {"LocationID": "BL289", "Name": "Chesil"},
    {"LocationID": "BL290", "Name": "Chesulloth"},
    {"LocationID": "BL291", "Name": "Chezib"},
    {"LocationID": "BL292", "Name": "Chilmad"},
    {"LocationID": "BL293", "Name": "Chinnereth"},
    {"LocationID": "BL294", "Name": "Chinnereth"},
    {"LocationID": "BL295", "Name": "Chinneroth/Cinneroth"},
    {"LocationID": "BL296", "Name": "Chios"},
    {"LocationID": "BL297", "Name": "Chisloth-Tabor"},
    {"LocationID": "BL298", "Name": "Kithlish"},
    {"LocationID": "BL299", "Name": "Chorazin"},
    {"LocationID": "BL300", "Name": "Cilicia"},
    {"LocationID": "BL301", "Name": "Destruction"},
    {"LocationID": "BL302", "Name": "Salt"},
    {"LocationID": "BL304", "Name": "Cnidus"},
    {"LocationID": "BL305", "Name": "Colosse"},
    {"LocationID": "BL306", "Name": "Corinth"},
    {"LocationID": "BL308", "Name": "Coos"},
    {"LocationID": "BL309", "Name": "Chozeba"},
    {"LocationID": "BL310", "Name": "Crete"},
    {"LocationID": "BL311", "Name": "Chun"},
    {"LocationID": "BL312", "Name": "Ethiopia/Cush"},
    {"LocationID": "BL313", "Name": "Cushan"},
    {"LocationID": "BL314", "Name": "Cuth"},
    {"LocationID": "BL315", "Name": "Cuthah"},
    {"LocationID": "BL316", "Name": "Chittim/Cyprus"},
    {"LocationID": "BL317", "Name": "Cyrene/Cyrenian"},
    {"LocationID": "BL318", "Name": "Dabbasheth"},
    {"LocationID": "BL319", "Name": "Daberath/Dabareh"},
    {"LocationID": "BL320", "Name": "Dalmanutha"},
    {"LocationID": "BL321", "Name": "Dalmatia"},
    {"LocationID": "BL322", "Name": "Damascus"},
    {"LocationID": "BL323", "Name": "Dan/Dan-Jaan"},
    {"LocationID": "BL324", "Name": "Dannah"},
    {"LocationID": "BL325", "Name": "Debir"},
    {"LocationID": "BL326", "Name": "Debir"},
    {"LocationID": "BL327", "Name": "Debir"},
    {"LocationID": "BL328", "Name": "Decapolis"},
    {"LocationID": "BL329", "Name": "Dedan"},
    {"LocationID": "BL330", "Name": "Derbe"},
    {"LocationID": "BL331", "Name": "Dibon/Dimon"},
    {"LocationID": "BL332", "Name": "Dibon"},
    {"LocationID": "BL333", "Name": "Dibon-Gad"},
    {"LocationID": "BL334", "Name": "Dilean"},
    {"LocationID": "BL335", "Name": "Dimnah"},
    {"LocationID": "BL336", "Name": "Dimonah"},
    {"LocationID": "BL337", "Name": "Dinhabah"},
    {"LocationID": "BL338", "Name": "Meonenim"},
    {"LocationID": "BL339", "Name": "Dizahab"},
    {"LocationID": "BL340", "Name": "Dophkah"},
    {"LocationID": "BL341", "Name": "Dor"},
    {"LocationID": "BL342", "Name": "Dothan"},
    {"LocationID": "BL344", "Name": "Dumah"},
    {"LocationID": "BL345", "Name": "Dumah"},
    {"LocationID": "BL347", "Name": "Dura"},
    {"LocationID": "BL350", "Name": "Eben-Ezer"},
    {"LocationID": "BL351", "Name": "Abez"},
    {"LocationID": "BL352", "Name": "Hebron"},
    {"LocationID": "BL353", "Name": "Achmetha"},
    {"LocationID": "BL354", "Name": "Eden"},
    {"LocationID": "BL355", "Name": "Edar"},
    {"LocationID": "BL356", "Name": "Eder"},
    {"LocationID": "BL357", "Name": "Edom/Syria/Idumea"},
    {"LocationID": "BL358", "Name": "Edrei"},
    {"LocationID": "BL359", "Name": "Eglaim"},
    {"LocationID": "BL361", "Name": "Eglon"},
    {"LocationID": "BL362", "Name": "Egypt/Egyptians/Egyptian"},
    {"LocationID": "BL364", "Name": "Ekron"},
    {"LocationID": "BL365", "Name": "Elam"},
    {"LocationID": "BL366", "Name": "Elath"},
    {"LocationID": "BL367", "Name": "El-Beth-El"},
    {"LocationID": "BL368", "Name": "Elealeh"},
    {"LocationID": "BL369", "Name": "Elim"},
    {"LocationID": "BL370", "Name": "Elishah"},
    {"LocationID": "BL371", "Name": "Elkoshite"},
    {"LocationID": "BL372", "Name": "Ellasar"},
    {"LocationID": "BL373", "Name": "Elon"},
    {"LocationID": "BL374", "Name": "Elon-Beth-Hanan"},
    {"LocationID": "BL375", "Name": "Eloth"},
    {"LocationID": "BL376", "Name": "El-Paran"},
    {"LocationID": "BL377", "Name": "Eltekeh"},
    {"LocationID": "BL378", "Name": "Eltekeh"},
    {"LocationID": "BL379", "Name": "Eltekon"},
    {"LocationID": "BL380", "Name": "Eltolad"},
    {"LocationID": "BL381", "Name": "Eden"},
    {"LocationID": "BL382", "Name": "Emmaus"},
    {"LocationID": "BL384", "Name": "Enam"},
    {"LocationID": "BL385", "Name": "En-Dor"},
    {"LocationID": "BL386", "Name": "En-Eglaim"},
    {"LocationID": "BL387", "Name": "En-Gannim"},
    {"LocationID": "BL388", "Name": "En-Gannim"},
    {"LocationID": "BL389", "Name": "En-Gedi"},
    {"LocationID": "BL390", "Name": "En-Haddah"},
    {"LocationID": "BL391", "Name": "En-Hakkore"},
    {"LocationID": "BL392", "Name": "En-Hazor"},
    {"LocationID": "BL393", "Name": "En-Mishpat"},
    {"LocationID": "BL394", "Name": "En-Rimmon"},
    {"LocationID": "BL395", "Name": "En-Rogel"},
    {"LocationID": "BL396", "Name": "En-Shemesh"},
    {"LocationID": "BL397", "Name": "En-Tappuah"},
    {"LocationID": "BL398", "Name": "Ephah"},
    {"LocationID": "BL399", "Name": "Ephes-Dammim"},
    {"LocationID": "BL400", "Name": "Ephesus"},
    {"LocationID": "BL401", "Name": "Ephraim"},
    {"LocationID": "BL402", "Name": "Ephraim"},
    {"LocationID": "BL403", "Name": "Ephrath"},
    {"LocationID": "BL404", "Name": "Ephratah"},
    {"LocationID": "BL406", "Name": "Ephrain"},
    {"LocationID": "BL407", "Name": "Erech"},
    {"LocationID": "BL408", "Name": "Esau"},
    {"LocationID": "BL409", "Name": "Esek"},
    {"LocationID": "BL410", "Name": "Eshean"},
    {"LocationID": "BL411", "Name": "Eshtaol"},
    {"LocationID": "BL412", "Name": "Eshtemoa"},
    {"LocationID": "BL413", "Name": "Eshtemoh"},
    {"LocationID": "BL414", "Name": "Etam"},
    {"LocationID": "BL415", "Name": "Etam"},
    {"LocationID": "BL416", "Name": "Etam"},
    {"LocationID": "BL417", "Name": "Etham"},
    {"LocationID": "BL418", "Name": "Ether"},
    {"LocationID": "BL419", "Name": "Ethiopia"},
    {"LocationID": "BL420", "Name": "Ittah-Kazin"},
    {"LocationID": "BL421", "Name": "Euphrates River"},
    {"LocationID": "BL422", "Name": "Azem/Ezem"},
    {"LocationID": "BL423", "Name": "Ezion-Gaber/Ezion-Geber"},
    {"LocationID": "BL424", "Name": "Havens"},
    {"LocationID": "BL427", "Name": "Appii"},
    {"LocationID": "BL429", "Name": "Gaash"},
    {"LocationID": "BL430", "Name": "Gabbatha"},
    {"LocationID": "BL431", "Name": "Galatia"},
    {"LocationID": "BL432", "Name": "Galeed"},
    {"LocationID": "BL433", "Name": "Gilgal/Galilee"},
    {"LocationID": "BL434", "Name": "Gallim"},
    {"LocationID": "BL435", "Name": "Gammadims"},
    {"LocationID": "BL436", "Name": "Gareb"},
    {"LocationID": "BL438", "Name": "Ephraim"},
    {"LocationID": "BL442", "Name": "Gath"},
    {"LocationID": "BL443", "Name": "Gittah-Hepher/Gath-Hepher"},
    {"LocationID": "BL444", "Name": "Gath-Rimmon"},
    {"LocationID": "BL445", "Name": "Gath-Rimmon"},
    {"LocationID": "BL446", "Name": "Gaza/Azzah"},
    {"LocationID": "BL447", "Name": "Gaba/Geba"},
    {"LocationID": "BL448", "Name": "Geba"},
    {"LocationID": "BL450", "Name": "Gebim"},
    {"LocationID": "BL451", "Name": "Geder"},
    {"LocationID": "BL452", "Name": "Gederah"},
    {"LocationID": "BL453", "Name": "Gederoth"},
    {"LocationID": "BL454", "Name": "Gederothaim"},
    {"LocationID": "BL455", "Name": "Gedor"},
    {"LocationID": "BL456", "Name": "Gedor"},
    {"LocationID": "BL457", "Name": "Geliloth"},
    {"LocationID": "BL458", "Name": "Gennesaret"},
    {"LocationID": "BL459", "Name": "Gerar"},
    {"LocationID": "BL460", "Name": "Chimham"},
    {"LocationID": "BL461", "Name": "Geshur"},
    {"LocationID": "BL462", "Name": "Gethsemane"},
    {"LocationID": "BL463", "Name": "Gezer/Gazer"},
    {"LocationID": "BL464", "Name": "Giah"},
    {"LocationID": "BL465", "Name": "Gibbethon"},
    {"LocationID": "BL466", "Name": "Gibeath/Gibeah"},
    {"LocationID": "BL467", "Name": "Gibeah"},
    {"LocationID": "BL470", "Name": "Gibeon"},
    {"LocationID": "BL471", "Name": "Gidom"},
    {"LocationID": "BL473", "Name": "Gihon"},
    {"LocationID": "BL474", "Name": "Gilboa"},
    {"LocationID": "BL475", "Name": "Gilead"},
    {"LocationID": "BL476", "Name": "Gilgal"},
    {"LocationID": "BL477", "Name": "Gilgal"},
    {"LocationID": "BL479", "Name": "Giloh"},
    {"LocationID": "BL480", "Name": "Gimzo"},
    {"LocationID": "BL481", "Name": "Gittaim"},
    {"LocationID": "BL482", "Name": "Goath"},
    {"LocationID": "BL483", "Name": "Gob"},
    {"LocationID": "BL484", "Name": "Gog"},
    {"LocationID": "BL486", "Name": "Golan"},
    {"LocationID": "BL487", "Name": "Golgotha"},
    {"LocationID": "BL488", "Name": "Gomer"},
    {"LocationID": "BL489", "Name": "Gomorrah/Gomorrha"},
    {"LocationID": "BL490", "Name": "Goshen"},
    {"LocationID": "BL491", "Name": "Goshen"},
    {"LocationID": "BL492", "Name": "Gozan"},
    {"LocationID": "BL494", "Name": "Zidon"},
    {"LocationID": "BL495", "Name": "Grecia/Greece"},
    {"LocationID": "BL496", "Name": "Gudgodah"},
    {"LocationID": "BL497", "Name": "Gur"},
    {"LocationID": "BL498", "Name": "Gurbaal"},
    {"LocationID": "BL499", "Name": "Habor"},
    {"LocationID": "BL500", "Name": "Hachilah"},
    {"LocationID": "BL501", "Name": "Hadadrimmon"},
    {"LocationID": "BL502", "Name": "Hadashah"},
    {"LocationID": "BL503", "Name": "Hadid"},
    {"LocationID": "BL504", "Name": "Hadrach"},
    {"LocationID": "BL505", "Name": "Eleph"},
    {"LocationID": "BL506", "Name": "Pi-Hahiroth"},
    {"LocationID": "BL508", "Name": "Halah"},
    {"LocationID": "BL509", "Name": "Halhul"},
    {"LocationID": "BL510", "Name": "Hali"},
    {"LocationID": "BL514", "Name": "Ham"},
    {"LocationID": "BL515", "Name": "Ham"},
    {"LocationID": "BL516", "Name": "Hamath"},
    {"LocationID": "BL517", "Name": "Hamath-Zobah"},
    {"LocationID": "BL518", "Name": "Hammath/Hemath"},
    {"LocationID": "BL519", "Name": "Hammon"},
    {"LocationID": "BL520", "Name": "Hammoth-Dor"},
    {"LocationID": "BL521", "Name": "Hamonah"},
    {"LocationID": "BL522", "Name": "Hanes"},
    {"LocationID": "BL523", "Name": "Hannathon"},
    {"LocationID": "BL524", "Name": "Haphraim"},
    {"LocationID": "BL525", "Name": "Hara"},
    {"LocationID": "BL526", "Name": "Haradah"},
    {"LocationID": "BL527", "Name": "Haran"},
    {"LocationID": "BL529", "Name": "Harod"},
    {"LocationID": "BL530", "Name": "Harosheth"},
    {"LocationID": "BL531", "Name": "Hashmonah"},
    {"LocationID": "BL532", "Name": "Hauran"},
    {"LocationID": "BL534", "Name": "Havilah"},
    {"LocationID": "BL535", "Name": "Jair/Havoth-Jair"},
    {"LocationID": "BL536", "Name": "Hazar-Addar"},
    {"LocationID": "BL537", "Name": "Hazar-Enan"},
    {"LocationID": "BL538", "Name": "Hazar-Gaddah"},
    {"LocationID": "BL539", "Name": "Hazar-Shual"},
    {"LocationID": "BL540", "Name": "Hazar-Susah"},
    {"LocationID": "BL541", "Name": "Hazar-Susim"},
    {"LocationID": "BL542", "Name": "Hazezon-Tamar/Hazazon-Tamar"},
    {"LocationID": "BL543", "Name": "Hazar-Hatticon"},
    {"LocationID": "BL544", "Name": "Hazeroth"},
    {"LocationID": "BL545", "Name": "Hazor"},
    {"LocationID": "BL546", "Name": "Hazor"},
    {"LocationID": "BL547", "Name": "Hazor"},
    {"LocationID": "BL548", "Name": "Hazor"},
    {"LocationID": "BL549", "Name": "Hazor"},
    {"LocationID": "BL550", "Name": "Hadattah"},
    {"LocationID": "BL551", "Name": "Hebron"},
    {"LocationID": "BL552", "Name": "Helam"},
    {"LocationID": "BL553", "Name": "Helbah"},
    {"LocationID": "BL554", "Name": "Helbon"},
    {"LocationID": "BL556", "Name": "Heleph"},
    {"LocationID": "BL557", "Name": "Beth-Shemesh"},
    {"LocationID": "BL558", "Name": "Helkath"},
    {"LocationID": "BL559", "Name": "Helkath-Hazzurim"},
    {"LocationID": "BL560", "Name": "Hena"},
    {"LocationID": "BL561", "Name": "Hepher"},
    {"LocationID": "BL563", "Name": "Hareth"},
    {"LocationID": "BL564", "Name": "Hermon"},
    {"LocationID": "BL565", "Name": "Heshbon"},
    {"LocationID": "BL566", "Name": "Heshmon"},
    {"LocationID": "BL567", "Name": "Hethlon"},
    {"LocationID": "BL568", "Name": "Hezron"},
    {"LocationID": "BL569", "Name": "Hierapolis"},
    {"LocationID": "BL570", "Name": "Hilen"},
    {"LocationID": "BL571", "Name": "Hobah"},
    {"LocationID": "BL572", "Name": "Holon"},
    {"LocationID": "BL573", "Name": "Holon"},
    {"LocationID": "BL576", "Name": "Horeb"},
    {"LocationID": "BL577", "Name": "Horem"},
    {"LocationID": "BL579", "Name": "Hor-Hagidgad"},
    {"LocationID": "BL580", "Name": "Hormah"},
    {"LocationID": "BL581", "Name": "Horonaim"},
    {"LocationID": "BL583", "Name": "Hosah"},
    {"LocationID": "BL585", "Name": "Lebanon"},
    {"LocationID": "BL586", "Name": "Hukkok"},
    {"LocationID": "BL587", "Name": "Hukok"},
    {"LocationID": "BL588", "Name": "Humtah"},
    {"LocationID": "BL589", "Name": "Ibleam"},
    {"LocationID": "BL590", "Name": "Iconium"},
    {"LocationID": "BL591", "Name": "Idalah"},
    {"LocationID": "BL592", "Name": "Idumaea"},
    {"LocationID": "BL593", "Name": "Iim"},
    {"LocationID": "BL594", "Name": "Ijon"},
    {"LocationID": "BL595", "Name": "Illyricum"},
    {"LocationID": "BL596", "Name": "Immer"},
    {"LocationID": "BL597", "Name": "India"},
    {"LocationID": "BL598", "Name": "Jiphtah"},
    {"LocationID": "BL599", "Name": "Irpeel"},
    {"LocationID": "BL600", "Name": "Ir-Shemesh"},
    {"LocationID": "BL601", "Name": "Italy"},
    {"LocationID": "BL602", "Name": "Jethlah"},
    {"LocationID": "BL603", "Name": "Ithnan"},
    {"LocationID": "BL604", "Name": "Ituraea"},
    {"LocationID": "BL605", "Name": "Ivah"},
    {"LocationID": "BL606", "Name": "Ije-Abarim"},
    {"LocationID": "BL607", "Name": "Iim"},
    {"LocationID": "BL609", "Name": "Jabbok"},
    {"LocationID": "BL610", "Name": "Jabesh"},
    {"LocationID": "BL611", "Name": "Jabesh-Gilead"},
    {"LocationID": "BL612", "Name": "Jabez"},
    {"LocationID": "BL613", "Name": "Jabneel"},
    {"LocationID": "BL614", "Name": "Jabneel"},
    {"LocationID": "BL615", "Name": "Jabneh"},
    {"LocationID": "BL616", "Name": "Jagur"},
    {"LocationID": "BL617", "Name": "Jahaz"},
    {"LocationID": "BL618", "Name": "Jahzah/Jahazah"},
    {"LocationID": "BL619", "Name": "Jair"},
    {"LocationID": "BL620", "Name": "Janum"},
    {"LocationID": "BL621", "Name": "Janohah"},
    {"LocationID": "BL622", "Name": "Janoah"},
    {"LocationID": "BL623", "Name": "Japhia"},
    {"LocationID": "BL624", "Name": "Jarmuth"},
    {"LocationID": "BL625", "Name": "Jarmuth"},
    {"LocationID": "BL626", "Name": "Jattir"},
    {"LocationID": "BL627", "Name": "Javan"},
    {"LocationID": "BL628", "Name": "Jaazer/Jazer"},
    {"LocationID": "BL629", "Name": "Jebusi/Jebus"},
    {"LocationID": "BL631", "Name": "Jegarsahadutha"},
    {"LocationID": "BL632", "Name": "Jehud"},
    {"LocationID": "BL633", "Name": "Jekabzeel"},
    {"LocationID": "BL634", "Name": "Jericho"},
    {"LocationID": "BL635", "Name": "Jeruel"},
    {"LocationID": "BL636", "Name": "Jerusalem"},
    {"LocationID": "BL638", "Name": "Jeshanah"},
    {"LocationID": "BL639", "Name": "Jeshimon"},
    {"LocationID": "BL640", "Name": "Jeshua"},
    {"LocationID": "BL641", "Name": "Jetur"},
    {"LocationID": "BL642", "Name": "Jezreel"},
    {"LocationID": "BL643", "Name": "Jezreel"},
    {"LocationID": "BL644", "Name": "Jezreel"},
    {"LocationID": "BL645", "Name": "Jogbehah"},
    {"LocationID": "BL646", "Name": "Jokdeam"},
    {"LocationID": "BL647", "Name": "Jokneam"},
    {"LocationID": "BL648", "Name": "Jokmeam"},
    {"LocationID": "BL649", "Name": "Jokneam"},
    {"LocationID": "BL650", "Name": "Joktheel"},
    {"LocationID": "BL651", "Name": "Joktheel"},
    {"LocationID": "BL652", "Name": "Japho/Joppa"},
    {"LocationID": "BL653", "Name": "Jordan"},
    {"LocationID": "BL654", "Name": "Jordan"},
    {"LocationID": "BL655", "Name": "Jotbah"},
    {"LocationID": "BL656", "Name": "Jotbathah/Jotbath"},
    {"LocationID": "BL657", "Name": "Judah/Judaea"},
    {"LocationID": "BL658", "Name": "Judaea"},
    {"LocationID": "BL659", "Name": "Juttah"},
    {"LocationID": "BL660", "Name": "Kabzeel"},
    {"LocationID": "BL661", "Name": "Kadesh"},
    {"LocationID": "BL662", "Name": "Tahtim-Hodshi"},
    {"LocationID": "BL663", "Name": "Kadesh-Barnea"},
    {"LocationID": "BL665", "Name": "Camon"},
    {"LocationID": "BL666", "Name": "Kanah"},
    {"LocationID": "BL667", "Name": "Kanah"},
    {"LocationID": "BL668", "Name": "Karkaa"},
    {"LocationID": "BL669", "Name": "Karkor"},
    {"LocationID": "BL671", "Name": "Kartah"},
    {"LocationID": "BL672", "Name": "Kartan"},
    {"LocationID": "BL673", "Name": "Kattath"},
    {"LocationID": "BL674", "Name": "Kedar"},
    {"LocationID": "BL675", "Name": "Kedemoth"},
    {"LocationID": "BL676", "Name": "Kedesh"},
    {"LocationID": "BL677", "Name": "Kedesh"},
    {"LocationID": "BL678", "Name": "Kedesh"},
    {"LocationID": "BL679", "Name": "Kedesh-Naphtali"},
    {"LocationID": "BL680", "Name": "Kehelathah"},
    {"LocationID": "BL681", "Name": "Keilah"},
    {"LocationID": "BL682", "Name": "Kenath"},
    {"LocationID": "BL683", "Name": "Kerioth"},
    {"LocationID": "BL684", "Name": "Kerioth/Hezron"},
    {"LocationID": "BL685", "Name": "Kibroth-Hattaavah"},
    {"LocationID": "BL686", "Name": "Kibzaim"},
    {"LocationID": "BL687", "Name": "Kidron"},
    {"LocationID": "BL688", "Name": "Kidron/Cedron"},
    {"LocationID": "BL689", "Name": "Kinah"},
    {"LocationID": "BL694", "Name": "Kir-Haraseth/Kir-Hareseth"},
    {"LocationID": "BL695", "Name": "Kirjathaim/Kiriathaim"},
    {"LocationID": "BL696", "Name": "Kirjathaim"},
    {"LocationID": "BL697", "Name": "Kirjath-Arba/Arbah"},
    {"LocationID": "BL698", "Name": "Kirjath-Arim"},
    {"LocationID": "BL699", "Name": "Kirjath-Baal"},
    {"LocationID": "BL700", "Name": "Kirjath-Huzoth"},
    {"LocationID": "BL701", "Name": "Kirjath-Jearim/Kirjath"},
    {"LocationID": "BL702", "Name": "Kirjath-Sannah"},
    {"LocationID": "BL703", "Name": "Kirjath-Sepher"},
    {"LocationID": "BL704", "Name": "Kishion/Kishon"},
    {"LocationID": "BL705", "Name": "Kishon"},
    {"LocationID": "BL706", "Name": "Kitron"},
    {"LocationID": "BL707", "Name": "Chittim"},
    {"LocationID": "BL708", "Name": "Koa"},
    {"LocationID": "BL710", "Name": "Laban"},
    {"LocationID": "BL711", "Name": "Lachish"},
    {"LocationID": "BL712", "Name": "Lahmam"},
    {"LocationID": "BL713", "Name": "Laish"},
    {"LocationID": "BL714", "Name": "Laish"},
    {"LocationID": "BL715", "Name": "Lakum"},
    {"LocationID": "BL716", "Name": "Laodicea"},
    {"LocationID": "BL717", "Name": "Lasea"},
    {"LocationID": "BL718", "Name": "Lasha"},
    {"LocationID": "BL719", "Name": "Lasharon"},
    {"LocationID": "BL720", "Name": "Lebanon"},
    {"LocationID": "BL721", "Name": "Lebaoth"},
    {"LocationID": "BL723", "Name": "Hamath/Hemath"},
    {"LocationID": "BL724", "Name": "Lebonah"},
    {"LocationID": "BL725", "Name": "Jashubi-Lehem"},
    {"LocationID": "BL726", "Name": "Lehi"},
    {"LocationID": "BL727", "Name": "Leshem"},
    {"LocationID": "BL728", "Name": "Libnah"},
    {"LocationID": "BL729", "Name": "Libnah"},
    {"LocationID": "BL730", "Name": "Libya"},
    {"LocationID": "BL731", "Name": "Lod"},
    {"LocationID": "BL732", "Name": "Lo-Debar"},
    {"LocationID": "BL733", "Name": "Beth-Horon"},
    {"LocationID": "BL734", "Name": "Beth-Horon"},
    {"LocationID": "BL735", "Name": "Lud/Lydians/Lydia"},
    {"LocationID": "BL736", "Name": "Luhith"},
    {"LocationID": "BL737", "Name": "Luz"},
    {"LocationID": "BL738", "Name": "Luz"},
    {"LocationID": "BL739", "Name": "Lycaonia"},
    {"LocationID": "BL740", "Name": "Lycia"},
    {"LocationID": "BL741", "Name": "Lydda"},
    {"LocationID": "BL742", "Name": "Lystra"},
    {"LocationID": "BL743", "Name": "Maacah/Maachah"},
    {"LocationID": "BL745", "Name": "Maarath"},
    {"LocationID": "BL746", "Name": "Gibeah"},
    {"LocationID": "BL747", "Name": "Macedonia"},
    {"LocationID": "BL748", "Name": "Machpelah"},
    {"LocationID": "BL749", "Name": "Madmannah"},
    {"LocationID": "BL750", "Name": "Madmen"},
    {"LocationID": "BL751", "Name": "Madmenah"},
    {"LocationID": "BL752", "Name": "Madon"},
    {"LocationID": "BL753", "Name": "Magdala"},
    {"LocationID": "BL754", "Name": "Magog"},
    {"LocationID": "BL756", "Name": "Mahanaim"},
    {"LocationID": "BL757", "Name": "Dan/Mahaneh-Dan"},
    {"LocationID": "BL758", "Name": "Makaz"},
    {"LocationID": "BL759", "Name": "Makheloth"},
    {"LocationID": "BL760", "Name": "Makkedah"},
    {"LocationID": "BL761", "Name": "Melita"},
    {"LocationID": "BL762", "Name": "Mamre"},
    {"LocationID": "BL763", "Name": "Manahath"},
    {"LocationID": "BL764", "Name": "Maon"},
    {"LocationID": "BL765", "Name": "Marah"},
    {"LocationID": "BL766", "Name": "Maralah"},
    {"LocationID": "BL767", "Name": "Mareshah"},
    {"LocationID": "BL768", "Name": "Maroth"},
    {"LocationID": "BL769", "Name": "Mashal"},
    {"LocationID": "BL770", "Name": "Masrekah"},
    {"LocationID": "BL771", "Name": "Massah"},
    {"LocationID": "BL772", "Name": "Mattanah"},
    {"LocationID": "BL773", "Name": "Mearah"},
    {"LocationID": "BL774", "Name": "Mekonah"},
    {"LocationID": "BL775", "Name": "Medeba"},
    {"LocationID": "BL776", "Name": "Medes/Media"},
    {"LocationID": "BL777", "Name": "Megiddo/Megiddon"},
    {"LocationID": "BL778", "Name": "Me-Jarkon"},
    {"LocationID": "BL779", "Name": "Noph/Memphis"},
    {"LocationID": "BL780", "Name": "Mephaath"},
    {"LocationID": "BL781", "Name": "Merathaim"},
    {"LocationID": "BL782", "Name": "Meribah"},
    {"LocationID": "BL783", "Name": "Meribah"},
    {"LocationID": "BL784", "Name": "Meribah-Kadesh/Kadesh"},
    {"LocationID": "BL785", "Name": "Merom"},
    {"LocationID": "BL786", "Name": "Meroz"},
    {"LocationID": "BL787", "Name": "Mesha"},
    {"LocationID": "BL788", "Name": "Mesech/Meshech"},
    {"LocationID": "BL789", "Name": "Meshech/Tubal"},
    {"LocationID": "BL790", "Name": "Mesopotamia"},
    {"LocationID": "BL791", "Name": "Metheg-Ammah"},
    {"LocationID": "BL792", "Name": "Michmas"},
    {"LocationID": "BL793", "Name": "Michmash"},
    {"LocationID": "BL794", "Name": "Michmethah"},
    {"LocationID": "BL795", "Name": "Middin"},
    {"LocationID": "BL796", "Name": "Midian"},
    {"LocationID": "BL797", "Name": "Migdal-El"},
    {"LocationID": "BL798", "Name": "Migdal-Gad"},
    {"LocationID": "BL799", "Name": "Migdol"},
    {"LocationID": "BL800", "Name": "Migron"},
    {"LocationID": "BL801", "Name": "Miletus/Miletum"},
    {"LocationID": "BL802", "Name": "Millo"},
    {"LocationID": "BL803", "Name": "Minni"},
    {"LocationID": "BL804", "Name": "Minnith"},
    {"LocationID": "BL805", "Name": "Misheal/Mishal"},
    {"LocationID": "BL806", "Name": "Misrephoth-Maim"},
    {"LocationID": "BL807", "Name": "Mithcah"},
    {"LocationID": "BL808", "Name": "Mitylene"},
    {"LocationID": "BL809", "Name": "Mizpah/Mizpeh"},
    {"LocationID": "BL810", "Name": "Mizpeh"},
    {"LocationID": "BL811", "Name": "Mizpeh/Mizpah"},
    {"LocationID": "BL812", "Name": "Mizpeh"},
    {"LocationID": "BL813", "Name": "Mizpeh"},
    {"LocationID": "BL814", "Name": "Mizpeh"},
    {"LocationID": "BL815", "Name": "Moab"},
    {"LocationID": "BL816", "Name": "Moladah"},
    {"LocationID": "BL817", "Name": "Moreh"},
    {"LocationID": "BL818", "Name": "Moreh"},
    {"LocationID": "BL820", "Name": "Moresheth-Gath"},
    {"LocationID": "BL821", "Name": "Moriah"},
    {"LocationID": "BL822", "Name": "Maktesh"},
    {"LocationID": "BL823", "Name": "Mosera"},
    {"LocationID": "BL824", "Name": "Moseroth"},
    {"LocationID": "BL829", "Name": "Baal-Hermon"},
    {"LocationID": "BL830", "Name": "Baalah"},
    {"LocationID": "BL831", "Name": "Carmel"},
    {"LocationID": "BL832", "Name": "Ebal"},
    {"LocationID": "BL833", "Name": "Ephraim"},
    {"LocationID": "BL834", "Name": "Ephron"},
    {"LocationID": "BL835", "Name": "Esau"},
    {"LocationID": "BL836", "Name": "Gerizim"},
    {"LocationID": "BL837", "Name": "Gilboa"},
    {"LocationID": "BL838", "Name": "Gilead"},
    {"LocationID": "BL839", "Name": "Halak"},
    {"LocationID": "BL840", "Name": "Heres"},
    {"LocationID": "BL841", "Name": "Hermon"},
    {"LocationID": "BL842", "Name": "Hor"},
    {"LocationID": "BL843", "Name": "Hor"},
    {"LocationID": "BL844", "Name": "Horeb"},
    {"LocationID": "BL845", "Name": "Jearim"},
    {"LocationID": "BL846", "Name": "Lebanon"},
    {"LocationID": "BL847", "Name": "Mizar"},
    {"LocationID": "BL848", "Name": "Moriah"},
    {"LocationID": "BL849", "Name": "Nebo"},
    {"LocationID": "BL850", "Name": "Paran"},
    {"LocationID": "BL851", "Name": "Perazim"},
    {"LocationID": "BL852", "Name": "Seir"},
    {"LocationID": "BL853", "Name": "Seir"},
    {"LocationID": "BL854", "Name": "Shapher"},
    {"LocationID": "BL855", "Name": "Sinai/Sina"},
    {"LocationID": "BL856", "Name": "Sion"},
    {"LocationID": "BL857", "Name": "Tabor"},
    {"LocationID": "BL858", "Name": "Zalmon"},
    {"LocationID": "BL859", "Name": "Zemaraim"},
    {"LocationID": "BL860", "Name": "Zion/Sion"},
    {"LocationID": "BL861", "Name": "Olivet/Olives"},
    {"LocationID": "BL862", "Name": "Mozah"},
    {"LocationID": "BL863", "Name": "Miphkad"},
    {"LocationID": "BL864", "Name": "Myra"},
    {"LocationID": "BL865", "Name": "Mysia"},
    {"LocationID": "BL866", "Name": "Naamah"},
    {"LocationID": "BL867", "Name": "Naarath"},
    {"LocationID": "BL868", "Name": "Naaran"},
    {"LocationID": "BL869", "Name": "Nahallal/Nahalal"},
    {"LocationID": "BL870", "Name": "Nahaliel"},
    {"LocationID": "BL871", "Name": "Nahalol"},
    {"LocationID": "BL872", "Name": "Nain"},
    {"LocationID": "BL873", "Name": "Naioth"},
    {"LocationID": "BL875", "Name": "Dor"},
    {"LocationID": "BL876", "Name": "Nephish"},
    {"LocationID": "BL877", "Name": "Dor"},
    {"LocationID": "BL878", "Name": "Nazareth"},
    {"LocationID": "BL879", "Name": "Neah"},
    {"LocationID": "BL880", "Name": "Neapolis"},
    {"LocationID": "BL881", "Name": "Nebaioth"},
    {"LocationID": "BL882", "Name": "Neballat"},
    {"LocationID": "BL883", "Name": "Nebo"},
    {"LocationID": "BL884", "Name": "Nebo"},
    {"LocationID": "BL887", "Name": "Neiel"},
    {"LocationID": "BL888", "Name": "Nephtoah"},
    {"LocationID": "BL892", "Name": "Nezib"},
    {"LocationID": "BL893", "Name": "Nibshan"},
    {"LocationID": "BL894", "Name": "Nicopolis"},
    {"LocationID": "BL896", "Name": "Nimrah"},
    {"LocationID": "BL897", "Name": "Nimrim"},
    {"LocationID": "BL898", "Name": "Nimrod"},
    {"LocationID": "BL899", "Name": "Nineveh"},
    {"LocationID": "BL900", "Name": "Nob"},
    {"LocationID": "BL901", "Name": "Nobah"},
    {"LocationID": "BL902", "Name": "Nod"},
    {"LocationID": "BL903", "Name": "Nodab"},
    {"LocationID": "BL905", "Name": "Nophah"},
    {"LocationID": "BL906", "Name": "Oboth"},
    {"LocationID": "BL908", "Name": "On/Aven"},
    {"LocationID": "BL909", "Name": "Ono"},
    {"LocationID": "BL910", "Name": "Ophel"},
    {"LocationID": "BL911", "Name": "Ophir"},
    {"LocationID": "BL912", "Name": "Ophni"},
    {"LocationID": "BL913", "Name": "Ophrah"},
    {"LocationID": "BL914", "Name": "Ophrah"},
    {"LocationID": "BL915", "Name": "Padan"},
    {"LocationID": "BL916", "Name": "Padan-Aram"},
    {"LocationID": "BL917", "Name": "Pai"},
    {"LocationID": "BL918", "Name": "Pamphylia"},
    {"LocationID": "BL919", "Name": "Paphos"},
    {"LocationID": "BL920", "Name": "Parah"},
    {"LocationID": "BL921", "Name": "Paran"},
    {"LocationID": "BL922", "Name": "Parvaim"},
    {"LocationID": "BL923", "Name": "Pas-Dammim"},
    {"LocationID": "BL924", "Name": "Patara"},
    {"LocationID": "BL925", "Name": "Pathros"},
    {"LocationID": "BL926", "Name": "Patmos"},
    {"LocationID": "BL927", "Name": "Pau"},
    {"LocationID": "BL928", "Name": "Pekod"},
    {"LocationID": "BL929", "Name": "Sin"},
    {"LocationID": "BL930", "Name": "Peniel"},
    {"LocationID": "BL931", "Name": "Penuel"},
    {"LocationID": "BL933", "Name": "Peor"},
    {"LocationID": "BL934", "Name": "Perez-Uzza"},
    {"LocationID": "BL935", "Name": "Perez-Uzzah"},
    {"LocationID": "BL936", "Name": "Perga"},
    {"LocationID": "BL937", "Name": "Pergamos"},
    {"LocationID": "BL938", "Name": "Persia"},
    {"LocationID": "BL939", "Name": "Pethor"},
    {"LocationID": "BL940", "Name": "Pharpar"},
    {"LocationID": "BL941", "Name": "Philadelphia"},
    {"LocationID": "BL942", "Name": "Philippi"},
    {"LocationID": "BL943", "Name": "Palestina/Philistia"},
    {"LocationID": "BL944", "Name": "Phenice/Phenicia"},
    {"LocationID": "BL945", "Name": "Phenice"},
    {"LocationID": "BL946", "Name": "Phrygia"},
    {"LocationID": "BL947", "Name": "Pi-Beseth"},
    {"LocationID": "BL948", "Name": "Pi-Hahiroth"},
    {"LocationID": "BL949", "Name": "Pirathon"},
    {"LocationID": "BL950", "Name": "Pisgah"},
    {"LocationID": "BL951", "Name": "Pison"},
    {"LocationID": "BL952", "Name": "Pisidia"},
    {"LocationID": "BL953", "Name": "Pithom"},
    {"LocationID": "BL956", "Name": "Pontus"},
    {"LocationID": "BL959", "Name": "Ptolemais"},
    {"LocationID": "BL960", "Name": "Pul"},
    {"LocationID": "BL961", "Name": "Punon"},
    {"LocationID": "BL962", "Name": "Libyans/Put"},
    {"LocationID": "BL963", "Name": "Puteoli"},
    {"LocationID": "BL964", "Name": "Raamah"},
    {"LocationID": "BL965", "Name": "Raamses"},
    {"LocationID": "BL966", "Name": "Rabbath/Rabbah"},
    {"LocationID": "BL967", "Name": "Rabbith"},
    {"LocationID": "BL968", "Name": "Rachal"},
    {"LocationID": "BL969", "Name": "Rahab"},
    {"LocationID": "BL970", "Name": "Rakkath"},
    {"LocationID": "BL971", "Name": "Rakkon"},
    {"LocationID": "BL972", "Name": "Ramah/Ramath"},
    {"LocationID": "BL973", "Name": "Ramah"},
    {"LocationID": "BL974", "Name": "Ramah"},
    {"LocationID": "BL975", "Name": "Ramah"},
    {"LocationID": "BL976", "Name": "Ramah"},
    {"LocationID": "BL977", "Name": "Ramathaim-Zophim"},
    {"LocationID": "BL978", "Name": "Ramath-Lehi"},
    {"LocationID": "BL979", "Name": "Ramath-Mizpeh"},
    {"LocationID": "BL980", "Name": "Rameses"},
    {"LocationID": "BL981", "Name": "Ramoth"},
    {"LocationID": "BL982", "Name": "Ramoth"},
    {"LocationID": "BL983", "Name": "Ramoth"},
    {"LocationID": "BL984", "Name": "Ramoth-Gilead"},
    {"LocationID": "BL985", "Name": "Rechah"},
    {"LocationID": "BL986", "Name": "Red/sea"},
    {"LocationID": "BL987", "Name": "Rehob"},
    {"LocationID": "BL988", "Name": "Rehob"},
    {"LocationID": "BL989", "Name": "Rehob"},
    {"LocationID": "BL990", "Name": "Rehoboth"},
    {"LocationID": "BL991", "Name": "Rehoboth"},
    {"LocationID": "BL992", "Name": "Rehoboth"},
    {"LocationID": "BL993", "Name": "Rekem"},
    {"LocationID": "BL994", "Name": "Remeth"},
    {"LocationID": "BL996", "Name": "Rephidim"},
    {"LocationID": "BL997", "Name": "Resen"},
    {"LocationID": "BL998", "Name": "Rezeph"},
    {"LocationID": "BL999", "Name": "Rhegium"},
    {"LocationID": "BL1000", "Name": "Rhodes"},
    {"LocationID": "BL1001", "Name": "Riblah/Diblath"},
    {"LocationID": "BL1002", "Name": "Riblah"},
    {"LocationID": "BL1003", "Name": "Rimmon"},
    {"LocationID": "BL1004", "Name": "Rimmon/Remmon"},
    {"LocationID": "BL1006", "Name": "Rimmon"},
    {"LocationID": "BL1007", "Name": "Rimmon-Parez"},
    {"LocationID": "BL1008", "Name": "Rissah"},
    {"LocationID": "BL1009", "Name": "Rithmah"},
    {"LocationID": "BL1012", "Name": "Rogelim"},
    {"LocationID": "BL1013", "Name": "Rome"},
    {"LocationID": "BL1014", "Name": "Rumah"},
    {"LocationID": "BL1016", "Name": "Salamis"},
    {"LocationID": "BL1017", "Name": "Salchah/Salcah"},
    {"LocationID": "BL1018", "Name": "Salem"},
    {"LocationID": "BL1019", "Name": "Salim"},
    {"LocationID": "BL1020", "Name": "Salmone"},
    {"LocationID": "BL1021", "Name": "Salt Ssea"},
    {"LocationID": "BL1022", "Name": "Samaria"},
    {"LocationID": "BL1023", "Name": "Samaria"},
    {"LocationID": "BL1024", "Name": "Samos"},
    {"LocationID": "BL1025", "Name": "Samothracia"},
    {"LocationID": "BL1026", "Name": "Sansannah"},
    {"LocationID": "BL1027", "Name": "Sardis"},
    {"LocationID": "BL1028", "Name": "Sarid"},
    {"LocationID": "BL1029", "Name": "Chinnereth"},
    {"LocationID": "BL1030", "Name": "Chinneroth"},
    {"LocationID": "BL1032", "Name": "Galilee"},
    {"LocationID": "BL1034", "Name": "Tiberias"},
    {"LocationID": "BL1037", "Name": "Seba"},
    {"LocationID": "BL1038", "Name": "Shebam"},
    {"LocationID": "BL1039", "Name": "Secacah"},
    {"LocationID": "BL1040", "Name": "College"},
    {"LocationID": "BL1041", "Name": "Sechu"},
    {"LocationID": "BL1042", "Name": "Seir"},
    {"LocationID": "BL1043", "Name": "Seirath"},
    {"LocationID": "BL1044", "Name": "Sela"},
    {"LocationID": "BL1045", "Name": "Seleucia"},
    {"LocationID": "BL1046", "Name": "Seneh"},
    {"LocationID": "BL1047", "Name": "Shenir/Senir"},
    {"LocationID": "BL1048", "Name": "Sephar"},
    {"LocationID": "BL1049", "Name": "Sepharad"},
    {"LocationID": "BL1050", "Name": "Sepharvaim"},
    {"LocationID": "BL1051", "Name": "Zoheleth"},
    {"LocationID": "BL1052", "Name": "Shaalabbin"},
    {"LocationID": "BL1053", "Name": "Shaalbim"},
    {"LocationID": "BL1054", "Name": "Shalim"},
    {"LocationID": "BL1055", "Name": "Sharaim/Shaaraim"},
    {"LocationID": "BL1056", "Name": "Shaaraim"},
    {"LocationID": "BL1057", "Name": "Shahazimah"},
    {"LocationID": "BL1058", "Name": "Shalisha"},
    {"LocationID": "BL1059", "Name": "Shallecheth"},
    {"LocationID": "BL1060", "Name": "Shamir"},
    {"LocationID": "BL1061", "Name": "Shamir"},
    {"LocationID": "BL1062", "Name": "Saphir"},
    {"LocationID": "BL1063", "Name": "Sharon/Saron"},
    {"LocationID": "BL1064", "Name": "Sharon"},
    {"LocationID": "BL1065", "Name": "Sharuhen"},
    {"LocationID": "BL1066", "Name": "Shaveh/Kiriathaim"},
    {"LocationID": "BL1067", "Name": "Sheba"},
    {"LocationID": "BL1068", "Name": "Shebarim"},
    {"LocationID": "BL1069", "Name": "Sichem/Shechem"},
    {"LocationID": "BL1071", "Name": "Shema"},
    {"LocationID": "BL1072", "Name": "Shen"},
    {"LocationID": "BL1073", "Name": "Shepham"},
    {"LocationID": "BL1075", "Name": "Shebah"},
    {"LocationID": "BL1076", "Name": "Sihor"},
    {"LocationID": "BL1077", "Name": "Shihor-Libnath"},
    {"LocationID": "BL1078", "Name": "Shicron"},
    {"LocationID": "BL1079", "Name": "Shilhim"},
    {"LocationID": "BL1080", "Name": "Shiloah"},
    {"LocationID": "BL1081", "Name": "Shiloh"},
    {"LocationID": "BL1082", "Name": "Shimron"},
    {"LocationID": "BL1083", "Name": "Shimron-Meron"},
    {"LocationID": "BL1084", "Name": "Shinar"},
    {"LocationID": "BL1085", "Name": "Shion"},
    {"LocationID": "BL1086", "Name": "Shittim"},
    {"LocationID": "BL1087", "Name": "Shoa"},
    {"LocationID": "BL1088", "Name": "Shual"},
    {"LocationID": "BL1089", "Name": "Shunem"},
    {"LocationID": "BL1090", "Name": "Shur"},
    {"LocationID": "BL1091", "Name": "Shibmah/Sibmah"},
    {"LocationID": "BL1092", "Name": "Sibraim"},
    {"LocationID": "BL1093", "Name": "Sidon/Zidon"},
    {"LocationID": "BL1094", "Name": "Zidon"},
    {"LocationID": "BL1095", "Name": "Silla"},
    {"LocationID": "BL1096", "Name": "Siloam"},
    {"LocationID": "BL1097", "Name": "Sin"},
    {"LocationID": "BL1098", "Name": "Sinai"},
    {"LocationID": "BL1099", "Name": "Siphmoth"},
    {"LocationID": "BL1100", "Name": "Sirah"},
    {"LocationID": "BL1101", "Name": "Sirion/field"},
    {"LocationID": "BL1102", "Name": "Sitnah"},
    {"LocationID": "BL1103", "Name": "Smyrna"},
    {"LocationID": "BL1104", "Name": "Shoco"},
    {"LocationID": "BL1105", "Name": "Socoh"},
    {"LocationID": "BL1106", "Name": "Socoh"},
    {"LocationID": "BL1107", "Name": "Sodom/Sodoma"},
    {"LocationID": "BL1111", "Name": "Spain"},
    {"LocationID": "BL1113", "Name": "Succoth"},
    {"LocationID": "BL1114", "Name": "Succoth"},
    {"LocationID": "BL1117", "Name": "Sur"},
    {"LocationID": "BL1118", "Name": "Shushan"},
    {"LocationID": "BL1119", "Name": "Sychar"},
    {"LocationID": "BL1120", "Name": "Sinim/Syene"},
    {"LocationID": "BL1121", "Name": "Syracuse"},
    {"LocationID": "BL1122", "Name": "Syria/Syrians"},
    {"LocationID": "BL1123", "Name": "Quicksands"},
    {"LocationID": "BL1124", "Name": "Taanach/Tanach"},
    {"LocationID": "BL1125", "Name": "Taanath-Shiloh"},
    {"LocationID": "BL1126", "Name": "Tabbath"},
    {"LocationID": "BL1127", "Name": "Taberah"},
    {"LocationID": "BL1128", "Name": "Tabor"},
    {"LocationID": "BL1129", "Name": "Tabor"},
    {"LocationID": "BL1130", "Name": "Tabor"},
    {"LocationID": "BL1131", "Name": "Tadmor"},
    {"LocationID": "BL1132", "Name": "Tahath"},
    {"LocationID": "BL1133", "Name": "Tahpanhes"},
    {"LocationID": "BL1134", "Name": "Tadmor"},
    {"LocationID": "BL1135", "Name": "Tamar"},
    {"LocationID": "BL1136", "Name": "Tappuah"},
    {"LocationID": "BL1137", "Name": "Tappuah"},
    {"LocationID": "BL1138", "Name": "Taralah"},
    {"LocationID": "BL1139", "Name": "Tharshish/Tarshish"},
    {"LocationID": "BL1140", "Name": "Tarsus"},
    {"LocationID": "BL1141", "Name": "Tehaphnehes"},
    {"LocationID": "BL1142", "Name": "Tekoah/Tekoa"},
    {"LocationID": "BL1143", "Name": "Tel-Abib"},
    {"LocationID": "BL1144", "Name": "Telaim"},
    {"LocationID": "BL1145", "Name": "Thelasar/Telassar"},
    {"LocationID": "BL1146", "Name": "Telem"},
    {"LocationID": "BL1147", "Name": "Tel-Harsa/Tel-Haresha"},
    {"LocationID": "BL1148", "Name": "Tel-Melah"},
    {"LocationID": "BL1149", "Name": "Tema"},
    {"LocationID": "BL1150", "Name": "Teman"},
    {"LocationID": "BL1151", "Name": "Tarah"},
    {"LocationID": "BL1154", "Name": "Calvary"},
    {"LocationID": "BL1155", "Name": "Pavement"},
    {"LocationID": "BL1156", "Name": "No"},
    {"LocationID": "BL1157", "Name": "Thebez"},
    {"LocationID": "BL1158", "Name": "Thessalonica"},
    {"LocationID": "BL1159", "Name": "taverns"},
    {"LocationID": "BL1160", "Name": "Thyatira"},
    {"LocationID": "BL1161", "Name": "Tiberias"},
    {"LocationID": "BL1162", "Name": "Tibhath"},
    {"LocationID": "BL1163", "Name": "Hiddekel"},
    {"LocationID": "BL1164", "Name": "Timnath/Timnah"},
    {"LocationID": "BL1165", "Name": "Timnah"},
    {"LocationID": "BL1166", "Name": "Timnath-Heres"},
    {"LocationID": "BL1167", "Name": "Timnath-Serah"},
    {"LocationID": "BL1168", "Name": "Tiphsah"},
    {"LocationID": "BL1169", "Name": "Tiphsah"},
    {"LocationID": "BL1170", "Name": "Tirzah"},
    {"LocationID": "BL1171", "Name": "Tishbite"},
    {"LocationID": "BL1172", "Name": "Tob"},
    {"LocationID": "BL1173", "Name": "Tochen"},
    {"LocationID": "BL1174", "Name": "Tolad"},
    {"LocationID": "BL1175", "Name": "Tophel"},
    {"LocationID": "BL1176", "Name": "Topheth/Tophet"},
    {"LocationID": "BL1177", "Name": "Hananeel"},
    {"LocationID": "BL1178", "Name": "Shechem"},
    {"LocationID": "BL1181", "Name": "Trachonitis"},
    {"LocationID": "BL1182", "Name": "Troas"},
    {"LocationID": "BL1183", "Name": "Tubal"},
    {"LocationID": "BL1184", "Name": "Tyre/Tyrus"},
    {"LocationID": "BL1185", "Name": "Ulai"},
    {"LocationID": "BL1186", "Name": "Ummah"},
    {"LocationID": "BL1187", "Name": "Uphaz"},
    {"LocationID": "BL1188", "Name": "Beth-Horon"},
    {"LocationID": "BL1189", "Name": "Ur"},
    {"LocationID": "BL1190", "Name": "Uz"},
    {"LocationID": "BL1192", "Name": "Uzza"},
    {"LocationID": "BL1193", "Name": "Uzzen-Sherah"},
    {"LocationID": "BL1194", "Name": "Succoth"},
    {"LocationID": "BL1196", "Name": "Achor"},
    {"LocationID": "BL1197", "Name": "Ajalon"},
    {"LocationID": "BL1198", "Name": "Aven"},
    {"LocationID": "BL1199", "Name": "Baca"},
    {"LocationID": "BL1200", "Name": "Berachah"},
    {"LocationID": "BL1201", "Name": "Elah"},
    {"LocationID": "BL1202", "Name": "Eshcol"},
    {"LocationID": "BL1203", "Name": "Gerar"},
    {"LocationID": "BL1204", "Name": "Gibeon"},
    {"LocationID": "BL1205", "Name": "Hamon-Gog"},
    {"LocationID": "BL1206", "Name": "Hebron"},
    {"LocationID": "BL1207", "Name": "Hinnom"},
    {"LocationID": "BL1208", "Name": "Jiphthah-El"},
    {"LocationID": "BL1209", "Name": "Jehoshaphat"},
    {"LocationID": "BL1210", "Name": "Jericho"},
    {"LocationID": "BL1211", "Name": "Jezreel"},
    {"LocationID": "BL1212", "Name": "Lebanon"},
    {"LocationID": "BL1213", "Name": "Mizpeh"},
    {"LocationID": "BL1215", "Name": "Salt"},
    {"LocationID": "BL1216", "Name": "Shaveh"},
    {"LocationID": "BL1217", "Name": "Shittim"},
    {"LocationID": "BL1218", "Name": "Siddim"},
    {"LocationID": "BL1220", "Name": "Sorek"},
    {"LocationID": "BL1221", "Name": "Succoth"},
    {"LocationID": "BL1222", "Name": "Zeboim"},
    {"LocationID": "BL1223", "Name": "Zephathah"},
    {"LocationID": "BL1224", "Name": "Zared"},
    {"LocationID": "BL1225", "Name": "Arnon"},
    {"LocationID": "BL1226", "Name": "Hinnom"},
    {"LocationID": "BL1228", "Name": "Red Sea"},
    {"LocationID": "BL1233", "Name": "Iron"},
    {"LocationID": "BL1234", "Name": "Zaanan"},
    {"LocationID": "BL1235", "Name": "Zaanannim/Zaanaim"},
    {"LocationID": "BL1236", "Name": "Zair"},
    {"LocationID": "BL1237", "Name": "Salmon"},
    {"LocationID": "BL1238", "Name": "Zalmonah"},
    {"LocationID": "BL1239", "Name": "Zanoah"},
    {"LocationID": "BL1240", "Name": "Zanoah"},
    {"LocationID": "BL1241", "Name": "Zaphon"},
    {"LocationID": "BL1242", "Name": "Zarephath/Sarepta"},
    {"LocationID": "BL1243", "Name": "Zaretan/Zartanah"},
    {"LocationID": "BL1244", "Name": "Zeboim/Zeboiim"},
    {"LocationID": "BL1245", "Name": "Zeboim"},
    {"LocationID": "BL1246", "Name": "Zedad"},
    {"LocationID": "BL1247", "Name": "Zelah"},
    {"LocationID": "BL1248", "Name": "Zelzah"},
    {"LocationID": "BL1249", "Name": "Zemaraim"},
    {"LocationID": "BL1250", "Name": "Zenan"},
    {"LocationID": "BL1251", "Name": "Zephath"},
    {"LocationID": "BL1252", "Name": "Zer"},
    {"LocationID": "BL1253", "Name": "Zered"},
    {"LocationID": "BL1254", "Name": "Zereda"},
    {"LocationID": "BL1255", "Name": "Zeredathah"},
    {"LocationID": "BL1256", "Name": "Zererath"},
    {"LocationID": "BL1257", "Name": "Zareth-Shahar"},
    {"LocationID": "BL1258", "Name": "Ziddim"},
    {"LocationID": "BL1259", "Name": "Ziklag"},
    {"LocationID": "BL1260", "Name": "Zimri"},
    {"LocationID": "BL1261", "Name": "Zin"},
    {"LocationID": "BL1262", "Name": "Zin"},
    {"LocationID": "BL1263", "Name": "Zion/Sion"},
    {"LocationID": "BL1264", "Name": "Zion"},
    {"LocationID": "BL1265", "Name": "Zior"},
    {"LocationID": "BL1266", "Name": "Ziph"},
    {"LocationID": "BL1267", "Name": "Ziph"},
    {"LocationID": "BL1268", "Name": "Ziphron"},
    {"LocationID": "BL1269", "Name": "Ziz"},
    {"LocationID": "BL1270", "Name": "Zoan"},
    {"LocationID": "BL1271", "Name": "Zoar"},
    {"LocationID": "BL1272", "Name": "Zobah/Zoba"},
    {"LocationID": "BL1273", "Name": "Zobah/Hamath"},
    {"LocationID": "BL1274", "Name": "Zophim"},
    {"LocationID": "BL1275", "Name": "Zoreah/Zorah"},
    {"LocationID": "BL1276", "Name": "Zup"},
  ];

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