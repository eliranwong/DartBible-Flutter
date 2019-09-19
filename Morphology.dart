import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'BibleParser.dart';
import 'config.dart';
import 'Helpers.dart';
import 'Bibles.dart';
import 'HtmlWrapper.dart';

class InterlinearView extends StatefulWidget {
  final List<Map> _data;
  final bool _firstOpened;
  final String _module;
  final Config _config;
  final Bibles _bibles;

  InterlinearView(
      this._data, this._firstOpened, this._module, this._config, this._bibles);

  @override
  InterlinearViewState createState() => InterlinearViewState(
      this._data, this._firstOpened, this._module, this._config, this._bibles);
}

class InterlinearViewState extends State<InterlinearView> {
  // [{WordID: 1, ClauseID: 1, Book: 1, Chapter: 1, Verse: 1, Word: בְּ, LexicalEntry: E70001,H9003,, MorphologyCode: prep, Morphology: preposition,, Lexeme: בְּ, Transliteration: bĕ, Pronunciation: bᵊ, Interlinear: in, Translation: In, Gloss: in}]
  final List<Map> _data;
  final bool _firstOpened;
  final String _module;
  final Config _config;
  final Bibles _bibles;
  double _fontSize;
  String abbreviations;
  final Map interface = {
    "ENG": ["Interlinear", "More"],
    "TC": ["原文逐字翻譯", "更多"],
    "SC": ["原文逐字翻译", "更多"],
  };

  InterlinearViewState(
      this._data, this._firstOpened, this._module, this._config, this._bibles) {
    this._fontSize = this._config.fontSize;
    this.abbreviations = this._config.abbreviations;
  }

  @override
  Widget build(BuildContext context) {
    var verseRef = "";
    if (_data.isNotEmpty)
      verseRef = BibleParser(this.abbreviations).bcvToVerseReference(
          [_data[0]["Book"], _data[0]["Chapter"], _data[0]["Verse"]]);
    final title =
        "${interface[this.abbreviations][0]} - $verseRef";
    return Theme(
      data: _config.mainTheme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: <Widget>[
            IconButton(
              tooltip: interface[this.abbreviations][1],
              icon: const Icon(Icons.unfold_more),
              onPressed: () {
                _loadMorphologyView(context);
              },
            ),
          ],
        ),
        body: _buildCardList(context),
      ),
    );
  }

  Widget _buildCardList(BuildContext context) {
    return ListView.builder(
        padding: const EdgeInsets.all(15.0),
        itemCount: _data.length,
        itemBuilder: (context, i) {
          return _buildCard(context, i);
        });
  }

  Widget _buildCard(BuildContext context, int i) {
    final wordData = _data[i];
    final textStyle = TextStyle(fontSize: (_fontSize - 2), color: _config.myColors["grey"],);
    TextStyle originalStyle = ((wordData["Book"] < 40) && (_module == "OHGB"))
        ? _config.verseTextStyle["verseFontHebrew"]
        : _config.verseTextStyle["verseFontGreek"];
    Widget word;
    word = Text(wordData["Word"], style: originalStyle);
    return Center(
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.album, color: _config.myColors["black"],),
              title: word,
              subtitle: Text(wordData["Interlinear"], style: textStyle),
              onTap: () {
                _loadLexiconView(context, wordData["LexicalEntry"]);
              },
              trailing: IconButton(
                tooltip: interface[this.abbreviations][1],
                icon: Icon(Icons.more_vert, color: _config.myColors["black"],),
                onPressed: () {
                  _loadWordView(context, wordData);
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Future _loadWordView(BuildContext context, Map wordData) async {
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              WordView(wordData, _module, _config, _bibles)),
    );
    if (selected != null) Navigator.pop(context, selected);
  }

  Future _loadMorphologyView(BuildContext context) async {
    if ((_firstOpened) && (_module != "ABP")) {
      final selected = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                MorphologyView(_data, false, _module, _config, _bibles)),
      );
      if (selected != null) Navigator.pop(context, selected);
    } else {
      Navigator.pop(context, null);
    }
  }

  Future _loadLexiconView(BuildContext context, String lexicalEntries) async {
    List lexicons = await SqliteHelper(_config).getLexicons(lexicalEntries);
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LexiconView(_config, lexicons, _bibles)),
    );
    if (selected != null) Navigator.pop(context, selected);
  }

}

