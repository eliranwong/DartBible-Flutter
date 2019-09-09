import 'package:flutter/material.dart';
import 'package:unique_bible_app/BibleParser.dart';
import 'package:unique_bible_app/config.dart';
import 'package:unique_bible_app/Helpers.dart';
import 'package:sqflite/sqflite.dart';

class InterlinearView extends StatefulWidget {

  final List<Map> _data;
  final bool _firstOpened;
  final String _module;
  final Config _config;

  InterlinearView(this._data, this._firstOpened, this._module, this._config);

  @override
  InterlinearViewState createState() => InterlinearViewState(this._data, this._firstOpened, this._module, this._config);

}

class InterlinearViewState extends State<InterlinearView> {

  // [{WordID: 1, ClauseID: 1, Book: 1, Chapter: 1, Verse: 1, Word: בְּ, LexicalEntry: E70001,H9003,, MorphologyCode: prep, Morphology: preposition,, Lexeme: בְּ, Transliteration: bĕ, Pronunciation: bᵊ, Interlinear: in, Translation: In, Gloss: in}]
  final List<Map> _data;
  final bool _firstOpened;
  final String _module;
  final Config _config;
  double _fontSize;
  String abbreviations;
  final Map interfaceBibleSettings = {
    "ENG": ["Interlinear", "More"],
    "TC": ["原文逐字翻譯", "更多"],
    "SC": ["原文逐字翻译", "更多"],
  };

  InterlinearViewState(this._data, this._firstOpened, this._module, this._config) {
    this._fontSize = this._config.fontSize;
    this.abbreviations = this._config.abbreviations;
  }

  @override
  Widget build(BuildContext context) {
    var verseRef = "";
    if (_data.isNotEmpty) verseRef = BibleParser(this.abbreviations).bcvToVerseReference([_data[0]["Book"], _data[0]["Chapter"], _data[0]["Verse"]]);
    final title = "${interfaceBibleSettings[this.abbreviations][0]} - $verseRef";
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: <Widget>[
          IconButton(
            tooltip: interfaceBibleSettings[this.abbreviations][1],
            icon: const Icon(Icons.unfold_more),
            onPressed: () {
              _loadMorphologyView(context);
            },
          ),
        ],
      ),
      body: _buildCardList(context),
    );
  }

  Widget _buildCardList(BuildContext context) {
    return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _data.length,
        itemBuilder: (context, i) {
          return _buildCard(context, i);
        });
  }

  Widget _buildCard(BuildContext context, int i) {
    final wordData = _data[i];
    final textStyle = TextStyle(fontSize: (_fontSize - 2));
    final textStyleHebrew = TextStyle(fontFamily: "Ezra SIL", fontSize: (_fontSize + 4));
    final textStyleGreek = TextStyle(fontSize: (_fontSize + 2));
    Widget word;
    if ((wordData["Book"] < 40) && (_module == "OHGB")) {
      word = Text(wordData["Word"], style: textStyleHebrew);
    } else {
      word = Text(wordData["Word"], style: textStyleGreek);
    }
    return Center(
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.album),
              title: word,
              subtitle: Text(wordData["Interlinear"], style: textStyle),
              onTap: () {
                _loadLexiconView(context);
              },
              trailing: IconButton(
                //tooltip: interfaceBibleSettings[this.abbreviations][2],
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WordView(wordData)),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Future _loadMorphologyView(BuildContext context) async {
    if ((_firstOpened) && (_module != "ABP")) {
      final selected = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MorphologyView(_data, false, _module, _config)),
      );
      if (selected != null) Navigator.pop(context, selected);
    } else {
      Navigator.pop(context, null);
    }
  }

  Future _loadLexiconView(BuildContext context) async {
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LexiconView()),
    );
    if (selected != null) Navigator.pop(context, selected);
  }

}

class MorphologyView extends StatefulWidget {

  final List<Map> _data;
  final bool _firstOpened;
  final String _module;
  final Config _config;

  MorphologyView(this._data, this._firstOpened, this._module, this._config);

  @override
  MorphologyViewState createState() => MorphologyViewState(this._data, this._firstOpened, this._module, this._config);

}

