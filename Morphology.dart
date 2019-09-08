import 'package:flutter/material.dart';
import 'package:unique_bible_app/BibleParser.dart';
//import 'package:unique_bible_app/HtmlWrapper.dart';

class InterlinearView extends StatelessWidget {

  // [{WordID: 1, ClauseID: 1, Book: 1, Chapter: 1, Verse: 1, Word: בְּ, LexicalEntry: E70001,H9003,, MorphologyCode: prep, Morphology: preposition,, Lexeme: בְּ, Transliteration: bĕ, Pronunciation: bᵊ, Interlinear: in, Translation: In, Gloss: in}]
  final List<Map> _data;
  final bool _firstOpened;
  final double _fontSize;
  final String abbreviations;
  final String _module;
  final Map interfaceBibleSettings = {
    "ENG": ["Interlinear", "More"],
    "TC": ["原文逐字翻譯", "更多"],
    "SC": ["原文逐字翻译", "更多"],
  };

  InterlinearView(this._data, this._firstOpened, this.abbreviations, this._fontSize, this._module);

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
              if ((_firstOpened) && (_module != "ABP")) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MorphologyView(_data, false, this.abbreviations, _fontSize, _module)),
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
            )
          ],
        ),
      ),
    );
  }

  Future _loadLexiconView(BuildContext context) async {
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LexiconView()),
    );
    if (selected != null) Navigator.pop(context, selected);
  }

}

class MorphologyView extends StatelessWidget {

  // [{WordID: 1, ClauseID: 1, Book: 1, Chapter: 1, Verse: 1, Word: בְּ, LexicalEntry: E70001,H9003,, MorphologyCode: prep, Morphology: preposition,, Lexeme: בְּ, Transliteration: bĕ, Pronunciation: bᵊ, Interlinear: in, Translation: In, Gloss: in}]
  final List<Map> _data;
  final bool _firstOpened;
  final double _fontSize;
  final String abbreviations;
  final String _module;
  final Map interfaceBibleSettings = {
    "ENG": ["Morphology", "Less", "Search"],
    "TC": ["原文形態學", "翻譯", "搜索"],
    "SC": ["原文形态学", "翻译", "搜索"],
  };
  MorphologyView(this._data, this._firstOpened, this.abbreviations, this._fontSize, this._module);

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
                  MaterialPageRoute(builder: (context) => InterlinearView(_data, false, this.abbreviations, _fontSize, _module)),
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
    Widget word, lexeme;
    if ((wordData["Book"] < 40) && (_module == "OHGB")) {
      word = Text(wordData["Word"], style: textStyleHebrew);
      lexeme = Text(wordData["Lexeme"], style: textStyleHebrew);
    } else {
      word = Text(wordData["Word"], style: textStyleGreek);
      lexeme = Text(wordData["Lexeme"], style: textStyleGreek);
    }
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
            ),
            ListTile(
              leading: Icon(Icons.label_outline),
              title: lexeme,
              subtitle: Text(morphology, style: textStyle),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MorphologySearchView()),
                );
              },
              trailing: IconButton(
                tooltip: interfaceBibleSettings[this.abbreviations][2],
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MorphologySearchView()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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

class MorphologySearchView extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final title = 'Search Morphology';
    return Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: Center(
          child: Text("This page is reserved for searching morphology.\n\nThis feature will be available next version."),
        )
    );
  }

}