class MorphologyView extends StatefulWidget {
  final List<Map> _data;
  final bool _firstOpened;
  final String _module;
  final Config _config;
  final Bibles _bibles;

  MorphologyView(
      this._data, this._firstOpened, this._module, this._config, this._bibles);

  @override
  MorphologyViewState createState() => MorphologyViewState(
      this._data, this._firstOpened, this._module, this._config, this._bibles);
}

class MorphologyViewState extends State<MorphologyView> {
  // [{WordID: 1, ClauseID: 1, Book: 1, Chapter: 1, Verse: 1, Word: בְּ, LexicalEntry: E70001,H9003,, MorphologyCode: prep, Morphology: preposition,, Lexeme: בְּ, Transliteration: bĕ, Pronunciation: bᵊ, Interlinear: in, Translation: In, Gloss: in}]
  final List<Map> _data;
  final bool _firstOpened;
  final String _module;
  final Config _config;
  final Bibles _bibles;
  double _fontSize;
  String abbreviations;
  final Map interface = {
    "ENG": ["Morphology", "Less", "Search", "More"],
    "TC": ["原文形態學", "翻譯", "搜索", "更多"],
    "SC": ["原文形态学", "翻译", "搜索", "更多"],
  };

  MorphologyViewState(
      this._data, this._firstOpened, this._module, this._config, this._bibles) {
    this._fontSize = this._config.fontSize;
    this.abbreviations = this._config.abbreviations;
  }

