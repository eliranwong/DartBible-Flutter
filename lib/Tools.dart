import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'config.dart';
import 'Bibles.dart';
import 'Helpers.dart';
import 'BibleSearchDelegate.dart';
import 'BibleParser.dart';
import 'package:photo_view/photo_view.dart';

class ToolMenu extends StatelessWidget {
  final Map _title;
  final String _module;
  final List _data;
  final Config _config;
  final Bible _bible;
  final Icon _icon;
  final Map _interfaceDialog;
  final List _bcvList;

  ToolMenu(this._title, this._module, this._data, this._config, this._bible, this._icon, this._interfaceDialog, this._bcvList);

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
    var statement = "SELECT Topic, Passages FROM $_module WHERE Tool = ? ORDER BY Number";
    List<Map> tools = await db.rawQuery(statement, [tool]);
    db.close();

    final selected = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ToolView(_data[tool], tools, _config, _bible, _interfaceDialog, _icon, _bcvList)),
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
  final List _bcvList;

  ToolView(this._title, this._data, this._config, this._bible, this._interfaceDialog, this._icon, this._bcvList);

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
        padding: const EdgeInsets.all(16.0),
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
    List bcvLists = BibleParser(_config.abbreviations).extractAllReferences(itemData["Passages"]);
    List passages = _bible.openMultipleVerses(bcvLists, topic);
    final List selected = await showSearch(
        context: context,
        delegate: BibleSearchDelegate(context, _bible, _interfaceDialog, _config, passages, _bcvList));
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

  Relationship(this._title, this._data, this._config, this._bible, this._interfaceDialog, this._bcvList);

  @override
  RelationshipState createState() => RelationshipState(this._title, this._data, this._config, this._bible, this._interfaceDialog, this._bcvList);
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

  RelationshipState(this._title, this._data, this._config, this._bible, this._interfaceDialog, this._bcvList);

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
        padding: const EdgeInsets.all(16.0),
        itemCount: _data.length,
        itemBuilder: (context, i) {
          return _buildItemRow(context, i);
        });
  }

  Widget _buildItemRow(BuildContext context, int i) {
    Map itemData = _data[i];
    Icon icon = (itemData["Sex"] == "F") ? Icon(Icons.person_outline, color: _config.myColors["black"],) : Icon(Icons.person, color: _config.myColors["black"],);
    return ListTile(
      leading: icon,
      title: Text(itemData["Name"], style: _config.verseTextStyle["verseFont"]),
      subtitle: Text(itemData["Relationship"], style: TextStyle(fontSize: _config.fontSize - 4, color: _config.myColors["grey"],)),
      trailing: IconButton(
        tooltip: interface[_config.abbreviations][0],
        icon: Icon(Icons.search, color: _config.myColors["black"],),
        onPressed: () {
          _loadPeopleVerses(context, itemData["PersonID"]);
        },
      ),

      onTap: () {
        _updateRelationship(context, itemData);
      },

    );
  }

  Future _updateRelationship(BuildContext context, Map itemData) async {
    final Database db = await SqliteHelper(_config).initToolsDb();
    var statement = "SELECT PersonID, Name, Sex, Relationship FROM PEOPLERELATIONSHIP WHERE RelatedPersonID = ? AND Relationship != '[Reference]' ORDER BY RelationshipOrder";
    List<Map> tools = await db.rawQuery(statement, [itemData["PersonID"]]);
    db.close();
    setState(() {
      _title = itemData["Name"];
      _data = tools;
    });
  }

  Future _loadPeopleVerses(BuildContext context, int personID) async {
    final Database db = await SqliteHelper(_config).initToolsDb();
    var statement = "SELECT Book, Chapter, Verse FROM PEOPLE WHERE PersonID = ?";
    List<Map> tools = await db.rawQuery(statement, [personID]);
    db.close();
    List<List> bcvLists = tools.map((i) => [i["Book"], i["Chapter"], i["Verse"]]).toList();
    List verseData = _bible.openMultipleVerses(bcvLists);
    final List selected = await showSearch(
        context: context,
        delegate: BibleSearchDelegate(context, _bible, _interfaceDialog, _config, verseData, _bcvList));
    if (selected != null) Navigator.pop(context, selected);
  }

}

class Timeline extends StatefulWidget {

  final String _file;
  final String _title;
  final List _timelines;
  final Config _config;

  Timeline(this._file, this._title, this._timelines, this._config);

  @override
  TimelineState createState() => TimelineState(this._file, this._title, this._timelines, this._config);
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
            )
        ),
      ),
    );
  }

}