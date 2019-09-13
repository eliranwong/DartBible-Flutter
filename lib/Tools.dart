import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:unique_bible_app/config.dart';
import 'package:unique_bible_app/Bibles.dart';
import 'package:unique_bible_app/Helpers.dart';
import 'package:unique_bible_app/BibleSearchDelegate.dart';
import 'package:unique_bible_app/BibleParser.dart';
import 'package:photo_view/photo_view.dart';

class ToolMenu extends StatelessWidget {
  final Map _title;
  final String _module;
  final List _data;
  final Config _config;
  final Bible _bible;
  final Icon _icon;
  final Map _interfaceDialog;

  ToolMenu(this._title, this._module, this._data, this._config, this._bible, this._icon, this._interfaceDialog);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title[_config.abbreviations]),
      ),
      body: _buildItems(context),
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
      MaterialPageRoute(builder: (context) => ToolView(_data[tool], tools, _config, _bible, _interfaceDialog)),
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

  ToolView(this._title, this._data, this._config, this._bible, this._interfaceDialog);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
      ),
      body: _buildItems(context),
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
        delegate: BibleSearchDelegate(context, _bible, _interfaceDialog, _config, passages));
    if (selected != null) Navigator.pop(context, selected);
  }

}

class Relationship extends StatefulWidget {
  final String _title;
  final List _data;
  final Config _config;
  final Bible _bible;
  final Map _interfaceDialog;

  Relationship(this._title, this._data, this._config, this._bible, this._interfaceDialog);

  @override
  RelationshipState createState() => RelationshipState(this._title, this._data, this._config, this._bible, this._interfaceDialog);
}

class RelationshipState extends State<Relationship> {
  String _title;
  List _data;
  final Config _config;
  final Bible _bible;
  final Map _interfaceDialog;

  RelationshipState(this._title, this._data, this._config, this._bible, this._interfaceDialog);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
      ),
      body: _buildItems(context),
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
    Icon icon = (itemData["Sex"] == "F") ? Icon(Icons.person_outline) : Icon(Icons.person);
    return ListTile(
      leading: icon,
      title: Text(itemData["Name"], style: _config.verseTextStyle["verseFont"]),
      subtitle: Text(itemData["Relationship"], style: TextStyle(fontSize: _config.fontSize - 4)),
      trailing: IconButton(
        //tooltip: interfaceBibleSettings[this.abbreviations][2],
        icon: const Icon(Icons.search),
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
        delegate: BibleSearchDelegate(context, _bible, _interfaceDialog, _config, verseData));
    if (selected != null) Navigator.pop(context, selected);
  }

}

class Timeline extends StatefulWidget {

  final String _file;
  final String _title;

  Timeline(this._file, this._title);

  @override
  TimelineState createState() => TimelineState(this._file, this._title);
}

class TimelineState extends State<Timeline> {

  final String _file;
  final String _title;

  TimelineState(this._file, this._title);

  @override
  Widget build(BuildContext context) {
    return Container(
        child: PhotoView(
          imageProvider: AssetImage("assets/timelines/$_file.png"),
        )
    );
  }

}