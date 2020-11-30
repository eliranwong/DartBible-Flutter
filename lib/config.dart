import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Config {
  bool plus = true;
  String plusURL = (Platform.isAndroid)
      ? 'https://play.google.com/store/apps/details?id=app.bibletools.unique_bible_app_plus_paid'
      : 'https://apps.apple.com/app/unique-bible-app-plus/id1480768821?ls=1';
  Map plusMessage = {
    "ENG": ["is available in our 'PLUS' version.", "Learn more"],
    "TC": ["可以在我們的「PLUS」加強版上使用。", "了解更多"],
    "SC": ["可以在我们的「PLUS」加强版上使用。", "了解更多"],
  };

  SharedPreferences prefs;

  String assets = "assets";

  Map allBibleMap = {
    "ABG": "Apostolic Bible Greek Text",
    "ASV": "American Standard Version",
    "BBE": "Bible in Basic English",
    "BSB": "Berean Study Bible",
    "CCB": "當代聖經修訂版〔繁體〕",
    "CCBs": "当代圣经修订版〔简体〕",
    "CEB": "Common English Bible",
    "CEV": "Contemporary English Version",
    "CSB": "Christian Standard Bible",
    "CUV": "中文和合本〔繁體〕",
    "CUVs": "中文和合本〔简体〕",
    "ERV": "English Revised Version",
    "ESV": "English Standard Version",
    "EXP": "The Expanded Bible",
    "ISV": "International Standard Version",
    "KJV": "King James Version",
    "LEB": "Lexham English Bible",
    "LXX1": "Septuagint [Rahlfs 1935]; main text",
    "LXX1i": "Septuagint [Rahlfs 1935]; main text [interlinear]",
    "LXX2": "Septuagint [Rahlfs 1935]; alternate text",
    "LXX2i": "Septuagint [Rahlfs 1935]; alternate text [interlinear]",
    "LXXE": "Brenton English Septuagint",
    "LXXGNT": "Septuagint & Greek New Testament",
    "LXXGNTi": "Septuagint & Greek New Testament [interlinear]",
    "LXXk": "Septuagint [KJV versification]",
    "MSG": "The Message",
    "NASB": "New American Standard Bible",
    "NET": "New English Translation",
    "NIV": "New International Version",
    "NKJV": "New King James Version",
    "NLT": "New Living Translation",
    "NRSV": "New Revised Standard Version",
    "OHGB": "Open Hebrew & Greek Bible",
    "OHGBi": "Open Hebrew & Greek Bible [interlinear]",
    "OHGBt": "Open Hebrew & Greek Bible [transliteration]",
    "T4T": "Translation for Translators",
    "ULT": "UnfoldingWord Literal Text",
    "UST": "UnfoldingWord Simplified Text",
    "WEB": "World English Bible",
    "AMP": "Amplified Bible",
    "AMPC": "Amplified Bible, Classic Edition",
    "NA28": "NA28 Greek New Testament",
    "NETS": "New English Translation of the Septuagint",
    "NETS2": "New English Translation of the Septuagint [alternate texts]",
    "NJPS": "New Jewish Publication Society of America Tanakh",
    "TNK": "Tanakh",
    "UBS5": "UBS5 Greek New Testament",
  };

  List<String> hebrewBibles = ["OHGB", "OHGBi"];
  List<String> greekBibles = [
    "ABG",
    "LXX1",
    "LXX2",
    "LXXk",
    "OHGB",
    "OHGBi",
    "LXXGNT",
    "LXXGNTi",
    "LXX1i",
    "LXX2i",
    "NA28",
    "UBS5"
  ];
  List<String> interlinearBibles = ["OHGBi", "LXXGNTi", "LXX1i", "LXX2i"];
  List<String> chineseBibles = ["CCB", "CCBs", "CUV", "CUVs"];

  // public versions
  /*List<String> allBibleList = [
    "ABG",
    "ASV",
    "BBE",
    "BSB",
    "CUV",
    "CUVs",
    "ERV",
    "ISV",
    "KJV",
    "LEB",
    "LXX1",
    "LXX1i",
    "LXX2",
    "LXX2i",
    "LXXE",
    "LXXGNT",
    "LXXGNTi",
    "LXXk",
    "NET",
    "OHGB",
    "OHGBi",
    "OHGBt",
    "T4T",
    "ULT",
    "UST",
    "WEB"
  ];*/
  // private versions
  List<String> allBibleList = [
    "ABG",
    "AMP",
    "AMPC",
    "ASV",
    "BBE",
    "BSB",
    "CCB",
    "CCBs",
    "CEB",
    "CEV",
    "CSB",
    "CUV",
    "CUVs",
    "ERV",
    "ESV",
    "EXP",
    "ISV",
    "KJV",
    "LEB",
    "LXX1",
    "LXX1i",
    "LXX2",
    "LXX2i",
    "LXXE",
    "LXXGNT",
    "LXXGNTi",
    "LXXk",
    "MSG",
    "NA28",
    "NASB",
    "NET",
    "NETS",
    "NETS2",
    "NIV",
    "NJPS",
    "NKJV",
    "NLT",
    "NRSV",
    "OHGB",
    "OHGBi",
    "OHGBt",
    "T4T",
    "TNK",
    "UBS5",
    "ULT",
    "UST",
    "WEB"
  ];

  // variables linked with shared preferences

  // public versions
/*
  List<String> compareBibleList = [
    "ASV",
    "BSB",
    "ERV",
    "ISV",
    "KJV",
    "LEB",
    "LXXk",
    "NET",
    "OHGB",
    "WEB",
  ];
*/
  // private versions
  List<String> compareBibleList = [
    "CEV",
    "CSB",
    "CUV",
    "ESV",
    "EXP",
    "ISV",
    "KJV",
    "LXXE",
    "LXXk",
    "NASB",
    "NET",
    "NIV",
    "OHGB"
  ];

  bool bigScreen = false;
  bool showNotes = false;
  bool showDrawer = true;
  bool showHeadingVerseNo = false;
  double fontSize = 20.0;
  String abbreviations = "ENG";
  String bible1 = "KJV";
  String bible2 = "NET";
  String marvelBible = "MAB";
  String iBible = "OHGBi";
  List<List<int>> historyActiveVerse = [
    [43, 3, 16]
  ];
  List<List<int>> favouriteVerse = [
    [43, 3, 16]
  ];
  double morphologyVersion = 0.0;
  double lexiconVersion = 0.0;
  double toolsVersion = 0.0;
  int instantAction = 0;
  int favouriteAction = 1;
  int backgroundColor = 0;
  double speechRate = (Platform.isAndroid) ? 1.0 : 0.5;
  String ttsChinese = "zh-CN";
  String ttsEnglish = "en-GB";
  String ttsGreek = "modern";

  Map myColors;
  Map verseTextStyle;
  ThemeData mainTheme;

  void updateThemeData() {
    if (this.myColors != null) {
      mainTheme = ThemeData(
        //primaryColor: this.myColors["appBarColor"],
        appBarTheme: AppBarTheme(color: this.myColors["appBarColor"]),
        scaffoldBackgroundColor: Colors.blueGrey[this.backgroundColor],
        unselectedWidgetColor: this.myColors["blue"],
        accentColor: this.myColors["blueAccent"],
        dividerColor: this.myColors["grey"],
        cardColor: (this.backgroundColor >= 500)
            ? this.myColors["appBarColor"]
            : Colors.grey[300],
      );
    }
  }

  Future setDefault() async {
    this.prefs = await SharedPreferences.getInstance();

    if (prefs.getBool("bigScreen") == null) {
      prefs.setBool("bigScreen", this.bigScreen);
    } else {
      this.bigScreen = prefs.getBool("bigScreen");
    }
    if (prefs.getBool("showNotes") == null) {
      prefs.setBool("showNotes", this.showNotes);
    } else {
      this.showNotes = prefs.getBool("showNotes");
    }
    if (prefs.getBool("showDrawer") == null) {
      prefs.setBool("showDrawer", this.showDrawer);
    } else {
      this.showDrawer = prefs.getBool("showDrawer");
    }
    if (prefs.getBool("showHeadingVerseNo") == null) {
      prefs.setBool("showHeadingVerseNo", this.showHeadingVerseNo);
    } else {
      this.showHeadingVerseNo = prefs.getBool("showHeadingVerseNo");
    }
    if (prefs.getDouble("fontSize") == null) {
      prefs.setDouble("fontSize", this.fontSize);
    } else {
      this.fontSize = prefs.getDouble("fontSize");
    }
    if (prefs.getString("abbreviations") == null) {
      prefs.setString("abbreviations", this.abbreviations);
    } else {
      this.abbreviations = prefs.getString("abbreviations");
    }
    if (prefs.getString("bible1") == null) {
      prefs.setString("bible1", this.bible1);
    } else {
      this.bible1 = prefs.getString("bible1");
    }
    if (prefs.getString("bible2") == null) {
      prefs.setString("bible2", this.bible2);
    } else {
      this.bible2 = prefs.getString("bible2");
    }
    if (prefs.getString("marvelBible") == null) {
      prefs.setString("marvelBible", this.marvelBible);
    } else {
      this.marvelBible = prefs.getString("marvelBible");
    }
    if (prefs.getString("iBible") == null) {
      prefs.setString("iBible", this.iBible);
    } else {
      this.iBible = prefs.getString("iBible");
    }
    if (prefs.getString("ttsChinese") == null) {
      prefs.setString("ttsChinese", this.ttsChinese);
    } else {
      this.ttsChinese = prefs.getString("ttsChinese");
    }
    if (prefs.getString("ttsEnglish") == null) {
      prefs.setString("ttsEnglish", this.ttsEnglish);
    } else {
      this.ttsEnglish = prefs.getString("ttsEnglish");
    }
    if (prefs.getString("ttsGreek") == null) {
      prefs.setString("ttsGreek", this.ttsGreek);
    } else {
      this.ttsGreek = prefs.getString("ttsGreek");
    }
    if (prefs.getStringList("historyActiveVerse") == null) {
      prefs.setStringList("historyActiveVerse", ["43.3.16"]);
    } else {
      var tempHistoryActiveVerse = prefs
          .getStringList("historyActiveVerse")
          .map((i) => i.split("."))
          .toList();
      this.historyActiveVerse = [];
      for (var i in tempHistoryActiveVerse) {
        this.historyActiveVerse.add(i.map((i) => int.parse(i)).toList());
      }
    }
    if (prefs.getStringList("favouriteVerse") == null) {
      prefs.setStringList("favouriteVerse", ["43.3.16"]);
    } else {
      var tempFavouriteVerse = prefs
          .getStringList("favouriteVerse")
          .map((i) => i.split("."))
          .toList();
      this.favouriteVerse = [];
      for (var i in tempFavouriteVerse) {
        this.favouriteVerse.add(i.map((i) => int.parse(i)).toList());
      }
    }
    if (prefs.getDouble("morphologyVersion") == null) {
      prefs.setDouble("morphologyVersion", this.morphologyVersion);
    } else {
      this.morphologyVersion = prefs.getDouble("morphologyVersion");
    }
    if (prefs.getDouble("lexiconVersion") == null) {
      prefs.setDouble("lexiconVersion", this.lexiconVersion);
    } else {
      this.lexiconVersion = prefs.getDouble("lexiconVersion");
    }
    if (prefs.getDouble("toolsVersion") == null) {
      prefs.setDouble("toolsVersion", this.toolsVersion);
    } else {
      this.toolsVersion = prefs.getDouble("toolsVersion");
    }
    if (prefs.getDouble("speechRate") == null) {
      prefs.setDouble("speechRate", this.speechRate);
    } else {
      this.speechRate = prefs.getDouble("speechRate");
    }
    if (prefs.getStringList("compareBibleList") == null) {
      prefs.setStringList("compareBibleList", this.compareBibleList);
    } else {
      this.compareBibleList = prefs.getStringList("compareBibleList");
    }
    if (prefs.getInt("favouriteAction") == null) {
      prefs.setInt("favouriteAction", this.favouriteAction);
    } else {
      this.favouriteAction = prefs.getInt("favouriteAction");
    }
    if (prefs.getInt("instantAction") == null) {
      prefs.setInt("instantAction", this.instantAction);
    } else {
      this.instantAction = prefs.getInt("instantAction");
    }
    if (prefs.getInt("backgroundColor") == null) {
      prefs.setInt("backgroundColor", this.backgroundColor);
    } else {
      this.backgroundColor = prefs.getInt("backgroundColor");
    }

    return true;
  }

  Future read() async {
    this.prefs = await SharedPreferences.getInstance();

    if (prefs.getBool("bigScreen") == null)
      this.bigScreen = prefs.getBool("bigScreen");
    if (prefs.getBool("showNotes") == null)
      this.showNotes = prefs.getBool("showNotes");
    if (prefs.getBool("showDrawer") == null)
      this.showDrawer = prefs.getBool("showDrawer");
    if (prefs.getBool("showHeadingVerseNo") == null)
      this.showHeadingVerseNo = prefs.getBool("showHeadingVerseNo");
    if (prefs.getDouble("fontSize") != null)
      this.fontSize = prefs.getDouble("fontSize");
    if (prefs.getString("abbreviations") != null)
      this.abbreviations = prefs.getString("abbreviations");
    if (prefs.getString("bible1") != null)
      this.bible1 = prefs.getString("bible1");
    if (prefs.getString("bible2") != null)
      this.bible2 = prefs.getString("bible2");
    if (prefs.getString("marvelBible") != null)
      this.marvelBible = prefs.getString("marvelBible");
    if (prefs.getString("iBible") != null)
      this.iBible = prefs.getString("iBible");
    if (prefs.getString("ttsEnglish") != null)
      this.ttsEnglish = prefs.getString("ttsEnglish");
    if (prefs.getString("ttsGreek") != null)
      this.ttsGreek = prefs.getString("ttsGreek");
    if (prefs.getString("ttsChinese") != null)
      this.ttsChinese = prefs.getString("ttsChinese");
    if (prefs.getStringList("historyActiveVerse") != null) {
      var tempHistoryActiveVerse = prefs
          .getStringList("historyActiveVerse")
          .map((i) => i.split("."))
          .toList();
      this.historyActiveVerse = [];
      for (var i in tempHistoryActiveVerse) {
        this.historyActiveVerse.add(i.map((i) => int.parse(i)).toList());
      }
    }
    if (prefs.getStringList("favouriteVerse") != null) {
      var tempFavouriteVerse = prefs
          .getStringList("favouriteVerse")
          .map((i) => i.split("."))
          .toList();
      this.favouriteVerse = [];
      for (var i in tempFavouriteVerse) {
        this.favouriteVerse.add(i.map((i) => int.parse(i)).toList());
      }
    }
    if (prefs.getDouble("morphologyVersion") != null)
      this.morphologyVersion = prefs.getDouble("morphologyVersion");
    if (prefs.getDouble("lexiconVersion") != null)
      this.lexiconVersion = prefs.getDouble("lexiconVersion");
    if (prefs.getDouble("toolsVersion") != null)
      this.toolsVersion = prefs.getDouble("toolsVersion");
    if (prefs.getDouble("speechRate") != null)
      this.speechRate = prefs.getDouble("speechRate");
    if (prefs.getStringList("compareBibleList") != null)
      this.compareBibleList = prefs.getStringList("compareBibleList");
    if (prefs.getInt("favouriteAction") != null)
      this.favouriteAction = prefs.getInt("favouriteAction");
    if (prefs.getInt("instantAction") != null)
      this.instantAction = prefs.getInt("instantAction");
    if (prefs.getInt("backgroundColor") != null)
      this.backgroundColor = prefs.getInt("backgroundColor");

    return true;
  }

  Future save(String feature, dynamic newSetting) async {
    switch (feature) {
      case "bigScreen":
        await prefs.setBool(feature, newSetting as bool);
        break;
      case "showNotes":
        await prefs.setBool(feature, newSetting as bool);
        break;
      case "showDrawer":
        await prefs.setBool(feature, newSetting as bool);
        break;
      case "showHeadingVerseNo":
        await prefs.setBool(feature, newSetting as bool);
        break;
      case "fontSize":
        await prefs.setDouble(feature, newSetting as double);
        break;
      case "abbreviations":
        await prefs.setString(feature, newSetting as String);
        break;
      case "bible1":
        await prefs.setString(feature, newSetting as String);
        break;
      case "bible2":
        await prefs.setString(feature, newSetting as String);
        break;
      case "marvelBible":
        await prefs.setString(feature, newSetting as String);
        break;
      case "iBible":
        await prefs.setString(feature, newSetting as String);
        break;
      case "ttsChinese":
        await prefs.setString(feature, newSetting as String);
        break;
      case "ttsEnglish":
        await prefs.setString(feature, newSetting as String);
        break;
      case "ttsGreek":
        await prefs.setString(feature, newSetting as String);
        break;
      case "morphologyVersion":
        await prefs.setDouble(feature, newSetting as double);
        break;
      case "lexiconVersion":
        await prefs.setDouble(feature, newSetting as double);
        break;
      case "toolsVersion":
        await prefs.setDouble(feature, newSetting as double);
        break;
      case "speechRate":
        await prefs.setDouble(feature, newSetting as double);
        break;
      case "compareBibleList":
        await prefs.setStringList(feature, newSetting as List<String>);
        break;
      case "favouriteAction":
        await prefs.setInt(feature, newSetting as int);
        break;
      case "instantAction":
        await prefs.setInt(feature, newSetting as int);
        break;
      case "backgroundColor":
        await prefs.setInt(feature, newSetting as int);
        break;
    }

    return true;
  }

  Future add(feature, newItem) async {
    switch (feature) {
      case "historyActiveVerse":
        var tempHistoryActiveVerse = prefs.getStringList("historyActiveVerse");
        var newAddition = newItem.join(".");
        if (tempHistoryActiveVerse[0] != newAddition) {
          tempHistoryActiveVerse.insert(0, newAddition);
          // set limitations for the number of history records
          if (tempHistoryActiveVerse.length > 20)
            tempHistoryActiveVerse = tempHistoryActiveVerse.sublist(0, 20);
          await prefs.setStringList(
              "historyActiveVerse", tempHistoryActiveVerse);
        }
        break;
      case "favouriteVerse":
        var tempFavouriteVerse = prefs.getStringList("favouriteVerse");
        var newAddition = newItem.join(".");
        if ((tempFavouriteVerse.isEmpty) ||
            (tempFavouriteVerse[0] != newAddition)) {
          // avoid duplication in favourite records:
          var check = tempFavouriteVerse.indexOf(newAddition);
          if (check != -1) tempFavouriteVerse.removeAt(check);
          tempFavouriteVerse.insert(0, newAddition);
          // set limitations for the number of history records
          if (tempFavouriteVerse.length > 20)
            tempFavouriteVerse = tempFavouriteVerse.sublist(0, 20);
          await prefs.setStringList("favouriteVerse", tempFavouriteVerse);
        }
        break;
    }
  }

  Future remove(feature, newItem) async {
    if (feature == "favouriteVerse") {
      var newAddition = newItem.join(".");
      var tempFavouriteVerse = prefs.getStringList("favouriteVerse");
      var check = tempFavouriteVerse.indexOf(newAddition);
      if (check != -1) tempFavouriteVerse.removeAt(check);
      await prefs.setStringList("favouriteVerse", tempFavouriteVerse);
    }
  }
}