  Future searchMorphology(BuildContext context, String lexicalEntry,
      List selectedMorphologyItems) async {
    if (lexicalEntry.isNotEmpty) {
      final Database db = await SqliteHelper(this._config).initMorphologyDb();
      String statement;
      String prefix =
          "SELECT * FROM $_module WHERE LexicalEntry LIKE '%$lexicalEntry,%'";
      if (selectedMorphologyItems.isEmpty) {
        statement = prefix;
      } else {
        List<String> statementItems = selectedMorphologyItems
            .map<String>((i) => "AND Morphology LIKE '%$i,%'")
            .toList()
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
      MaterialPageRoute(
          builder: (context) => MorphologySearchResults(
              morphology, this._module, this._config, this._bibles)),
    );
    if (selected != null) Navigator.pop(context, selected);
  }

  @override
  Widget build(BuildContext context) {
    var verseRef = "";
    if (_data.isNotEmpty)
      verseRef = BibleParser(this.abbreviations).bcvToVerseReference(
          [_data[0]["Book"], _data[0]["Chapter"], _data[0]["Verse"]]);
    final title =
        "${interface[this.abbreviations][0]} - $verseRef";
    return Theme(
      data: _config.mainTheme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: <Widget>[
            IconButton(
              tooltip: interface[this.abbreviations][1],
              icon: const Icon(Icons.unfold_less),
              onPressed: () {
                if (_firstOpened) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => InterlinearView(
                            _data, false, _module, _config, _bibles)),
                  );
                } else {
                  Navigator.pop(context, null);
                }
              },
            ),
          ],
        ),
        body: _buildCardList(context),
      ),
    );
  }

  Widget _buildCardList(BuildContext context) {
    return ListView.builder(
        padding: const EdgeInsets.all(15.0),
        itemCount: _data.length,
        itemBuilder: (context, i) {
          return _buildCard(context, i);
        });
  }

  Widget _buildCard(BuildContext context, int i) {
    final wordData = _data[i];
    String morphology = wordData["Morphology"].replaceAll(",", ", ");
    morphology = morphology.substring(0, (morphology.length - 2));
    final textStyle = TextStyle(fontSize: (_fontSize - 2), color: _config.myColors["grey"],);
    TextStyle originalStyle = ((wordData["Book"] < 40) && (_module == "OHGB"))
        ? _config.verseTextStyle["verseFontHebrew"]
        : _config.verseTextStyle["verseFontGreek"];
    String lexemeText = wordData["Lexeme"];
    Widget word = Text(wordData["Word"], style: originalStyle);
    Widget lexeme = Text(lexemeText, style: originalStyle);
    String lexicalEntry = "";
    if (wordData["LexicalEntry"].isNotEmpty)
      lexicalEntry = wordData["LexicalEntry"].split(",").toList()[0];
    return Center(
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.album, color: _config.myColors["black"],),
              title: word,
              subtitle: Text(
                  "${wordData["Transliteration"]} [${wordData["Pronunciation"]}]",
                  style: textStyle),
              onTap: () {
                _loadLexiconView(context, wordData["LexicalEntry"]);
              },
              trailing: IconButton(
                tooltip: interface[this.abbreviations][3],
                icon: Icon(Icons.more_vert, color: _config.myColors["black"],),
                onPressed: () {
                  _loadWordView(context, wordData);
                },
              ),
            ),
            ListTile(
              leading: Icon(Icons.label_outline, color: _config.myColors["black"],),
              title: lexeme,
              subtitle: Text(morphology, style: textStyle),
              onTap: () {
                searchMorphology(context, lexicalEntry, morphology.split(", "));
              },
              trailing: IconButton(
                tooltip: interface[this.abbreviations][2],
                icon: Icon(Icons.search, color: _config.myColors["black"],),
                onPressed: () {
                  _loadMorphologySearchView(context, lexemeText,
                      wordData["LexicalEntry"], morphology);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future _loadWordView(BuildContext context, Map wordData) async {
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              WordView(wordData, _module, _config, _bibles)),
    );
    if (selected != null) Navigator.pop(context, selected);
  }

  Future _loadMorphologySearchView(
      BuildContext context, lexemeText, lexicalEntry, morphology) async {
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => MorphologySearchView(lexemeText, lexicalEntry,
              morphology, this._module, this._config, this._bibles)),
    );
    if (selected != null) Navigator.pop(context, selected);
  }

  Future _loadLexiconView(BuildContext context, String lexicalEntries) async {
    List lexicons = await SqliteHelper(_config).getLexicons(lexicalEntries);
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LexiconView(_config, lexicons, _bibles)),
    );
    if (selected != null) Navigator.pop(context, selected);
  }
}

class MorphologySearchView extends StatefulWidget {
  final String _lexeme, _lexicalEntry, _morphology, _module;
  final Config _config;
  final Bibles _bibles;

  MorphologySearchView(this._lexeme, this._lexicalEntry, this._morphology,
      this._module, this._config, this._bibles);

  @override
  MorphologySearchViewState createState() => MorphologySearchViewState(
      this._lexeme,
      this._lexicalEntry,
      this._morphology,
      this._module,
      this._config,
      this._bibles);
}

class MorphologySearchViewState extends State<MorphologySearchView> {
  final String _lexeme, _lexicalEntry, _morphology, _module;
  final Config _config;
  final Bibles _bibles;
  var lexicalEntry = "";
  List<String> morphologyItems, selectedMorphologyItems;

  final Map interface = {
    "ENG": ["Search"],
    "TC": ["搜索"],
    "SC": ["翻译"],
  };

  MorphologySearchViewState(this._lexeme, this._lexicalEntry, this._morphology,
      this._module, this._config, this._bibles) {
    morphologyItems = _morphology.split(", ").toList();
    selectedMorphologyItems = List<String>.from(morphologyItems);
    if (_lexicalEntry.isNotEmpty)
      this.lexicalEntry = _lexicalEntry.split(",").toList()[0];
  }

