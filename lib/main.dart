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

  final _bibleFont = const TextStyle(fontSize: 18.0);
  List<dynamic> _data = [];

  List _lastBcvList;
  bool _parallelBibles = false;

  var scrollController;

  Future _startup() async {
    if (!config.startup) {
      bibles = Bibles();
      var fetchResults = await bibles.openBible(config.bible1, config.lastBcvList);
      _data = fetchResults;
      _lastBcvList = config.lastBcvList;
      config.startup = true;
      setState(() {
        bibles.bible2 = Bible(config.bible2);
        bibles.bible2.loadData();
      });
    }
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

  void _searchResultSelected(List selected) {
    if (selected != null && selected != _lastBcvList) {
      setState(() {
        _data = bibles.bible1.directOpenSingleChapter(selected);
        _lastBcvList = selected;
        _parallelBibles = false;
      });
    }
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
                delegate: BibleSearchDelegate(bibles.bible1),
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
      body: _buildVerses(),
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

  Widget _buildVerses() {
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
        //itemCount: _data.length,
        itemBuilder: (context, i) {
          // the following condition is added to avoid errors with using IndexedListView:
          // it is not necessary for using standard ListView
          return _buildRow(i);
          //if ((i >= 0) && (i < _data.length)) return _buildRow(i);
          //return _buildEmptyRow(i);
        });
  }

  Widget _buildEmptyRow(int i) {
    return ListTile(
        title: Text(
        "",
        style: _bibleFont,
        ),

        onTap: () {
          if ((_data.isEmpty) && (i < 0)) {
            scrollController.jumpToIndex(0);
            print(0);
          }
        }
    );
  }

  Widget _buildRow(int i) {
    if ((i >= 0) && (i < _data.length)) {
      return ListTile(
        title: Text(
          _data[i][1],
          style: _bibleFont,
        ),

        onTap: () {
          setState(() {
            // TODO open a chapter on this verse
            print("Tap; index = $i");
          });
        },

        onLongPress: () {
          setState(() {
            // TODO open cross-references
            print("Long tap; index = $i");
          });
        },
      );
    } else {
      return ListTile(
        title: Text(
          "",
          style: _bibleFont,
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

