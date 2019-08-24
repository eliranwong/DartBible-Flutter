import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter/material.dart';
import 'config.dart' as config;
import 'Bibles.dart';
import 'BibleParser.dart';

class BibleSearchDelegate extends SearchDelegate<List> {

  Bible _bible;

  final _bibleFont = const TextStyle(fontSize: config.fontSize);
  List<dynamic> _data = [];

  BibleSearchDelegate(BuildContext context, Bible bible, [List startupData]) {
    _bible = bible;
    if (startupData != null) {
      _data = startupData; // startup data to be displayed via suggestions
    }
  }

  List _fetch(query) {
    List<dynamic> fetchResults =[];
    var verseReferenceList = BibleParser().extractAllReferences(query);
    (verseReferenceList.isEmpty) ? fetchResults = _bible.directSearch(query) : fetchResults = _bible.directOpenMultipleVerses(verseReferenceList);
    return fetchResults;
  }
/*
  @override
  ThemeData appBarTheme(BuildContext context) {
    assert(context != null);
    final ThemeData theme = Theme.of(context);
    assert(theme != null);
    return theme;
  }
*/
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
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

  @override
  Widget buildResults(BuildContext context) {
    if (query.isNotEmpty) _data = _fetch(query);
    return _buildVerses(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildVerses(context);
  }

  Widget _buildVerses(BuildContext context) {
    return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _data.length,
        itemBuilder: (context, i) {
          return _buildVerseRow(i, context);
        });
  }

  Widget _buildVerseRow(int i, BuildContext context) {
    return ListTile(
      title: Text(
        _data[i][1],
        style: _bibleFont,
      ),

      onTap: () {
        close(context, _data[i]);
      },

      onLongPress: () {
        Clipboard.setData(ClipboardData(text: _data[i][1]));
        final snackBar = SnackBar(content: Text('Copied to clipboard!'));
        Scaffold.of(context).showSnackBar(snackBar);
      },

    );
  }

}