  Future searchMorphology(BuildContext context) async {
    final Database db = await SqliteHelper(this._config).initMorphologyDb();
    String statement;
    String prefix =
        "SELECT * FROM $_module WHERE LexicalEntry LIKE '%$lexicalEntry,%'";
    if (selectedMorphologyItems.isEmpty) {
      statement = prefix;
    } else {
      List<String> statementItems = selectedMorphologyItems
          .map<String>((i) => "AND Morphology LIKE '%$i,%'")
          .toList()
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
      MaterialPageRoute(
          builder: (context) => MorphologySearchResults(
              morphology, this._module, this._config, this._bibles)),
    );
    if (selected != null) Navigator.pop(context, selected);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _config.mainTheme,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Search"),
          actions: <Widget>[
            IconButton(
              tooltip: interface[_config.abbreviations][0],
              icon: const Icon(Icons.search),
              onPressed: () {
                searchMorphology(context);
              },
            ),
          ],
        ),
        body: _buildMorphology(context),
      ),
    );
  }

  Widget _buildMorphology(BuildContext context) {
    List<Widget> morphologyItemList =
        morphologyItems.map((i) => _buildMorphologyRow(i)).toList();
    return ListView(children: <Widget>[
      ListTile(
        title: Text(_lexeme, style: TextStyle(color: _config.myColors["black"]),),
        subtitle: Text(lexicalEntry, style: TextStyle(color: _config.myColors["grey"]),),
      ),
      ExpansionTile(
        title: Text("+"),
        initiallyExpanded: true,
        backgroundColor: Theme.of(context).accentColor.withOpacity(0.025),
        children: morphologyItemList,
      ),
    ]);
  }

  Widget _buildMorphologyRow(String item) {
    return CheckboxListTile(
        title: Text(item, style: TextStyle(color: _config.myColors["black"]),),
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
  final Bibles _bibles;

  MorphologySearchResults(this._data, this._module, this._config, this._bibles);

  @override
  MorphologySearchResultsState createState() => MorphologySearchResultsState(
      this._data, this._module, this._config, this._bibles);
}

class MorphologySearchResultsState extends State<MorphologySearchResults> {
  // [{WordID: 1, ClauseID: 1, Book: 1, Chapter: 1, Verse: 1, Word: בְּ, LexicalEntry: E70001,H9003,, MorphologyCode: prep, Morphology: preposition,, Lexeme: בְּ, Transliteration: bĕ, Pronunciation: bᵊ, Interlinear: in, Translation: In, Gloss: in}]
  final List<Map> _data;
  final String _module;
  final Config _config;
  final Bibles _bibles;
  double _fontSize;
  String abbreviations;
  final Map interface = {
    "ENG": ["Found", "words", "More"],
    "TC": ["找到", "個字", "更多"],
    "SC": ["找到", "个字", "更多"],
  };

  MorphologySearchResultsState(
      this._data, this._module, this._config, this._bibles) {
    this._fontSize = this._config.fontSize;
    this.abbreviations = this._config.abbreviations;
  }

  @override
  Widget build(BuildContext context) {
    final title =
        "${interface[this.abbreviations][0]} ${_data.length} ${interface[this.abbreviations][1]}";
    return Theme(
      data: _config.mainTheme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: _buildCardList(context),
      ),
    );
  }

  Widget _buildCardList(BuildContext context) {
    return ListView.builder(
        padding: const EdgeInsets.all(15.0),
        itemCount: _data.length,
        itemBuilder: (context, i) {
          return _buildCard(context, i);
        });
  }

  Widget _buildCard(BuildContext context, int i) {
    final wordData = _data[i];
    final textStyle = TextStyle(fontSize: (_fontSize - 2), color: _config.myColors["grey"],);
    TextStyle originalStyle = ((wordData["Book"] < 40) && (_module == "OHGB"))
        ? _config.verseTextStyle["verseFontHebrew"]
        : _config.verseTextStyle["verseFontGreek"];
    Widget word = Text(wordData["Word"], style: originalStyle);
    var bcvList = [wordData["Book"], wordData["Chapter"], wordData["Verse"]];
    String verseReference =
        BibleParser(this.abbreviations).bcvToVerseReference(bcvList);
    return Center(
      child: Card(
        child: Container(
          color: Colors.grey[_config.backgroundColor + 100],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.album, color: _config.myColors["black"],),
                title: word,
                subtitle: Text(verseReference, style: textStyle),
                onTap: () {
                  Navigator.pop(context, [bcvList, "", _bibles.bible1.module]);
                },
                trailing: IconButton(
                  tooltip: interface[this.abbreviations][2],
                  icon: Icon(Icons.more_vert, color: _config.myColors["black"],),
                  onPressed: () {
                    _loadWordView(context, wordData);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future _loadWordView(BuildContext context, Map wordData) async {
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              WordView(wordData, _module, _config, _bibles)),
    );
    if (selected != null) Navigator.pop(context, selected);
  }

}

class WordView extends StatelessWidget {
  final Map _data;
  final String _module;
  final Config _config;
  final Bibles _bibles;

  WordView(this._data, this._module, this._config, this._bibles);

  @override
  Widget build(BuildContext context) {
    TextSpan originalWord = ((_module == "OHGB") && (_data["Book"] < 40)) ? TextSpan(text: _data["Word"], style: TextStyle(fontFamily: "Ezra SIL", fontSize: 22.0)) : TextSpan(text: _data["Word"], style: TextStyle(fontSize: 22.0));
    Widget title = RichText(text: TextSpan(children: <TextSpan>[TextSpan(text: "[${BibleParser(_config.abbreviations).bcvToVerseReference([_data["Book"], _data["Chapter"], _data["Verse"]])}] ", style: TextStyle(fontSize: 18.0)), originalWord]));
    return Theme(
      data: _config.mainTheme,
      child: Scaffold(
        appBar: AppBar(
          title: title,
        ),
        body: _buildKeys(context),
      ),
    );
  }

  Widget _buildKeys(BuildContext context) {
    Text originalWord = ((_module == "OHGB") && (_data["Book"] < 40)) ? Text(_data["Word"], style: _config.verseTextStyle["verseFontHebrew"]) : Text(_data["Word"], style: _config.verseTextStyle["verseFontGreek"]);

    List bcvList = [_data["Book"], _data["Chapter"], _data["Verse"]];

    List<Bible> bibleList = [_bibles.bible1, _bibles.bible2, _bibles.iBible];
    List<Widget> verseList = bibleList
        .map((bible) => _buildVerseRow(context, bible.openSingleVerse(bcvList),
            bible.module, bcvList))
        .toList();

    List<String> keys = _data.keys.toList();
    List<Widget> dataList =
        keys.map((key) => _buildKeyRow(context, key)).toList();

    return ListView(children: <Widget>[
      ExpansionTile(
        title: Text(BibleParser(_config.abbreviations).bcvToVerseReference(bcvList), style: TextStyle(color: _config.myColors["black"],),),
        initiallyExpanded: false,
        backgroundColor: Theme.of(context).accentColor.withOpacity(0.025),
        children: verseList,
      ),
      ExpansionTile(
        title: originalWord,
        initiallyExpanded: true,
        backgroundColor: Theme.of(context).accentColor.withOpacity(0.025),
        children: dataList,
      ),
    ]);
  }

  Widget _buildVerseRow(BuildContext context, String text, String module, List bcvList) {
    int book = bcvList[0];
    bool isHebrewBible =
        ((_config.hebrewBibles.contains(module)) && (book < 40));
    TextDirection verseDirection =
        isHebrewBible ? TextDirection.rtl : TextDirection.ltr;
    TextStyle verseFont;
    if (isHebrewBible) {
      verseFont = _config.verseTextStyle["verseFontHebrew"];
    } else if (_config.greekBibles.contains(module)) {
      verseFont = _config.verseTextStyle["verseFontGreek"];
    } else {
      verseFont = _config.verseTextStyle["verseFont"];
    }
    List<TextSpan> wordSpans = (_config.interlinearBibles.contains(module))
        ? InterlinearHelper(_config.verseTextStyle)
            .getInterlinearSpan(text, book)
        : <TextSpan>[TextSpan(text: text, style: verseFont)];
    return ListTile(
      title: RichText(
        text: TextSpan(
          //style: DefaultTextStyle.of(context).style,
          children: wordSpans,
        ),
        textDirection: verseDirection,
      ),
      subtitle: Text("[$module]", style: TextStyle(color: _config.myColors["blue"],),),
      onTap: () {
        Navigator.pop(context, [bcvList, "", module]);
      },
    );
  }

  Widget _buildKeyRow(BuildContext context, String key) {
    TextStyle titleStyle =
        TextStyle(fontSize: (this._config.fontSize - 4), color: Colors.grey);
    TextStyle dataStyle = _config.verseTextStyle["verseFont"];
    if ((key == "Word") || (key == "Lexeme"))
      dataStyle = _config.verseTextStyle["verseFontGreek"];
    if (((_module == "OHGB") && (_data["Book"] < 40)) &&
        ((key == "Word") || (key == "Lexeme")))
      dataStyle = _config.verseTextStyle["verseFontHebrew"];
    String data = _data[key].toString();
    if (data.contains(","))
      data = data.split(",").sublist(0, data.split(",").length - 1).join(", ");
    return ListTile(
      title: Text(key, style: titleStyle),
      subtitle: Text(data, style: dataStyle),
    );
  }

}

/*
class LexiconView extends StatefulWidget {
  final List _lexicalEntries;
  final Config _config;
  final Bibles _bibles;

  LexiconView(this._config, this._lexicalEntries, this._bibles);

  @override
  LexiconViewState createState() => LexiconViewState(this._config, this._lexicalEntries, this._bibles);
}

class LexiconViewState extends State<LexiconView> {

  final List _lexicalEntries;
  final Config _config;
  final Bibles _bibles;

  Map interface = {
    "ENG": ["Lexicon"],
    "TC": ["原文辭典"],
    "SC": ["原文词典"],
  };

  LexiconViewState(this._config, this._lexicalEntries, this._bibles);
*/
class LexiconView extends StatelessWidget {

  final List _lexicalEntries;
  final Config _config;
  final Bibles _bibles;

  Map interface = {
    "ENG": ["Lexicon"],
    "TC": ["原文辭典"],
    "SC": ["原文词典"],
  };

  LexiconView(this._config, this._lexicalEntries, this._bibles);

  List<Widget> formatItem(BuildContext context, Map item) {
    HtmlWrapper _wrapper = HtmlWrapper(_bibles, _config);

    //String _entry = item["Entry"];
    String _lexeme = item["Lexeme"];
    String _transliteration = item["Transliteration"];
    String _morphology = item["Morphology"];
    String _gloss = item["Gloss"];
    String _lexicon = item["Lexicon"];
    String _content = item["Content"];

    Widget headingRichText = Text(_lexicon, style: TextStyle(color: _config.myColors["grey"]),);

    String content = "<h>$_lexeme</h><p>Transliteration: $_transliteration<br>Morphology: $_morphology<br>Gloss: $_gloss</p><p>$_content</p>";
    Widget contentRichText = _wrapper.buildRichText(context, content);

    return [headingRichText, contentRichText];
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _config.mainTheme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(interface[_config.abbreviations][0]),
        ),
        body: _buildCardList(context),
      ),
    );
  }

  Widget _buildCardList(BuildContext context) {
    return ListView.builder(
        padding: const EdgeInsets.all(15.0),
        itemCount: _lexicalEntries.length,
        itemBuilder: (context, i) {
          return _buildCard(context, i);
        });
  }

  Widget _buildCard(BuildContext context, int i) {
    final wordItem = _lexicalEntries[i];
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
