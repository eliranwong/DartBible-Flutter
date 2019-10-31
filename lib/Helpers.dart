import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'dart:convert';
import 'config.dart';
// work with sqLite files
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:large_file_copy/large_file_copy.dart';
import 'package:path_provider/path_provider.dart';

enum DialogAction {
  people,
  locations,
  topics,
  openHere,
  confirmRead,
  confirmSaveRead,
  confirmOpen,
  confirmSaveOpen,
  confirmSaveClose,
  confirmClose,
  delete,
  cancel,
  share,
  addFavourite,
  removeFavourite,
  copy,
  addCopy,
  compareAll,
  crossReference,
  interlinearOHGB,
  morphologyOHGB,
  interlinearLXX1,
  morphologyLXX1,
  interlinearLXX2,
  morphologyLXX2,
  interlinearABP,
  openVerse,
}

enum TtsState {
  playing,
  stopped,
}

class TtsHelper {
  String workaroundHebrew(String text) {
    List searchReplace = [
      ['w', 'v'],
      ['ō|ō|Ō|ô|ŏ', 'ο'],
      ['ê|ē|ĕ', 'e'],
      ['î|ī', 'i'],
      ['û', 'u'],
      //['š', 'sh'],
      ['ś', 's'],
      ['ă|ā|â', 'a'],
      ['[ʿʾ]', ''],
    ];
    for (var i in searchReplace) {
      String search = i.first;
      String replace = i.last;
      text = text.replaceAll(RegExp(search), replace);
    }
    return text;
  }

  String removeGreekAccents(String text) {
    List searchReplace = [
      ['[ἀἄᾄἂἆἁἅᾅἃάᾴὰᾶᾷᾳᾆᾀ]', 'α'],
      ['[ἈἌἎἉἍἋ]', 'Α'],
      ['[ἐἔἑἕἓέὲ]', 'ε'],
      ['[ἘἜἙἝἛ]', 'Ε'],
      ['[ἠἤᾔἢἦᾖᾐἡἥἣἧᾗᾑήῄὴῆῇῃ]', 'η'],
      ['[ἨἬἪἮἩἭἫ]', 'Η'],
      ['[ἰἴἶἱἵἳἷίὶῖϊΐῒ]', 'ι'],
      ['[ἸἼἹἽ]', 'Ι'],
      ['[ὀὄὂὁὅὃόὸ]', 'ο'],
      ['[ὈὌὉὍὋ]', 'Ο'],
      ['[ῥ]', 'ρ'],
      ['[Ῥ]', 'Ρ'],
      ['[ὐὔὒὖὑὕὓὗύὺῦϋΰῢ]', 'υ'],
      ['[ὙὝὟ]', 'Υ'],
      ['[ὠὤὢὦᾠὡὥὧᾧώῴὼῶῷῳᾤὣ]', 'ω'],
      ['[ὨὬὪὮὩὭὯ]', 'Ω'],
      [
        "[\-\—\,\;\:\\\?\.\·\·\'\‘\’\᾿\‹\›\“\”\«\»\(\)\[\]\{\}\⧼\⧽\〈\〉\*\‿\᾽\⇔\¦]",
        ""
      ],
    ];
    for (var i in searchReplace) {
      String search = i.first;
      String replace = i.last;
      text = text.replaceAll(RegExp(search), replace);
    }
    return text;
  }
}

class FileIOHelper {
  String getDataPath(String dataType, [String module]) {
    var config = Config();
    return "${config.assets}/$dataType/$module.json";
  }
}

class JsonHelper {
  Future getJsonObject(filePath) async {
    var jsonString = await rootBundle.loadString(filePath);
    var jsonObject = jsonDecode(jsonString);
    return jsonObject;
  }
}

class RegexHelper {
  var searchReplace;

  var searchPattern;

  var patternString;

  String Function(Match) replacement(String pattern) => (Match match) => pattern
      .replaceAllMapped(new RegExp(r'\\(\d+)'), (m) => match[int.parse(m[1])]);

  String replaceAllSmart(
          String source, Pattern pattern, String replacementPattern) =>
      source.replaceAllMapped(pattern, replacement(replacementPattern));