class MorphologyViewState extends State<MorphologyView> {

  // [{WordID: 1, ClauseID: 1, Book: 1, Chapter: 1, Verse: 1, Word: בְּ, LexicalEntry: E70001,H9003,, MorphologyCode: prep, Morphology: preposition,, Lexeme: בְּ, Transliteration: bĕ, Pronunciation: bᵊ, Interlinear: in, Translation: In, Gloss: in}]
  final List<Map> _data;
  final bool _firstOpened;
  final String _module;
  final Config _config;
  double _fontSize;
  String abbreviations;
  final Map interfaceBibleSettings = {
    "ENG": ["Morphology", "Less", "Search"],
    "TC": ["原文形態學", "翻譯", "搜索"],
    "SC": ["原文形态学", "翻译", "搜索"],
  };

  MorphologyViewState(this._data, this._firstOpened, this._module, this._config) {
    this._fontSize = this._config.fontSize;
    this.abbreviations = this._config.abbreviations;
  }

  Future searchMorphology(BuildContext context, String lexicalEntry, List selectedMorphologyItems) async {
    if (lexicalEntry.isNotEmpty) {
      final Database db = await SqliteHelper(this._config).initMorphologyDb();
      String statement;
      String prefix = "SELECT * FROM $_module WHERE LexicalEntry LIKE '%$lexicalEntry,%'";
      if (selectedMorphologyItems.isEmpty) {
        statement = prefix;
      } else {
        List<String> statementItems = selectedMorphologyItems.map<String>((i) => "AND Morphology LIKE '%$i,%'").toList()
          ..insert(0, prefix);
        statement = statementItems.join(" ");
      }
      List<Map> morphology = await db.rawQuery(statement);
      _morphologySearchResults(context, morphology);
      db.close();
    }
  }

  Future _morphologySearchResults(BuildContext context, List morphology) async {
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MorphologySearchResults(morphology, this._module, this._config)),
    );
    if (selected != null) Navigator.pop(context, selected);
  }

  @override
  Widget build(BuildContext context) {
    var verseRef = "";
    if (_data.isNotEmpty) verseRef = BibleParser(this.abbreviations).bcvToVerseReference([_data[0]["Book"], _data[0]["Chapter"], _data[0]["Verse"]]);
    final title = "${interfaceBibleSettings[this.abbreviations][0]} - $verseRef";
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: <Widget>[
          IconButton(
            tooltip: interfaceBibleSettings[this.abbreviations][1],
            icon: const Icon(Icons.unfold_less),
            onPressed: () {
              if (_firstOpened) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => InterlinearView(_data, false, _module, _config)),
                );
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: _buildCardList(context),
    );
  }

  Widget _buildCardList(BuildContext context) {
    return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _data.length,
        itemBuilder: (context, i) {
          return _buildCard(context, i);
        });
  }

  Widget _buildCard(BuildContext context, int i) {
    final wordData = _data[i];
    String morphology = wordData["Morphology"].replaceAll(",", ", ");
    morphology = morphology.substring(0, (morphology.length - 2));
    final textStyle = TextStyle(fontSize: (_fontSize - 2));
    final textStyleHebrew = TextStyle(fontFamily: "Ezra SIL", fontSize: (_fontSize + 4));
    final textStyleGreek = TextStyle(fontSize: (_fontSize + 2));
    String wordText = wordData["Word"];
    String lexemeText = wordData["Lexeme"];
    Widget word, lexeme;
    if ((wordData["Book"] < 40) && (_module == "OHGB")) {
      word = Text(wordText, style: textStyleHebrew);
      lexeme = Text(lexemeText, style: textStyleHebrew);
    } else {
      word = Text(wordText, style: textStyleGreek);
      lexeme = Text(lexemeText, style: textStyleGreek);
    }
    String lexicalEntry = "";
    if (wordData["LexicalEntry"].isNotEmpty) lexicalEntry = wordData["LexicalEntry"].split(",").toList()[0];
    return Center(
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.album),
              title: word,
              subtitle: Text("${wordData["Transliteration"]} [${wordData["Pronunciation"]}]", style: textStyle),
              onTap: () {
                _loadLexiconView(context);
              },
              trailing: IconButton(
                tooltip: interfaceBibleSettings[this.abbreviations][2],
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WordView(wordData)),
                  );
                },
              ),
            ),
            ListTile(
              leading: Icon(Icons.label_outline),
              title: lexeme,
              subtitle: Text(morphology, style: textStyle),
              onTap: () {
                searchMorphology(context, lexicalEntry, morphology.split(", "));
              },
              trailing: IconButton(
                tooltip: interfaceBibleSettings[this.abbreviations][2],
                icon: const Icon(Icons.search),
                onPressed: () {
                  _loadMorphologySearchView(context, lexemeText, wordData["LexicalEntry"], morphology);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future _loadMorphologySearchView(BuildContext context, lexemeText, lexicalEntry, morphology) async {
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MorphologySearchView(lexemeText, lexicalEntry, morphology, this._module, this._config)),
    );
    if (selected != null) Navigator.pop(context, selected);
  }

  Future _loadLexiconView(BuildContext context) async {
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LexiconView()),
    );
    if (selected != null) Navigator.pop(context, selected);
  }

}

