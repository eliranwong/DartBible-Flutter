import 'Helpers.dart';
import 'BibleParser.dart';
import 'config.dart' as config;

class Bibles {

  var bible1, bible2;

  Map getBibles() => {1: this.bible1, 2: this.bible1};

  Future getALLBibleList() async {
    return config.allBibleList;
  }

/*
  Future getALLBibleList() async {
    var fileIO = FileIOHelper();
    var bibleFolder = fileIO.getDataPath("bible");
    var bibleList = await fileIO.getFileListInFolder(bibleFolder);
    bibleList = bibleList.where((i) => (i.endsWith(".json") as bool)).toList();
    bibleList = bibleList.map((i) => fileIO.getBasename(i.substring(0, (i.length - 5)))).toList();
    bibleList.sort();
    return bibleList;
  }
*/

  Future getValidBibleList(List bibleList) async {
    var validBibleList = [];
    var allBibleList = await this.getALLBibleList();
    for (var bible in bibleList) {
      if (allBibleList.contains(bible)) validBibleList.add(bible);
    }
    validBibleList.sort();
    return validBibleList;
  }

  Future loadBible(String bibleModule, [int bibleID = 1]) async {
    var allBibleList = await this.getALLBibleList();
    if (!(allBibleList.contains(bibleModule))) {
      return false;
    } else {
      switch (bibleID) {
        case 1:
          if ((this.bible1 == null) || ((this.bible1 != null) && (this.bible1.module != bibleModule))) {
            this.bible1 = Bible(bibleModule);
            //print("Bible 1 loaded");
          }
          break;
        case 2:
          if ((this.bible2 == null) || ((this.bible2 != null) && (this.bible2.module != bibleModule))) {
            this.bible2 = Bible(bibleModule);
            //print("Bible 2 loaded");
          }
          break;
      }
      return true;
    }
  }

  Future openBible(String bibleModule, String referenceString, [int bibleID = 1]) async {
    if (referenceString.isNotEmpty) {
      var bibleIsLoaded = await this.loadBible(bibleModule, bibleID);
      if (bibleIsLoaded) {
        var referenceList = BibleParser().extractAllReferences(referenceString);
        if (referenceList.isNotEmpty) {
          var versesFound = await this.getBibles()[bibleID].open(referenceList);
          return versesFound;
        }
      }
    }
    return [];
  }

  Future searchBible(String bibleModule, String searchString, [int bibleID = 1]) async {
    if (searchString.isNotEmpty) {
      var bibleIsLoaded = await this.loadBible(bibleModule, bibleID);
      if (bibleIsLoaded) {
        var versesFound = await this.getBibles()[bibleID].search(searchString);
        return versesFound;
      }
    }
    return [];
  }

  Future compareBibles(String bibleString, String referenceString, [int bibleID = 1]) async {
    var bibleList;
    (bibleString == "ALL") ? bibleList = await this.getALLBibleList() : bibleList = await this.getValidBibleList(bibleString.split("_"));
    if (bibleList.isNotEmpty) {
      var referenceList = BibleParser().extractAllReferences(referenceString);
      if (referenceList.isNotEmpty) {
        var versesFound = await this.compareVerses(referenceList, bibleList);
        return versesFound;
      }
    }
    return [];
  }

  Future compareVerses(List listOfBcvList, List bibleList) async {
    List<dynamic> versesFound = [];

    for (var bcvList in listOfBcvList) {
      versesFound.add([[], "[Compare ${BibleParser().bcvToVerseReference(bcvList)}]"]);
      for (var bible in bibleList) {
        var verseText = await Bible(bible).openSingleVerse(bcvList);
        versesFound.add([bcvList, "[$bible] $verseText", bible]);
      }
    }

    return versesFound;
  }

