import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'config.dart';
import 'Helpers.dart';

class PeopleSearchDelegate extends SearchDelegate<List> {
  List _data;
  Config _config;
  String abbreviations;

  Map interface = {
    "ENG": ["Clear", "Search", "Bible People"],
    "TC": ["清空", "搜索", "聖經人物"],
    "SC": ["清空", "搜索", "圣经人物"],
  };

  @override
  String get searchFieldLabel => interface[this.abbreviations].last;

  PeopleSearchDelegate(BuildContext context, this._data, this._config) {
    this.abbreviations = _config.abbreviations;
  }

  Future _fetch(BuildContext context, String searchItem) async {
    final Database db = await SqliteHelper(_config).initToolsDb();
    var statement =
        "SELECT PersonID, Name, Sex FROM PEOPLERELATIONSHIP WHERE Name LIKE ? AND Relationship = '[Reference]'";
    _data = await db.rawQuery(statement, ['%$searchItem%']);
    db.close();
    showSuggestions(context);
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        tooltip: this.interface[this.abbreviations][0],
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  // Function triggered when "ENTER" is pressed.
  @override
  Widget buildResults(BuildContext context) {
    if (query.isNotEmpty) _fetch(context, query);
    return _buildItems(context);
  }

  // Results are displayed if _data is not empty.
  // Display of results changes as users type something in the search field.
  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildItems(context);
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
      trailing: IconButton(
        tooltip: interface[this.abbreviations][1],
        icon: Icon(
          Icons.search,
          color: _config.myColors["black"],
        ),
        onPressed: () {
          close(context, [1, itemData["PersonID"]]);
        },
      ),
      onTap: () {
        close(context, [0, itemData["PersonID"], itemData["Name"]]);
      },
    );
  }
}
