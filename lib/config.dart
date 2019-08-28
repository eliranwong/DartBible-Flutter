import 'package:shared_preferences/shared_preferences.dart';

class Config {

  SharedPreferences prefs;

  Map interfaceBibleSettings = {
    "ENG": ["Settings", "Interface", "Bible", "Book", "Chapter", "Verse", "Font Size"],
    "TC": ["設定", "介面語言", "聖經", "書卷", "章", "節", "字體大小"],
    "SC": ["设定", "接口语言", "圣经", "书卷", "章", "节", "字体大小"],
  };

  String assets = "assets";
  // var allBibleList = ["CUV", "KJV", "ISV", "LEB", "NET", "WEB"];
  // var allBibleList = ["ASV", "BSB", "CUV", "CUVs", "KJV", "ISV", "LEB", "NET", "ULT", "UST", "WEB"];
  List allBibleList = ["CUV", "CSB", "NIV", "KJV", "ISV", "LEB", "NET", "WEB"];

  double fontSize = 18.0;
  var abbreviations = "ENG";
  var bible1 = "KJV";
  var bible2 = "NET";
  var historyActiveVerse = [[43, 3, 16]];

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
    }

    return true;
  }

  Future add(feature, newItem) async {
    switch (feature) {
      case "historyActiveVerse":
        var tempHistoryActiveVerse = prefs.getStringList("historyActiveVerse");
        tempHistoryActiveVerse.insert(0, newItem.join("."));
        if (tempHistoryActiveVerse.length > 20) tempHistoryActiveVerse.removeAt(tempHistoryActiveVerse.length - 1);
        await prefs.setStringList("historyActiveVerse", tempHistoryActiveVerse);
        break;
    }
  }

}