  Future parallelBibles(String bibleString, String referenceString, [int bibleID = 1]) async {
    List<dynamic> versesFound = [];

    var bibleList = await this.getValidBibleList(bibleString.split("_"));
    if (bibleList.length >= 2) {
      var bible1IsLoaded = await this.loadBible(bibleList[0], 1);
      if (bible1IsLoaded) {
        var bible2IsLoaded = await this.loadBible(bibleList[1], 2);
        if (bible2IsLoaded) {
          var referenceList = BibleParser().extractAllReferences(referenceString);
          if (referenceList.length >= 1) {
            var bcvList = referenceList[0];
            versesFound.add([[], "[${BibleParser().bcvToChapterReference(bcvList)}]"]);

            var b = bcvList[0];
            var c = bcvList[1];
            var v = bcvList[2];

            var bible1VerseList = await this.bible1.getVerseList(b, c);
            var vs1 = bible1VerseList[0];
            var ve1 = bible1VerseList[(bible1VerseList.length - 1)];

            var bible2VerseList = await this.bible2.getVerseList(b, c);
            var vs2 = bible2VerseList[0];
            var ve2 = bible2VerseList[(bible2VerseList.length - 1)];

            var vs, ve;
            (vs1 <= vs2) ? vs = vs1 : vs = vs2;
            (ve1 >= ve2) ? ve = ve1 : ve = ve2;

            for (var i = vs; i <= ve; i++) {
              var ibcv = [b, c, i];
              var verseText1 = await this.bible1.openSingleVerse(ibcv);
              var verseText2 = await this.bible2.openSingleVerse(ibcv);
              if (i == v) {
                versesFound.add([ibcv, "**********\n[$i] [${this.bible1.module}] $verseText1", this.bible1.module]);
                versesFound.add([ibcv, "[$i] [${this.bible2.module}] $verseText2\n**********", this.bible2.module]);
              } else {
                versesFound.add([ibcv, "[$i] [${this.bible1.module}] $verseText1", this.bible1.module]);
                versesFound.add([ibcv, "[$i] [${this.bible2.module}] $verseText2", this.bible2.module]);
              }
            }
          }
        }
      }
    }

    return versesFound;
  }

  Future crossReference(String bibleString, String referenceString, [int bibleID = 1]) async {
    var referenceList = BibleParser().extractAllReferences(referenceString);

    var xRefList;
    if (referenceList.isNotEmpty) xRefList = await this.getCrossReference(referenceList[0]);
    if (xRefList.isNotEmpty) {
      var bibleIsLoaded = await this.loadBible(bibleString, 1);
      if (bibleIsLoaded) {
        var versesFound = await this.bible1.openMultipleVerses(xRefList);
        return versesFound;
      }
    }
    return [];
  }

  Future getCrossReference(List bcvList) async {
    var filePath = FileIOHelper().getDataPath("xRef", "xRef");
    var jsonObject = await JsonHelper().getJsonObject(filePath);
    var bcvString = bcvList.join(".");
    var fetchResults = jsonObject.where((i) => (i["bcv"] == bcvString)).toList();
    var referenceString = fetchResults[0]["xref"];
    return BibleParser().extractAllReferences(referenceString);
  }

  Future parallelVerses(List bcvList) async {
    print("pending");
  }

  Future parallelChapters(List bcvList) async {
    print("pending");
  }

}

class Bible {

  var biblePath;
  var module;
  var data;

  Bible(String bible) {
    this.biblePath = FileIOHelper().getDataPath("bible", bible);
    this.module = bible;
  }

  Future getBookList() async {
    if (this.data == null) await this.loadData();

    Set books = {};
    for (var i in this.data) {
      books.add(i["bNo"]);
    }
    var bookList = books.toList();
    bookList.sort();
    return bookList;
  }

  Future getChapterList(int b) async {
    if (this.data == null) await this.loadData();

    Set chapters = {};
    var fetchResults = this.data.where((i) => (i["bNo"] == b)).toList();
    for (var i in fetchResults) {
      chapters.add(i["cNo"]);
    }
    var chapterList = chapters.toList();
    chapterList.sort();
    return chapterList;
  }

  Future getVerseList(int b, int c) async {
    if (this.data == null) await this.loadData();

    Set verses = {};
    var fetchResults = this.data.where((i) => ((i["bNo"] == b) && (i["cNo"] == c))).toList();
    for (var i in fetchResults) {
      verses.add(i["vNo"]);
    }
    return verses.toList();
    var verseList = verses.toList();
    verseList.sort();
    return verseList;
  }

  Future loadData() async {
    this.data = await JsonHelper().getJsonObject(this.biblePath);
  }

  Future open(List referenceList) async {
    if (this.data == null) await this.loadData();

    if ((referenceList.length == 1) && (referenceList[0].length == 3)) {
      return this.openSingleChapter(referenceList[0]);
    } else {
      return this.openMultipleVerses(referenceList);
    }
  }

