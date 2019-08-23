import 'Bibles.dart';
import 'BibleParser.dart';

class BibleSearchDelegate extends SearchDelegate {

  Bible _bible;

  final _bibleFont = const TextStyle(fontSize: 18.0);
  List<dynamic> _data = [];

  CustomSearchDelegate(Bible bible, [List startupData]) {
    _bible = bible;
    if (startupData != null) _data = startupData;
  }

  List _fetch(query) {
    List<dynamic> fetchResults =[];
    var verseReferenceList = BibleParser().extractAllReferences(query);
    (verseReferenceList.isEmpty) ? fetchResults = _bible.directSearch(query) : fetchResults = _bible.directOpenMultipleVerses(query);
    return fetchResults;
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    assert(context != null);
    final ThemeData theme = Theme.of(context);
    assert(theme != null);
    return theme;
  }

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
    return _buildVerses();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Column();
  }

  Widget _buildVerses() {
    return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _data.length,
        itemBuilder: (context, i) {
          return _buildRow(i);
        });
  }

  Widget _buildRow(int i) {
    return ListTile(
      title: Text(
        _data[i][1],
        style: _bibleFont,
      ),
    );
  }

}