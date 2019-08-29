// Copyright 2019 Eliran Wong. All rights reserved.

import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter/material.dart';
import 'package:indexed_list_view/indexed_list_view.dart';
import 'config.dart';
import 'Bibles.dart';
import 'BibleSearchDelegate.dart';
import 'BibleSettings.dart';
import 'BibleParser.dart';
import 'DialogAction.dart';

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
  List<dynamic> _data = [
    [
      [0, 0, 0],
      "... loading ...",
      ""
    ]
  ];
  List _currentActiveVerse = [0, 0, 0];

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
        _activeVerseFont =
            TextStyle(fontSize: config.fontSize, fontWeight: FontWeight.bold);
      }
      bibles = Bibles(this.config.abbreviations);
      // pre-load bible1 data
      bibles.bible1 = Bible(config.bible1, this.config.abbreviations);
      await bibles.bible1.loadData();
      setState(() {
        _currentActiveVerse = this.config.historyActiveVerse[0];
        _data = bibles.bible1.openSingleChapter(_currentActiveVerse);
        // pre-load bible2 data
        bibles.bible2 = Bible(config.bible2, this.config.abbreviations);
        bibles.bible2.loadData();
        // make sure these function runs on startup only
        this._startup = true;
      });
    }
  }

  void updateHistoryActiveVerse() {
    List tempList = List<int>.from(this._currentActiveVerse);
    if (this.config.historyActiveVerse[0] != tempList)
      this.config.historyActiveVerse.insert(0, tempList);
    this.config.add("historyActiveVerse", (tempList));
  }

  void addToFavourite(List bcvList) {
    var check = this.config.favouriteVerse.indexOf(bcvList);
    if (check != -1) this.config.favouriteVerse.removeAt(check);
    this.config.favouriteVerse.insert(0, bcvList);
    this.config.add("favouriteVerse", bcvList);
  }

  void removeFromFavourite(List bcvList) {
    var check = this.config.favouriteVerse.indexOf(bcvList);
    if (check != -1) this.config.favouriteVerse.removeAt(check);
    this.config.remove("favouriteVerse", bcvList);
  }

  void setActiveVerse(BuildContext context, List bcvList) {
    if ((bcvList.isNotEmpty) && (bcvList != this._currentActiveVerse)) {
      setState(() {
        _currentActiveVerse = bcvList;
        this.updateHistoryActiveVerse();
        //_scrollToCurrentActiveVerse();
      });
      String verseReference = BibleParser(this.config.abbreviations).bcvToVerseReference(bcvList);
      String message = ""
          "'$verseReference' is selected.\n"
          "'Tap' it again for cross-references.\n"
          "Or 'press' it & 'hold' for more actions.";
      final snackBar = SnackBar(content: Text(message));
      Scaffold.of(context).showSnackBar(snackBar);
    }
  }

  void _scrollToCurrentActiveVerse() {
    (_parallelBibles)
        ? scrollController.jumpToIndex(this._currentActiveVerse[2] * 2 - 1)
        : scrollController.jumpToIndex(this._currentActiveVerse[2]);
  }

  Future _newVerseSelected(List selected) async {
    var selectedBcvList = selected[0];
    var selectedBible = selected[2];
    if (selectedBcvList != null && selectedBcvList.isNotEmpty) {
      if ((selectedBcvList != _currentActiveVerse) ||
          ((selectedBcvList == _currentActiveVerse) &&
              (selectedBible != bibles.bible1.module))) {
        if (selectedBible != bibles.bible1.module) {
          bibles.bible1 = Bible(selectedBible, this.config.abbreviations);
          await bibles.bible1.loadData();
        }
        setState(() {
          this.config.bible1 = bibles.bible1.module;
          this.config.save("bible1", bibles.bible1.module);
          _data = bibles.bible1.openSingleChapter(selectedBcvList);
          _currentActiveVerse = selectedBcvList;
          this.updateHistoryActiveVerse();
          _parallelBibles = false;
        });
      }
    }
  }

  Future _openBibleSettings(BuildContext context) async {
    final newBibleSettings = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => BibleSettings(
              bibles.bible1,
              _currentActiveVerse,
              this.config.fontSize,
              this.config.abbreviations)),
    );
    var newVerseString =
        "${newBibleSettings[1]} ${newBibleSettings[3]}:${newBibleSettings[4]}";
    var newVerse = [
      [
        int.parse(newBibleSettings[2]),
        int.parse(newBibleSettings[3]),
        int.parse(newBibleSettings[4])
      ],
      newVerseString,
      newBibleSettings[0]
    ];
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

  Future _loadXRef(BuildContext context, List bcvList) async {
    var xRefData = await bibles.crossReference(bcvList);
    final List selected = await showSearch(
        context: context,
        delegate: BibleSearchDelegate(context, bibles.bible1,
            this.config.fontSize, this.config.abbreviations, xRefData));
    _newVerseSelected(selected);
  }

  Future _loadCompare(BuildContext context, List bcvList) async {
    var compareData = await bibles.compareBibles("ALL", bcvList);
    final List selected = await showSearch(
        context: context,
        delegate: BibleSearchDelegate(context, bibles.bible1,
            this.config.fontSize, this.config.abbreviations, compareData));
    _newVerseSelected(selected);
  }

  bool _toggleParallelBibles() {
    if ((_parallelBibles) && (bibles.bible1.data != null)) {
      _data = bibles.bible1.openSingleChapter(_currentActiveVerse);
      return false;
    } else if ((!_parallelBibles) &&
        (bibles.bible1.data != null) &&
        (bibles.bible2.data != null)) {
      _data = bibles.parallelBibles(_currentActiveVerse);
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
    (_parallelBibles)
        ? _data = bibles.parallelBibles(_currentActiveVerse)
        : _data = bibles.bible1.openSingleChapter(_currentActiveVerse);
  }

  @override
  build(BuildContext context) {
    _setup();
    _verseFont = TextStyle(fontSize: this.config.fontSize);
    _activeVerseFont =
        TextStyle(fontSize: this.config.fontSize, fontWeight: FontWeight.bold);
    return Scaffold(
      drawer: Drawer(
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
                //decoration: BoxDecoration(color: Colors.blue,),
                currentAccountPicture: const CircleAvatar(
                  backgroundImage: AssetImage("assets/images/account.png"),
                ),
                accountName: const Text("Eliran Wong"),
                accountEmail: const Text("support@bibletools.app")),
            _buildFavouriteList(context),
            _buildHistoryList(context),
            _buildBookList(context),
            _buildChapterList(context),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text('Unique Bible App'),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
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
                delegate: BibleSearchDelegate(context, bibles.bible1,
                    this.config.fontSize, this.config.abbreviations),
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

  Widget _buildFavouriteList(BuildContext context) {
    List<Widget> favouriteRowList;
    if ((this._currentActiveVerse[0] == [0, 0, 0]) || (this.bibles == null)) {
      favouriteRowList = [_emptyRow(context)];
    } else {
      List favouriteList = this.config.favouriteVerse;
      favouriteRowList =
          favouriteList.map((i) => _buildFavouriteRow(context, i)).toList();
    }
    return ExpansionTile(
      title: const Text("Favourites"),
      backgroundColor: Theme.of(context).accentColor.withOpacity(0.025),
      children: favouriteRowList,
    );
  }

  Widget _buildFavouriteRow(BuildContext context, List hxBcvList) {
    var parser = BibleParser(this.config.abbreviations);
    String hxReference = parser.bcvToVerseReference(hxBcvList);
    return ListTile(
      title: Text(
        hxReference,
        //style: _verseFont,
      ),
      onTap: () {
        Navigator.pop(context);
        _scrollToCurrentActiveVerse();
        _newVerseSelected([hxBcvList, "", this.bibles.bible1.module]);
      },

      onLongPress: () {
        _removeFromFavouriteDialog(context, hxBcvList);
      },
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    List<Widget> historyRowList;
    if ((this._currentActiveVerse[0] == [0, 0, 0]) || (this.bibles == null)) {
      historyRowList = [_emptyRow(context)];
    } else {
      List historyList = this.config.historyActiveVerse;
      historyRowList =
          historyList.map((i) => _buildHistoryRow(context, i)).toList();
    }
    return ExpansionTile(
      title: const Text("History"),
      backgroundColor: Theme.of(context).accentColor.withOpacity(0.025),
      children: historyRowList,
    );
  }

  Widget _buildHistoryRow(BuildContext context, List hxBcvList) {
    var parser = BibleParser(this.config.abbreviations);
    String hxReference = parser.bcvToVerseReference(hxBcvList);
    return ListTile(
      title: Text(
        hxReference,
        //style: _verseFont,
      ),
      onTap: () {
        Navigator.pop(context);
        _scrollToCurrentActiveVerse();
        _newVerseSelected([hxBcvList, "", this.bibles.bible1.module]);
      },
      onLongPress: () {
        _addToFavouriteDialog(context, hxBcvList);
      },
    );
  }

  Widget _buildBookList(BuildContext context) {
    List<Widget> bookRowList;
    if ((this._currentActiveVerse[0] == [0, 0, 0]) || (this.bibles == null)) {
      bookRowList = [_emptyRow(context)];
    } else {
      List bookList = this.bibles.bible1.bookList;
      bookRowList = bookList.map((i) => _buildBookRow(context, i)).toList();
    }
    return ExpansionTile(
      title: const Text("Books"),
      backgroundColor: Theme.of(context).accentColor.withOpacity(0.025),
      children: bookRowList,
    );
  }

  Widget _buildBookRow(BuildContext context, int book) {
    var parser = BibleParser(this.config.abbreviations);
    return ListTile(
      title: Text(
        parser.standardAbbreviation[book.toString()],
        //style: _verseFont,
      ),
      onTap: () {
        Navigator.pop(context);
        _scrollToCurrentActiveVerse();
        _newVerseSelected([
          [book, 1, 1],
          "",
          this.bibles.bible1.module
        ]);
      },
      onLongPress: () {
        var selectedBcvList = [book, 1, 1];
        _addToFavouriteDialog(context, selectedBcvList);
      },
    );
  }

  Widget _buildChapterList(BuildContext context) {
    List<Widget> chapterRowList;
    if ((this._currentActiveVerse[0] == [0, 0, 0]) || (this.bibles == null)) {
      chapterRowList = [_emptyRow(context)];
    } else {
      List chapterList =
          this.bibles.bible1.getChapterList(this._currentActiveVerse[0]);
      chapterRowList =
          chapterList.map((i) => _buildChapterRow(context, i)).toList();
    }
    return ExpansionTile(
      title: const Text("Chapters"),
      initiallyExpanded: true,
      backgroundColor: Theme.of(context).accentColor.withOpacity(0.025),
      children: chapterRowList,
    );
  }

  Widget _buildChapterRow(BuildContext context, int chapter) {
    return ListTile(
      title: Text(
        chapter.toString(),
        //style: _verseFont,
      ),
      onTap: () {
        Navigator.pop(context);
        _scrollToCurrentActiveVerse();
        _newVerseSelected([
          [this._currentActiveVerse[0], chapter, 1],
          "",
          this.bibles.bible1.module
        ]);
      },
      onLongPress: () {
        List<int> selectedBcvList = [this._currentActiveVerse[0] as int, chapter, 1];
        _addToFavouriteDialog(context, selectedBcvList);
      },
    );
  }

  Widget _emptyRow(BuildContext context) {
    return ListTile(
      title: Text("... loading ..."),
      onTap: () {
        Navigator.pop(context);
      },
    );
  }

  Widget _buildVerses(BuildContext context) {
    var initialIndex;
    (_parallelBibles)
        ? initialIndex = _currentActiveVerse[2] * 2 - 1
        : initialIndex = _currentActiveVerse[2];
    if (_currentActiveVerse == null) {
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
        // do not use itemCount in this case
        // build empty rows with embedded actions
        // itemCount: _data.length,
        itemBuilder: (context, i) {
          return _buildVerseRow(context, i);
        },
        emptyItemBuilder: (context, i) {
          return _buildEmptyVerseRow(i);
        });
  }

  Widget _buildVerseRow(BuildContext context, int i) {
    if (((!_parallelBibles) && (i == _currentActiveVerse[2])) ||
        ((_parallelBibles) &&
            ((i == _currentActiveVerse[2] * 2) ||
                (i == _currentActiveVerse[2] * 2 - 1)))) {
      return ListTile(
        title: Text(
          _data[i][1],
          style: _activeVerseFont,
        ),
        onTap: () {
          final snackBar =
              SnackBar(content: Text('Loading cross-references ...'));
          Scaffold.of(context).showSnackBar(snackBar);
          _loadXRef(context, _data[i][0]);
        },
        onLongPress: () {
          _longPressedActiveVerse(context, _data[i]);
        },
      );
    } else if ((i >= 0) && (i < _data.length)) {
      return ListTile(
        title: Text(
          _data[i][1],
          style: _verseFont,
        ),
        onTap: () {
          setActiveVerse(context, _data[i][0]);
        },
        onLongPress: () {
          _longPressedVerse(_data[i]);
        },
      );
    }
  }

  Widget _buildEmptyVerseRow(int i) {
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

  // reference: https://api.flutter.dev/flutter/material/SimpleDialog-class.html
  Future<void> _longPressedVerse(List verseData) async {
    var copiedText = await Clipboard.getData('text/plain');
    switch (await showDialog<DialogAction>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: const Text('Select an action:'),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () { Navigator.pop(context, DialogAction.copy); },
                child: const Text('Copy'),
              ),
              SimpleDialogOption(
                onPressed: () { Navigator.pop(context, DialogAction.addCopy); },
                child: const Text('Add to Copied Text'),
              ),
              SimpleDialogOption(
                onPressed: () { Navigator.pop(context, DialogAction.addFavourite); },
                child: const Text('Add to Favourites'),
              ),
            ],
          );
        }
    )) {
      case DialogAction.copy:
        Clipboard.setData(ClipboardData(text: verseData[1]));
        break;
      case DialogAction.addCopy:
        var combinedText = copiedText.text;
        combinedText += "\n${verseData[1]}";
        Clipboard.setData(ClipboardData(text: combinedText));
        break;
      case DialogAction.addFavourite:
        setState(() {
          List bcvList = List<int>.from(verseData[0]);
          addToFavourite(bcvList);
        });
        break;
      default:
    }
  }

  Future<void> _longPressedActiveVerse(BuildContext context, List verseData) async {
    var copiedText = await Clipboard.getData('text/plain');
    switch (await showDialog<DialogAction>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: const Text('Select an action:'),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () { Navigator.pop(context, DialogAction.copy); },
                child: const Text('Copy'),
              ),
              SimpleDialogOption(
                onPressed: () { Navigator.pop(context, DialogAction.addCopy); },
                child: const Text('Add to Copied Text'),
              ),
              SimpleDialogOption(
                onPressed: () { Navigator.pop(context, DialogAction.addFavourite); },
                child: const Text('Add to Favourites'),
              ),
              SimpleDialogOption(
                onPressed: () { Navigator.pop(context, DialogAction.crossReference); },
                child: const Text('Cross-References'),
              ),
              SimpleDialogOption(
                onPressed: () { Navigator.pop(context, DialogAction.compareAll); },
                child: const Text('Compare ALL'),
              ),
              SimpleDialogOption(
                onPressed: () { Navigator.pop(context, DialogAction.interlinear); },
                child: const Text('Interlinear'),
              ),
              SimpleDialogOption(
                onPressed: () { Navigator.pop(context, DialogAction.morphology); },
                child: const Text('Morphology'),
              ),
            ],
          );
        }
    )) {
      case DialogAction.copy:
        Clipboard.setData(ClipboardData(text: verseData[1]));
        break;
      case DialogAction.addCopy:
        var combinedText = copiedText.text;
        combinedText += "\n${verseData[1]}";
        Clipboard.setData(ClipboardData(text: combinedText));
        break;
      case DialogAction.addFavourite:
        setState(() {
          List bcvList = List<int>.from(verseData[0]);
          addToFavourite(bcvList);
        });
        break;
      case DialogAction.crossReference:
        _loadXRef(context, verseData[0]);
        break;
      case DialogAction.compareAll:
        _loadCompare(context, verseData[0]);
        break;
      case DialogAction.interlinear:
        // ...
        break;
      case DialogAction.morphology:
      // ...
        break;
      default:
    }
  }

  // reference: https://github.com/flutter/flutter/blob/master/examples/flutter_gallery/lib/demo/material/dialog_demo.dart
  void _addToFavouriteDialog(BuildContext context, List bcvList) {
    final ThemeData theme = Theme.of(context);
    final TextStyle dialogTextStyle = theme.textTheme.subhead.copyWith(color: theme.textTheme.caption.color);
    showMyDialog<DialogAction>(
      bcvList,
      context: context,
      child: AlertDialog(
        content: Text(
          "Add to Favourites?",
          style: dialogTextStyle,
        ),
        actions: <Widget>[
          FlatButton(
            child: const Text('CANCEL'),
            onPressed: () {
              Navigator.pop(context, DialogAction.cancel);
            },
          ),
          FlatButton(
            child: const Text('ADD'),
            onPressed: () {
              Navigator.pop(context, DialogAction.addFavourite);
            },
          ),
        ],
      ),
    );
  }

  void _removeFromFavouriteDialog(BuildContext context, List bcvList) {
    final ThemeData theme = Theme.of(context);
    final TextStyle dialogTextStyle = theme.textTheme.subhead.copyWith(color: theme.textTheme.caption.color);
    showMyDialog<DialogAction>(
      bcvList,
      context: context,
      child: AlertDialog(
        content: Text(
          "Remove from Favourites?",
          style: dialogTextStyle,
        ),
        actions: <Widget>[
          FlatButton(
            child: const Text('CANCEL'),
            onPressed: () {
              Navigator.pop(context, DialogAction.cancel);
            },
          ),
          FlatButton(
            child: const Text('REMOVE'),
            onPressed: () {
              Navigator.pop(context, DialogAction.removeFavourite);
            },
          ),
        ],
      ),
    );
  }

  void showMyDialog<T>(List bcvList, {BuildContext context, Widget child}) {
    showDialog<T>(
      context: context,
      builder: (BuildContext context) => child,
    ).then<void>((T value) {
      // The value passed to Navigator.pop() or null.

      if (value == DialogAction.addFavourite) {
        setState(() {
          addToFavourite(bcvList);
        });
      } else if (value == DialogAction.removeFavourite) {
        setState(() {
          removeFromFavourite(bcvList);
        });
      }
    });
  }

}