  Future openSingleVerse(List bcvList) async {
    if (this.data == null) await this.loadData();

    String versesFound = "";

    var b = bcvList[0];
    var c = bcvList[1];
    var v = bcvList[2];

    var fetchResults = this.data.where((i) => ((i["bNo"] == b) && (i["cNo"] == c) && (i["vNo"] == v))).toList();
    for (var found in fetchResults) {
      var verseText = found["vText"].trim();
      versesFound += "$verseText ";
    }

    return versesFound.trimRight();
  }

  Future openSingleVerseRange(List bcvList) async {
    if (this.data == null) await this.loadData();

    String versesFound = "";

    var b = bcvList[0];
    var c = bcvList[1];
    var v = bcvList[2];
    var c2 = bcvList[3];
    var v2 = bcvList[4];

    var check, fetchResults;

    if ((c2 == c) && (v2 > v)) {
      check = v;
      while (check <= v2) {
        fetchResults = this.data.where((i) => ((i["bNo"] == b) && (i["cNo"] == c) && (i["vNo"] == check))).toList();
        for (var found in fetchResults) {
          var verseText = "[${found["vNo"]}] ${found["vText"].trim()}";
          versesFound += "$verseText ";
        }
        check += 1;
      }
    } else if (c2 > c) {
      check = c;
      while (check < c2) {
        fetchResults = this.data.where((i) => ((i["bNo"] == b) && (i["cNo"] == check))).toList();
        for (var found in fetchResults) {
          var verseText = found["vText"].trim();
          versesFound += "$verseText ";
        }
        check += 1;
      }
      check = 0; // some bible versions may have chapters starting with verse 0.
      while (check <= v2) {
        fetchResults = this.data.where((i) => ((i["bNo"] == b) && (i["cNo"] == c) && (i["vNo"] == check))).toList();
        for (var found in fetchResults) {
          var verseText = found["vText"].trim();
          versesFound += "$verseText ";
        }
        check += 1;
      }
    }

    return versesFound.trimRight();
  }

  Future openSingleChapter(List bcvList) async {
    if (this.data == null) await this.loadData();

    List<dynamic> versesFound = [];
    versesFound.add([[], "[${BibleParser().bcvToChapterReference(bcvList)}]"]);
    var fetchResults = this.data.where((i) => ((i["bNo"] == bcvList[0]) && (i["cNo"] == bcvList[1]))).toList();
    for (var found in fetchResults) {
      var b = found["bNo"];
      var c = found["cNo"];
      var v = found["vNo"];
      var verseText = found["vText"].trim();
      (v == bcvList[2]) ? versesFound.add([[b, c, v], "**********\n[$v] $verseText\n**********"]) : versesFound.add([[b, c, v], "[$v] $verseText"]);
  }
    return versesFound;
  }

  Future openMultipleVerses(List listOfBcvList) async {
    if (this.data == null) await this.loadData();

    List<dynamic> versesFound = [];
    versesFound.add([[], "[Multiple verses]"]);
    for (var bcvList in listOfBcvList) {
      var referenceString = "[${BibleParser().bcvToVerseReference(bcvList)}]";
      if (bcvList.length == 5) {
        var verse = await openSingleVerseRange(bcvList);
        versesFound.add([bcvList, "$referenceString $verse"]);
      } else {
        var verse = await openSingleVerse(bcvList);
        versesFound.add([bcvList, "$referenceString $verse"]);
      }
    }
    return versesFound;
  }

  Future search(String searchString) async {
    if (this.data == null) await this.loadData();

    var fetchResults = this.data.where((i) => (i["vText"].contains(RegExp(searchString)) as bool)).toList();

    List<dynamic> versesFound = [];
    versesFound.add([[], "[$searchString is found in ${fetchResults.length} verse(s).]"]);

    for (var found in fetchResults) {
      var b = found["bNo"];
      var c = found["cNo"];
      var v = found["vNo"];
      var bcvRef = BibleParser().bcvToVerseReference([b, c, v]);
      var verseText = found["vText"];
      versesFound.add([[b, c, v], "[$bcvRef] $verseText"]);
    }
    return versesFound;
  }

}