  String doSearchReplace(String text,
      {bool multiLine = false,
      bool caseSensitive = true,
      bool unicode = false,
      bool dotAll = false}) {
    var replacedText = text;
    for (var i in this.searchReplace) {
      var search = i[0];
      var replace = i[1];
      replacedText = this.replaceAllSmart(
          replacedText,
          RegExp(search,
              multiLine: multiLine,
              caseSensitive: caseSensitive,
              unicode: unicode,
              dotAll: dotAll),
          replace);
    }
    return replacedText;
  }
}

class SqliteHelper {
  final Config config;

  SqliteHelper(this.config);

  /*
  Future<String> copyFile(String filename) async {
    var dbDir = await getDatabasesPath();
    var newPathName = join(dbDir, filename);

    ByteData data = await rootBundle.load("assets/$filename");
    List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await File(newPathName).writeAsBytes(bytes);

    return newPathName;
    //e.g. /data/user/0/app.bibletools.unique_bible_app_plus/databases/morphology.sqlite
  }
  */

  Future<String> copyLargeFile(String filename) async {
    String newPathName;

    try {
      newPathName = await LargeFileCopy(filename).copyLargeFile;
    } catch (e) {
      print('Failed to copy the Large File.');
    }

    return newPathName;
  }

  Future initMorphologyDb() async {
    // Construct the path to the app's writable database file:
    Directory directory = await getApplicationDocumentsDirectory();
    var dbPath = join(directory.path, "morphology.sqlite");

    double latestMorphologyVersion = 0.8;

    // check if database is up-to-date
    if (this.config.morphologyVersion < latestMorphologyVersion) {
      // Delete any existing database:
      await deleteDatabase(dbPath);

      // copy database file from assets folder
      dbPath = await copyLargeFile("morphology.sqlite");

      // save config to avoid copying the database file again
      this.config.morphologyVersion = latestMorphologyVersion;
      this.config.save("morphologyVersion", latestMorphologyVersion);
    }

    var db = await openDatabase(dbPath);
    return db;
  }

  Future getMorphology(List bcvList, String module) async {
    if (bcvList.length > 3) bcvList = bcvList.sublist(0, 3);
    final Database db = await this.initMorphologyDb();
    var statement =
        "SELECT * FROM $module WHERE Book = ? AND Chapter = ? AND Verse = ?";
    List<Map> morphology = await db.rawQuery(statement, bcvList);
    db.close();
    return morphology;
  }

  Future initToolsDb() async {
    // Construct the path to the app's writable database file:
    Directory directory = await getApplicationDocumentsDirectory();
    var dbPath = join(directory.path, "tools.sqlite");

    double latestToolsVersion = 1.1;

    // check if database is up-to-date
    if (this.config.toolsVersion < latestToolsVersion) {
      // Delete any existing database:
      await deleteDatabase(dbPath);

      // copy database file from assets folder
      dbPath = await copyLargeFile("tools.sqlite");

      // save config to avoid copying the database file again
      this.config.toolsVersion = latestToolsVersion;
      this.config.save("toolsVersion", latestToolsVersion);
    }

    var db = await openDatabase(dbPath);
    return db;
  }

  Future getTopic(String entry) async {
    final Database db = await this.initToolsDb();
    var statement = "SELECT * FROM EXLBTENTRY WHERE Entry = ?";
    List<Map> lexicon = await db.rawQuery(statement, [entry]);
    db.close();
    return lexicon;
  }

  Future getTopics(List bcvList, String module) async {
    List bcvList2 = [...bcvList, bcvList[2]];
    final Database db = await this.initToolsDb();
    var statement =
        "SELECT Tool, Entry, Topic FROM $module WHERE Book = ? AND Chapter = ? AND Verse <= ? AND toVerse >= ?";
    List<Map> tools = await db.rawQuery(statement, bcvList2);
    db.close();

    List<String> entries = <String>[];
    List<Map> toolsFiltered = <Map>[];
    for (var tool in tools) {
      String entry = tool["Entry"];
      if (!(entries.contains(entry))) {
        entries.add(entry);
        toolsFiltered.add(tool);
      }
    }

    return toolsFiltered;
  }

