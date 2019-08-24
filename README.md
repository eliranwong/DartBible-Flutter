# DartBible-Flutter
Flutter version of the <a href="https://github.com/eliranwong/DartBible">DartBible</a> project; bible tools written in Dart programming language.

Materials in this repository is for building cross-platform apps.
For command-line version, please visit https://github.com/eliranwong/DartBible.

# progress
A simple mobile interface is setup.  All known issues are fixed.
need to improve interface.

features & introduction:

two major screens
* one for bible chapter reading
* one for search features.

SCREEN 1 - bible chapter reading
* the app pre-load 2 bibles
* users can swap the versions via "swap" button, located at right upper corner
* users can toggle parallel reading of both versions via the "plus" floating button
* tap on a verse scrolls the verse to the top.  the font style changes to bold
* a second tap on the already "active" or "bold" verse runs cross-references features on the verse.  results are shown on search screen.
* long-tap (i.e. tap-and-hold) runs "compare all" features, which compare all installed versions on the verse.  results are shown on search screen.

SCREEN 2 - search screen
* as mentioned above, results of cross-references and compare all features are shown on search screen.
* a "tap" on verse listed on one of search results closes the search screen.  the app then goes back to bible chapter reading screen to load the whole chapter where the verse belongs.
* to search the bible currently opened bible in the bible chapter reading screen, you have four major options:
1. search plain text like "Christ Jesus"
2. search with standard regular expression like "Christ.*?Jesus" regular expression is turned on by default.
3. search for a verse reference in order to open a chapter on bible chapter reading screen.  For example, search "John 3:16", and tap on the result to open the whole chapter of John chapter 3 with verse 16 highlighted.
4. search multiple references with a single search, e.g. Rm 3:23; 5:8; 6:23; 10:9, 13; Gen 1:1-2; John 3:1-16. please note that common abbreviations and verse range(s) is supported.

4 common questions:

at the moment, the interface is yet to be fully-built, but users can still get access of available features, via the 1 search field, 2 major screens and 3 buttons mentioned above.  don't forget the "tap" and "long-tap" actions ...

as interface is not yet fully built, users may ask with current interface ...

1) How to change chapter for bible chapter reading screen?  Answer: search for a verse reference, e.g. John 3:16, in search field and tap on the result to open chapter John 3 with verse 16 highligted.

2) How to change bible version for current bible reading chapter?  Answer: "long-tap" to launch "compare all" feature, sellect the version you like.

3) are we going to include Hebrew and Greek bible data in this app?  yes.

4) can you use your own customised or personal bibles for this app?  yes, a converter is in place.  read

5) are we going to improve the interface?  yes, but we will try to keep it as simple as possible

welcome suggestions at support@marvel.bible

# screenshots

<img src="screenshot/screenshot1.png">
<img src="screenshot/screenshot2.png">
<img src="screenshot/screenshot3.png">
<img src="screenshot/screenshot4.png">
<img src="screenshot/screenshot5.png">
<img src="screenshot/screenshot6.png">
<img src="screenshot/screenshot7.png">
<img src="screenshot/screenshot8.png">


