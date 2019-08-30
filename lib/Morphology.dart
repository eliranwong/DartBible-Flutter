import 'package:flutter/material.dart';

class InterlinearView extends StatelessWidget {

  // [{WordID: 1, ClauseID: 1, Book: 1, Chapter: 1, Verse: 1, Word: בְּ, LexicalEntry: E70001,H9003,, MorphologyCode: prep, Morphology: preposition,, Lexeme: בְּ, Transliteration: bĕ, Pronunciation: bᵊ, Interlinear: in, Translation: In, Gloss: in}]
  final List<Map> _data;
  InterlinearView(this._data);

  @override
  Widget build(BuildContext context) {
    final title = 'Interlinear';
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
    return Center(
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.album),
              title: Text(wordData["Word"]),
              subtitle: Text(wordData["Interlinear"]),
            )
          ],
        ),
      ),
    );
  }

}

class MorphologyView extends StatelessWidget {

  // [{WordID: 1, ClauseID: 1, Book: 1, Chapter: 1, Verse: 1, Word: בְּ, LexicalEntry: E70001,H9003,, MorphologyCode: prep, Morphology: preposition,, Lexeme: בְּ, Transliteration: bĕ, Pronunciation: bᵊ, Interlinear: in, Translation: In, Gloss: in}]
  final List<Map> _data;
  MorphologyView(this._data);

  @override
  Widget build(BuildContext context) {
    final title = 'Morphology';
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
    String morphology = wordData["Morphology"].replaceAll(",", ", ");
    morphology = morphology.substring(0, (morphology.length - 2));
    return Center(
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.album),
              title: Text(wordData["Word"]),
              subtitle: Text("${wordData["Transliteration"]} [${wordData["Pronunciation"]}]"),
            ),
            ListTile(
              leading: Icon(Icons.label_outline),
              title: Text(wordData["Lexeme"]),
              subtitle: Text(morphology),
            ),
          ],
        ),
      ),
    );
  }

}
