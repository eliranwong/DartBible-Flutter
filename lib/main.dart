// Copyright 2019 Eliran Wong. All rights reserved.

import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter/material.dart';
import 'package:indexed_list_view/indexed_list_view.dart';
import 'config.dart';
import 'Bibles.dart';
import 'BibleSearchDelegate.dart';
import 'BibleSettings.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unique Bible App',
      home: UniqueBible(),
    );
  }
}

class UniqueBible extends StatefulWidget {
  @override
  UniqueBibleState createState() => UniqueBibleState();
}

class UniqueBibleState extends State<UniqueBible> {

  bool _startup = false;
  bool _parallelBibles = false;
  List<dynamic> _data = [[[0, 0, 0], "... loading ...", ""]];
  List _lastBcvList = [0, 0, 0];

  Bibles bibles;
  var scrollController;
  var config;
  var _verseFont;
  var _activeVerseFont;

  UniqueBibleState() {
    this.config = Config();
  }

  Future _setup() async {
    if (!this._startup) {
      var check = await config.setDefault();
      if (check) {
        _verseFont = TextStyle(fontSize: config.fontSize);
        _activeVerseFont = TextStyle(fontSize: config.fontSize, fontWeight: FontWeight.bold);
      }
      bibles = Bibles(this.config.abbreviations);
      _lastBcvList = this.config.historyActiveVerse[0];
      // load bible1
      bibles.bible1 = Bible(config.bible1, this.config.abbreviations);
      await bibles.bible1.loadData();
      _data = bibles.bible1.directOpenSingleChapter(_lastBcvList);
      // make sure these function runs on startup only
      this._startup = true;
      setState(() {
        // pre-load bible2
        bibles.bible2 = Bible(config.bible2, this.config.abbreviations);
        bibles.bible2.loadData();
      });
    }
  }

  void updateHistoryActiveVerse() {
    List<int> tempList = this._lastBcvList.map((i) => i as int).toList();
    this.config.historyActiveVerse.add(tempList);
    this.config.add("historyActiveVerse", (this._lastBcvList));
  }

  void setActiveVerse(List bcvList) {
    if (bcvList.isNotEmpty) {
      _lastBcvList = bcvList;
      this.updateHistoryActiveVerse();
      (_parallelBibles) ? scrollController.jumpToIndex(bcvList[2] * 2 - 1) : scrollController.jumpToIndex(bcvList[2]);
    }
  }

  Future _newVerseSelected(List selected) async {
    var selectedBcvList = selected[0];
    var selectedBible = selected[2];
    if (selectedBcvList != null && selectedBcvList.isNotEmpty) {
      if ((selectedBcvList != _lastBcvList) || ((selectedBcvList == _lastBcvList) && (selectedBible != bibles.bible1.module))) {
        if (selectedBible != bibles.bible1.module) {
          bibles.bible1 = Bible(selectedBible, this.config.abbreviations);
          await bibles.bible1.loadData();
        }
        setState(() {
          this.config.bible1 = bibles.bible1.module;
          this.config.save("bible1", bibles.bible1.module);
          _data = bibles.bible1.directOpenSingleChapter(selectedBcvList);
          _lastBcvList = selectedBcvList;
          this.updateHistoryActiveVerse();
          _parallelBibles = false;
        });
      }
    }
  }

