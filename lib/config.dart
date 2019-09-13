import 'package:shared_preferences/shared_preferences.dart';

class Config {

  SharedPreferences prefs;

  String assets = "assets";

  List<String> hebrewBibles = ["OHGB", "OHGBi"];
  List<String> greekBibles = ["ABG", "LXX1", "LXX2", "LXXk", "OHGB", "OHGBi"];
  List<String> interlinearBibles = ["OHGBi"];

  Map verseTextStyle;

  List<String> allBibleList = ["ABG", "ASV", "BBE", "BSB", "CUV", "CUVs", "ERV", "ISV", "KJV", "LEB", "LXX1", "LXX2", "LXXE", "LXXk", "NET", "OHGB", "OHGBi", "T4T", "ULT", "UST", "WEB"];
  // the following line is written for personal use only [not for public]
  //List<String> allBibleList = ["ABG", "ASV", "BBE", "BSB", "CCB", "CEB", "CEV", "CSB", "CUV", "CUVs", "ERV", "ESV", "EXP", "ISV", "KJV", "LEB", "LXX1", "LXX2", "LXXE", "LXXk", "NASB", "NET", "NIV", "NLT", "NRSV", "OHGB", "OHGBi", "T4T", "ULT", "UST", "WEB"];

  // variables linked with shared preferences
  List<String> compareBibleList = ["ASV", "BSB", "ERV", "ISV", "KJV", "LEB", "LXXk", "NET", "OHGB", "WEB"];
  // the following line is written for personal use only [not for public]
  //List<String> compareBibleList = ["CEV", "CSB", "CUV", "ESV", "EXP", "ISV", "KJV", "LEB", "LXXE", "LXXk", "NASB", "NET", "NIV", "OHGB"];

  double fontSize = 20.0;
  String abbreviations = "ENG";
  String bible1 = "KJV";
  String bible2 = "NET";
  List<List<int>> historyActiveVerse = [[43, 3, 16]];
  List<List<int>> favouriteVerse = [[43, 3, 16]];
  double morphologyVersion = 0.0;
  double toolsVersion = 0.0;
  int instantAction = 0;
  int favouriteAction = 1;

  Future setDefault() async {
    this.prefs = await SharedPreferences.getInstance();

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
    if (prefs.getStringList("historyActiveVerse") == null) {
      prefs.setStringList("historyActiveVerse", ["43.3.16"]);
    } else {
      var tempHistoryActiveVerse = prefs.getStringList("historyActiveVerse").map((i) => i.split(".")).toList();
      this.historyActiveVerse = [];
      for (var i in tempHistoryActiveVerse) {
        this.historyActiveVerse.add(i.map((i) => int.parse(i)).toList());
      }
    }
    if (prefs.getStringList("favouriteVerse") == null) {
      prefs.setStringList("favouriteVerse", ["43.3.16"]);
    } else {
      var tempFavouriteVerse = prefs.getStringList("favouriteVerse").map((i) => i.split(".")).toList();
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
    if (prefs.getDouble("toolsVersion") == null) {
      prefs.setDouble("toolsVersion", this.toolsVersion);
    } else {
      this.toolsVersion = prefs.getDouble("toolsVersion");
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

    return true;
  }

  Future read() async {
    this.prefs = await SharedPreferences.getInstance();

    if (prefs.getDouble("fontSize") != null) this.fontSize = prefs.getDouble("fontSize");
    if (prefs.getString("abbreviations") != null) this.abbreviations = prefs.getString("abbreviations");
    if (prefs.getString("bible1") != null) this.bible1 = prefs.getString("bible1");
    if (prefs.getString("bible2") != null) this.bible2 = prefs.getString("bible2");
    if (prefs.getStringList("historyActiveVerse") != null) {
      var tempHistoryActiveVerse = prefs.getStringList("historyActiveVerse").map((i) => i.split(".")).toList();
      this.historyActiveVerse = [];
      for (var i in tempHistoryActiveVerse) {
        this.historyActiveVerse.add(i.map((i) => int.parse(i)).toList());
      }
    }
    if (prefs.getStringList("favouriteVerse") != null) {
      var tempFavouriteVerse = prefs.getStringList("favouriteVerse").map((i) => i.split(".")).toList();
      this.favouriteVerse = [];
      for (var i in tempFavouriteVerse) {
        this.favouriteVerse.add(i.map((i) => int.parse(i)).toList());
      }
    }
    if (prefs.getDouble("morphologyVersion") != null) this.morphologyVersion = prefs.getDouble("morphologyVersion");
    if (prefs.getDouble("toolsVersion") != null) this.toolsVersion = prefs.getDouble("toolsVersion");
    if (prefs.getStringList("compareBibleList") != null) this.compareBibleList = prefs.getStringList("compareBibleList");
    if (prefs.getInt("favouriteAction") != null) this.favouriteAction = prefs.getInt("favouriteAction");
    if (prefs.getInt("instantAction") != null) this.instantAction = prefs.getInt("instantAction");

    return true;
  }

  Future save(String feature, dynamic newSetting) async {
    switch (feature) {
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
      case "morphologyVersion":
        await prefs.setDouble(feature, newSetting as double);
        break;
      case "toolsVersion":
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
          if (tempHistoryActiveVerse.length > 20) tempHistoryActiveVerse = tempHistoryActiveVerse.sublist(0, 20);
          await prefs.setStringList("historyActiveVerse", tempHistoryActiveVerse);
        }
        break;
      case "favouriteVerse":
        var tempFavouriteVerse = prefs.getStringList("favouriteVerse");
        var newAddition = newItem.join(".");
        if ((tempFavouriteVerse.isEmpty) || (tempFavouriteVerse[0] != newAddition)) {
          // avoid duplication in favourite records:
          var check = tempFavouriteVerse.indexOf(newAddition);
          if (check != -1) tempFavouriteVerse.removeAt(check);
          tempFavouriteVerse.insert(0, newAddition);
          // set limitations for the number of history records
          if (tempFavouriteVerse.length > 20) tempFavouriteVerse = tempFavouriteVerse.sublist(0, 20);
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