class LexiconView extends StatelessWidget {

  //final _parser = HtmlWrapper("ENG", 20.0);
  /*final String testing = '''
  <h1>testing</h1><ref onclick="bcv(43,3,16)">TEST</ref>testing
  ''';

   */

  @override
  Widget build(BuildContext context) {
    final title = 'Lexicon';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        //The following line is created for testing only.
        //child: _parser.buildRichText(context, _parser.convertHtmlText(testing)),
        child: Text("This page is reserved for lexical studies.\n\nLexicons will be available next version."),
    )
    );
  }

}

class MorphologySearchView extends StatefulWidget {

  final String _lexeme, _lexicalEntry, _morphology, _module;
  final Config _config;

  MorphologySearchView(this._lexeme, this._lexicalEntry, this._morphology, this._module, this._config);

  @override
  MorphologySearchViewState createState() => MorphologySearchViewState(this._lexeme, this._lexicalEntry, this._morphology, this._module, this._config);

}

class MorphologySearchViewState extends State<MorphologySearchView> {

  final String _lexeme, _lexicalEntry, _morphology, _module;
  final Config _config;
  var lexicalEntry = "";
  List<String> morphologyItems, selectedMorphologyItems;

  MorphologySearchViewState(this._lexeme, this._lexicalEntry, this._morphology, this._module, this._config) {
    morphologyItems = _morphology.split(", ").toList();
    selectedMorphologyItems = List<String>.from(morphologyItems);
    if (_lexicalEntry.isNotEmpty) this.lexicalEntry = _lexicalEntry.split(",").toList()[0];
  }

  Future searchMorphology(BuildContext context) async {
    final Database db = await SqliteHelper(this._config).initMorphologyDb();
    String statement;
    String prefix = "SELECT * FROM $_module WHERE LexicalEntry LIKE '%$lexicalEntry,%'";
    if (selectedMorphologyItems.isEmpty) {
      statement = prefix;
    } else {
      List<String> statementItems = selectedMorphologyItems.map<String>((i) => "AND Morphology LIKE '%$i,%'").toList()
      ..insert(0, prefix);
      statement = statementItems.join(" ");
    }
    List<Map> morphology = await db.rawQuery(statement);
    _morphologySearchResults(context, morphology);
    db.close();
  }

  Future _morphologySearchResults(BuildContext context, List morphology) async {
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MorphologySearchResults(morphology, this._module, this._config)),
    );
    if (selected != null) Navigator.pop(context, selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Search"),
        actions: <Widget>[
          IconButton(
            tooltip: 'Save',
            icon: const Icon(Icons.search),
            onPressed: () {
              searchMorphology(context);
            },
          ),
        ],
      ),
      body: _buildMorphology(context),
    );
  }

  Widget _buildMorphology(BuildContext context) {
    List<Widget> morphologyItemList = morphologyItems.map((i) => _buildMorphologyRow(i)).toList();
    return ListView(
        children: <Widget>[
          ListTile(
            title: Text(_lexeme),
            subtitle: Text(lexicalEntry),
          ),
          ExpansionTile(
            title: Text("+"),
            initiallyExpanded: true,
            backgroundColor: Theme.of(context).accentColor.withOpacity(0.025),
            children: morphologyItemList,
          ),
        ]
    );
  }

  Widget _buildMorphologyRow(String item) {
    return CheckboxListTile(
        title: Text(item),
        value: (selectedMorphologyItems.contains(item)),
        onChanged: (bool value) {
          setState(() {
            if (value) {
              selectedMorphologyItems.add(item);
            } else {
              var index = selectedMorphologyItems.indexOf(item);
              selectedMorphologyItems.removeAt(index);
            }
          });
        });
  }

}