  Future _openBibleSettings(BuildContext context) async {
    final newBibleSettings = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BibleSettings(bibles.bible1, _lastBcvList, this.config.fontSize, this.config.abbreviations)),
    );
    var newVerseString = "${newBibleSettings[1]} ${newBibleSettings[3]}:${newBibleSettings[4]}";
    var newVerse = [[int.parse(newBibleSettings[2]), int.parse(newBibleSettings[3]), int.parse(newBibleSettings[4])], newVerseString, newBibleSettings[0]];
    var newFontSizeValue = double.parse(newBibleSettings[5]);
    this.config.fontSize = newFontSizeValue;
    this.config.save("fontSize", newFontSizeValue);
    var newAbbreviationValue = newBibleSettings[6];
    this.config.abbreviations = newAbbreviationValue;
    this.updateBibleAbbreviations(newAbbreviationValue);
    this.config.save("abbreviations", newAbbreviationValue);
    _newVerseSelected(newVerse);
  }

  void updateBibleAbbreviations(String abbreviations) {
    this.bibles.abbreviations = abbreviations;
    this.bibles.bible1.abbreviations = abbreviations;
    this.bibles.bible2.abbreviations = abbreviations;
  }

  Future _loadXRef (BuildContext context, List bcvList) async {
    var xRefData = await bibles.crossReference(bcvList);
    final List selected = await showSearch(context: context, delegate: BibleSearchDelegate(context, bibles.bible1, this.config.fontSize, this.config.abbreviations, xRefData));
    _newVerseSelected(selected);
  }

  Future _loadCompare (BuildContext context, List bcvList) async {
    var compareData = await bibles.compareBibles("ALL", bcvList);
    final List selected = await showSearch(context: context, delegate: BibleSearchDelegate(context, bibles.bible1, this.config.fontSize, this.config.abbreviations, compareData));
    _newVerseSelected(selected);
  }

  bool _toggleParallelBibles() {
    if ((_parallelBibles) && (bibles.bible1.data != null)) {
      _data = bibles.bible1.directOpenSingleChapter(_lastBcvList);
      return false;
    } else if ((!_parallelBibles) && (bibles.bible1.data != null) && (bibles.bible2.data != null)) {
      _data = bibles.parallelBibles(_lastBcvList);
      return true;
    }
    return _parallelBibles;
  }

  void _swapBibles() {
    bibles.bible3 = bibles.bible1;
    bibles.bible1 = bibles.bible2;
    bibles.bible2 = bibles.bible3;
    bibles.bible3 = Bible("KJV", this.config.abbreviations);
    this.config.bible1 = bibles.bible1.module;
    this.config.bible2 = bibles.bible2.module;
    this.config.save("bible1", bibles.bible1.module);
    this.config.save("bible2", bibles.bible2.module);
    _reLoadBibles();
  }

  void _reLoadBibles() {
    (_parallelBibles) ? _data = bibles.parallelBibles(_lastBcvList) : _data = bibles.bible1.directOpenSingleChapter(_lastBcvList);
  }

  @override
  build(BuildContext context) {
    _setup();
    _verseFont = TextStyle(fontSize: this.config.fontSize);
    _activeVerseFont = TextStyle(fontSize: this.config.fontSize, fontWeight: FontWeight.bold);
    return Scaffold(
      drawer: Drawer(
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Text('History'),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ListTile(
              title: Text('Item 1'),
              onTap: () {
                // Update the state of the app
                // ...
                // Then close the drawer
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Item 2'),
              onTap: () {
                // Update the state of the app
                // ...
                // Then close the drawer
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
        appBar: AppBar(
        title: Text('Unique Bible App'),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () { Scaffold.of(context).openDrawer(); },
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            );
          },
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: () async {
              final List selected = await showSearch(
                context: context,
                delegate: BibleSearchDelegate(context, bibles.bible1, this.config.fontSize, this.config.abbreviations),
              );
              _newVerseSelected(selected);
            },
          ),
          IconButton(
            tooltip: 'Swap',
            icon: const Icon(Icons.swap_calls),
            onPressed: () {
              setState(() {
                _swapBibles();
              });
            },
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _openBibleSettings(context);
            },
          ),
        ],
      ),
      body: _buildVerses(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _parallelBibles = _toggleParallelBibles();
          });
        },
        tooltip: 'Parallel',
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildVerses(BuildContext context) {
    var initialIndex;
    (_parallelBibles) ? initialIndex = _lastBcvList[2] * 2 - 1 : initialIndex = _lastBcvList[2];
    if (_lastBcvList == null) {
      scrollController = IndexedScrollController();
    } else {
      scrollController = IndexedScrollController(
          initialIndex: initialIndex,
          initialScrollOffset: 0.0,
      );
    }
    return IndexedListView.builder(
        padding: const EdgeInsets.all(16.0),
        controller: scrollController,
        // workaround of finite list with IndexedListView:
        // build empty rows with embedded actions
        // do not use itemCount in this case
        //itemCount: _data.length,
        itemBuilder: (context, i) {
          return _buildVerseRow(context, i);
        });
  }

  Widget _buildVerseRow(BuildContext context, int i) {
    if ((i < 0) && (i >= _data.length)) {
      return ListTile(
        title: Text(
          "",
          style: _verseFont,
        ),

        onTap: () {
          if (i < 0) {
            scrollController.jumpToIndex(0);
          } else if (i > _data.length) {
            scrollController.jumpToIndex(_data.length - 1);
          }
        },
      );
    } else if (((!_parallelBibles) && (i == _lastBcvList[2])) || ((_parallelBibles) && ((i == _lastBcvList[2] * 2) || (i == _lastBcvList[2] * 2 - 1)))) {
      return ListTile(
        title: Text(
          _data[i][1],
          style: _activeVerseFont,
        ),

        onTap: () {
          final snackBar = SnackBar(content: Text('Loading cross-references ...'));
          Scaffold.of(context).showSnackBar(snackBar);
          _loadXRef(context, _data[i][0]);
        },

        onLongPress: () {
          Clipboard.setData(ClipboardData(text: _data[i][1]));
          final snackBar = SnackBar(content: Text('Text copied to clipboard!\nLoading comparison ...'));
          Scaffold.of(context).showSnackBar(snackBar);
          _loadCompare(context, _data[i][0]);
        },
      );
    } else if ((i >= 0) && (i < _data.length)) {
      return ListTile(
        title: Text(
          _data[i][1],
          style: _verseFont,
        ),

        onTap: () {
          setActiveVerse(_data[i][0]);
        },

        onLongPress: () {
          Clipboard.setData(ClipboardData(text: _data[i][1]));
          final snackBar = SnackBar(content: Text('Text copied to clipboard!'));
          Scaffold.of(context).showSnackBar(snackBar);
        },
      );
    } else {
      return ListTile(
        title: Text(
          "",
          style: _verseFont,
        ),

        onTap: () {
          if (i < 0) {
            scrollController.jumpToIndex(0);
          } else if (i > _data.length) {
            scrollController.jumpToIndex(_data.length - 1);
          }
        },
      );
    }

  }

}

