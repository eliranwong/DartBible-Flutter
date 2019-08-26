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
    config = Config();
    _verseFont = TextStyle(fontSize: config.fontSize);
    _activeVerseFont = TextStyle(fontSize: config.fontSize, fontWeight: FontWeight.bold);
  }

  Future _setup() async {
    if (!this._startup) {
      var check = await config.setDefault();
      if (check) {
        _verseFont = TextStyle(fontSize: config.fontSize);
        _activeVerseFont = TextStyle(fontSize: config.fontSize, fontWeight: FontWeight.bold);
      }
      bibles = Bibles();
      // load bible1
      bibles.bible1 = Bible(config.bible1);
      await bibles.bible1.loadData();
      _data = bibles.bible1.directOpenSingleChapter(config.lastBcvList);
      _lastBcvList = config.lastBcvList;
      // make sure these function runs on startup only
      this._startup = true;
      setState(() {
        // pre-load bible2
        bibles.bible2 = Bible(config.bible2);
        bibles.bible2.loadData();
      });
    }
  }

  void setActiveVerse(List bcvList) {
    if (bcvList.isNotEmpty) {
      _lastBcvList = bcvList;
      (_parallelBibles) ? scrollController.jumpToIndex(bcvList[2] * 2 - 1) : scrollController.jumpToIndex(bcvList[2]);
    }
  }

  void _newVerseSelected(List selected) async {
    var selectedBcvList = selected[0];
    var selectedBible = selected[2];
    if (selectedBcvList != null && selectedBcvList.isNotEmpty) {
      if ((selectedBcvList != _lastBcvList) || ((selectedBcvList == _lastBcvList) && (selectedBible != bibles.bible1.module))) {
        if (selectedBible != bibles.bible1.module) {
          bibles.bible1 = Bible(selectedBible);
          await bibles.bible1.loadData();
        }
        setState(() {
          _data = bibles.bible1.directOpenSingleChapter(selectedBcvList);
          _lastBcvList = selectedBcvList;
          _parallelBibles = false;
        });
      }
    }
  }

  void _openBibleSettings(BuildContext context) async {
    final newBibleSettings = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BibleSettings(bibles.bible1, _lastBcvList)),
    );
    var newVerseString = "${newBibleSettings[1]} ${newBibleSettings[3]}:${newBibleSettings[4]}";
    var newVerse = [[int.parse(newBibleSettings[2]), int.parse(newBibleSettings[3]), int.parse(newBibleSettings[4])], newVerseString, newBibleSettings[0]];
    _newVerseSelected(newVerse);
  }

  Future _loadXRef (BuildContext context, List bcvList) async {
    var xRefData = await bibles.crossReference(bcvList);
    final List selected = await showSearch(context: context, delegate: BibleSearchDelegate(context, bibles.bible1, xRefData));
    _newVerseSelected(selected);
  }

  Future _loadCompare (BuildContext context, List bcvList) async {
    var compareData = await bibles.compareBibles("ALL", bcvList);
    final List selected = await showSearch(context: context, delegate: BibleSearchDelegate(context, bibles.bible1, compareData));
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
    bibles.bible3 = Bible("KJV");
    _reLoadBibles();
  }

  void _reLoadBibles() {
    (_parallelBibles) ? _data = bibles.parallelBibles(_lastBcvList) : _data = bibles.bible1.directOpenSingleChapter(_lastBcvList);
  }

  @override
  build(BuildContext context) {
    _setup();
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
                delegate: BibleSearchDelegate(context, bibles.bible1),
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
    // if (_data[i][0] == _lastBcvList) {
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

