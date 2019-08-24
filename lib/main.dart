// Copyright 2019 Eliran Wong. All rights reserved.

import 'package:flutter/material.dart';
import 'package:indexed_list_view/indexed_list_view.dart';
import 'config.dart' as config;
import 'Bibles.dart';
import 'BibleSearchDelegate.dart';

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

  Bibles bibles;

  final _verseFont = const TextStyle(fontSize: config.fontSize);
  final _activeVerseFont = const TextStyle(fontSize: config.fontSize, fontWeight: FontWeight.bold);
  List<dynamic> _data = [];

  List _lastBcvList;
  bool _parallelBibles = false;

  var scrollController;

  Future _startup() async {
    if (!config.startup) {

      setState(() async {
        bibles = Bibles();
        // load bible1
        bibles.bible1 = Bible(config.bible1);
        await bibles.bible1.loadData();
        _data = bibles.bible1.directOpenSingleChapter(config.lastBcvList);
        _lastBcvList = config.lastBcvList;
        // pre-load bible2
        bibles.bible2 = Bible(config.bible2);
        bibles.bible2.loadData();
        // make sure this process runs once only
        config.startup = true;
      });
    }
  }

  void _searchResultSelected(List selected) async {
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

  void setActiveVerse(List bcvList) {
    if (bcvList.isNotEmpty) {
      _lastBcvList = bcvList;
      (_parallelBibles) ? scrollController.jumpToIndex(bcvList[2] * 2 - 1) : scrollController.jumpToIndex(bcvList[2]);
    }
  }

  Future _loadXRef (BuildContext context, List bcvList) async {
    var xRefData = await bibles.crossReference(bcvList);
    final List selected = await showSearch(context: context, delegate: BibleSearchDelegate(context, bibles.bible1, xRefData));
    _searchResultSelected(selected);
  }

  Future _loadCompare (BuildContext context, List bcvList) async {
    var compareData = await bibles.compareBibles("ALL", bcvList);
    final List selected = await showSearch(context: context, delegate: BibleSearchDelegate(context, bibles.bible1, compareData));
    _searchResultSelected(selected);
  }
  bool _toggleParallelBibles() {
    if ((_parallelBibles) && (bibles.bible1.data != null)) {
      _data = bibles.bible1.directOpenSingleChapter(_lastBcvList);
      return false;
    } else if ((!_parallelBibles) && (bibles.bible1.data != null) && (bibles.bible2.data != null)) {
      _data = bibles.parallelBibles(_lastBcvList);
      return true;
    }
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
    _startup();
    return Scaffold(
      appBar: AppBar(
        title: Text('Unique Bible App'),

        actions: <Widget>[
          //swap_calls
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: () async {
              final List selected = await showSearch(
                context: context,
                delegate: BibleSearchDelegate(context, bibles.bible1),
              );
              _searchResultSelected(selected);
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
          initialScrollOffset: 0.0
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
          _loadXRef(context, _data[i][0]);
        },

        onLongPress: () {
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