  Future getTools(List bcvList, String module) async {
    if (bcvList.length > 3) bcvList = bcvList.sublist(0, 3);
    final Database db = await this.initToolsDb();
    var statement = "SELECT * FROM $module WHERE Book = ? AND Chapter = ? AND Verse = ? ORDER BY Number";
    List<Map> tools = await db.rawQuery(statement, bcvList);
    if (tools.isEmpty) {
      statement = "SELECT * FROM $module WHERE Book = ? AND Chapter = ? ORDER BY Number";
      tools = await db.rawQuery(statement, bcvList.sublist(0, 2));
    }
    db.close();

    return tools;
  }

  Future getBookTools(List bcvList, String module) async {
    final Database db = await this.initToolsDb();
    var statement = "SELECT * FROM $module WHERE Book = ? ORDER BY Number";
    List<Map> tools = await db.rawQuery(statement, [bcvList.first]);
    db.close();

    return tools;
  }

  Future initLexiconDb() async {
    // Construct the path to the app's writable database file:
    Directory directory = await getApplicationDocumentsDirectory();
    var dbPath = join(directory.path, "lexicon.sqlite");

    double latestLexiconVersion = 0.8;

    // check if database is up-to-date
    if (this.config.lexiconVersion < latestLexiconVersion) {
      // Delete any existing database:
      await deleteDatabase(dbPath);

      // copy database file from assets folder
      dbPath = await copyLargeFile("lexicon.sqlite");

      // save config to avoid copying the database file again
      this.config.lexiconVersion = latestLexiconVersion;
      this.config.save("lexiconVersion", latestLexiconVersion);
    }

    var db = await openDatabase(dbPath);
    return db;
  }

  Future getLexicons(String lexicalEntries) async {
    List entries = lexicalEntries
        .split(",")
        .sublist(0, (lexicalEntries.split(",").length - 1));
    List data = [];
    for (var entry in entries) {
      List entryData = await getLexicon(entry);
      data = [...data, ...entryData];
    }
    return data;
  }

  Future getLexicon(String entry) async {
    final Database db = await this.initLexiconDb();
    var statement = "SELECT * FROM LEXICON WHERE Entry = ?";
    List<Map> lexicon = await db.rawQuery(statement, [entry]);
    db.close();
    return lexicon;
  }
}

class InterlinearHelper {
  TextStyle _verseFontGreek,
      _activeVerseFontGreek,
      _verseFontHebrew,
      _activeVerseFontHebrew,
      _interlinearStyleDim,
      _interlinearStyle;

  InterlinearHelper(Map verseTextStyle) {
    _verseFontGreek = verseTextStyle["verseFontGreek"];
    _activeVerseFontGreek = verseTextStyle["activeVerseFontGreek"];
    _verseFontHebrew = verseTextStyle["verseFontHebrew"];
    _activeVerseFontHebrew = verseTextStyle["activeVerseFontHebrew"];
    _interlinearStyleDim = verseTextStyle["interlinearStyleDim"];
    _interlinearStyle = verseTextStyle["interlinearStyle"];
  }

  List<TextSpan> getInterlinearSpan(String module, String text, int book, [bool isActive = false]) {
    bool isHebrewBible = (book < 40) && (module == "OHGBi");

    var originalStyle;
    if (!isActive) {
      originalStyle = _verseFontGreek;
      if (isHebrewBible) originalStyle = _verseFontHebrew;
    } else {
      originalStyle = _activeVerseFontGreek;
      if (isHebrewBible) originalStyle = _activeVerseFontHebrew;
    }
    List<TextSpan> words = <TextSpan>[];
    List<String> wordList = text.split("｜");
    for (var word in wordList) {
      if (word.startsWith("＠")) {
        if (isHebrewBible) {
          List<String> glossList = word.substring(1).split(" ");
          for (var gloss in glossList) {
            if ((gloss.startsWith("[")) || (gloss.endsWith("]"))) {
              gloss = gloss.replaceAll(RegExp(r"[\[\]\+\.]"), "");
              words.add(TextSpan(text: "$gloss ", style: _interlinearStyleDim));
            } else {
              words.add(TextSpan(text: "$gloss ", style: _interlinearStyle));
            }
          }
        } else {
          words
              .add(TextSpan(text: word.substring(1), style: _interlinearStyle));
        }
      } else {
        words.add(TextSpan(text: word, style: originalStyle));
      }
    }

    return words;
  }
}
