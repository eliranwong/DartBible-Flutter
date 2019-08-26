import 'package:shared_preferences/shared_preferences.dart';

class Config {

  SharedPreferences prefs;

  String assets = "assets";
  // var allBibleList = ["CUV", "KJV", "ISV", "LEB", "NET", "WEB"];
  // var allBibleList = ["ASV", "BSB", "CUV", "CUVs", "KJV", "ISV", "LEB", "NET", "ULT", "UST", "WEB"];
  List allBibleList = ["CUV", "CSB", "NIV", "KJV", "ISV", "LEB", "NET", "WEB"];

  double fontSize = 18.0;
  var abbreviations = "ENG";
  var bible1 = "KJV";
  var bible2 = "NET";
  var lastBcvList = [43, 3, 16];

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
    if (prefs.getStringList("lastBcvList") == null) {
      prefs.setStringList("lastBcvList", ["43", "3", "16"]);
    } else {
      var bcvList = prefs.getStringList("lastBcvList") ?? ["43", "3", "16"];
      this.lastBcvList = bcvList.map((i) => int.parse(i)).toList();
    }

    return true;
  }

  Future read() async {
    this.prefs = await SharedPreferences.getInstance();

    if (prefs.getDouble("fontSize") != null) this.fontSize = prefs.getDouble("fontSize");
    if (prefs.getString("abbreviations") != null) this.abbreviations = prefs.getString("abbreviations");
    if (prefs.getString("bible1") != null) this.bible1 = prefs.getString("bible1");
    if (prefs.getString("bible2") != null) this.bible2 = prefs.getString("bible2");
    if (prefs.getStringList("lastBcvList") != null) {
      var bcvList = prefs.getStringList("lastBcvList") ?? ["43", "3", "16"];
      this.lastBcvList = bcvList.map((i) => int.parse(i)).toList();
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
      case "lastBcvList":
        await prefs.setStringList(feature, newSetting as List<String>);
        break;
    }

    return true;
  }

  void add() {
    // TO DO
  }

}