class MorphologySearchResults extends StatefulWidget {

  final List<Map> _data;
  final String _module;
  final Config _config;

  MorphologySearchResults(this._data, this._module, this._config);

  @override
  MorphologySearchResultsState createState() => MorphologySearchResultsState(this._data, this._module, this._config);

}

class MorphologySearchResultsState extends State<MorphologySearchResults> {

  // [{WordID: 1, ClauseID: 1, Book: 1, Chapter: 1, Verse: 1, Word: בְּ, LexicalEntry: E70001,H9003,, MorphologyCode: prep, Morphology: preposition,, Lexeme: בְּ, Transliteration: bĕ, Pronunciation: bᵊ, Interlinear: in, Translation: In, Gloss: in}]
  final List<Map> _data;
  final String _module;
  final Config _config;
  double _fontSize;
  String abbreviations;
  final Map interfaceBibleSettings = {
    "ENG": ["Found", "words", "More"],
    "TC": ["找到", "個字", "更多"],
    "SC": ["找到", "个字", "更多"],
  };

  MorphologySearchResultsState(this._data, this._module, this._config) {
    this._fontSize = this._config.fontSize;
    this.abbreviations = this._config.abbreviations;
  }

  @override
  Widget build(BuildContext context) {
    final title = "${interfaceBibleSettings[this.abbreviations][0]} ${_data.length} ${interfaceBibleSettings[this.abbreviations][1]}";
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: _buildCardList(context),
    );
  }

  Widget _buildCardList(BuildContext context) {
    return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _data.length,
        itemBuilder: (context, i) {
          return _buildCard(context, i);
        });
  }

  Widget _buildCard(BuildContext context, int i) {
    final wordData = _data[i];
    final textStyle = TextStyle(fontSize: (_fontSize - 2));
    final textStyleHebrew = TextStyle(fontFamily: "Ezra SIL", fontSize: (_fontSize + 4));
    final textStyleGreek = TextStyle(fontSize: (_fontSize + 2));
    Widget word;
    if ((wordData["Book"] < 40) && (_module == "OHGB")) {
      word = Text(wordData["Word"], style: textStyleHebrew);
    } else {
      word = Text(wordData["Word"], style: textStyleGreek);
    }
    var bcvList = [wordData["Book"], wordData["Chapter"], wordData["Verse"]];
    String verseReference = BibleParser(this.abbreviations).bcvToVerseReference(bcvList);
    return Center(
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.album),
              title: word,
              subtitle: Text(verseReference, style: textStyle),
              onTap: () {
                Navigator.pop(context, bcvList);
              },
              trailing: IconButton(
                //tooltip: interfaceBibleSettings[this.abbreviations][2],
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WordView(wordData)),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

}

class WordView extends StatelessWidget {

  final Map _data;

  WordView(this._data);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(_data["Word"]),
        ),
        body: _buildKeys(context),
    );
  }

  Widget _buildKeys(BuildContext context) {
    List<String> keys = _data.keys.toList();
    return ListView.builder(
        padding: const EdgeInsets.all(20.0),
        itemCount: keys.length,
        itemBuilder: (context, i) {
          return _buildKeyRow(i, context, keys);
        });
  }

  Widget _buildKeyRow(int i, BuildContext context, List keys) {
    String key = keys[i];
    return ListTile(
      title: Text(key),
      subtitle: Text(_data[key].toString()),

      /*
      onTap: () {
        //
      },

      onLongPress: () {
        //
      },
      */

    );
  }

}