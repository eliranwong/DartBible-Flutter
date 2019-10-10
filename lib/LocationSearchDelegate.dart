import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'config.dart';
import 'BibleParser.dart';
import 'BibleLocations.dart';

class LocationSearchDelegate extends SearchDelegate<List> {
  List _data;
  Config _config;
  String abbreviations;
  BibleParser _parser;

  Map interface = {
    "ENG": ["Clear", "Search ", "Bible Locations"],
    "TC": ["清空", "搜索", "聖經地點"],
    "SC": ["清空", "搜索", "圣经地点"],
  };

  List locations = BibleLocations().locations;

  @override
  String get searchFieldLabel => "${interface[this.abbreviations][1]}${interface[this.abbreviations].last}";

  LocationSearchDelegate(BuildContext context, this._data, this._config) {
    this.abbreviations = _config.abbreviations;
    _parser = BibleParser(this.abbreviations);
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
    if (query.isNotEmpty)
      _data = locations.where((i) => i["Name"].contains(query)).toList();
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
          close(context, [itemData["LocationID"]]);
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
