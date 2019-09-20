import re

inputFile = 'file.txt'
outputFile = 'file.csv'

# open file

f = open(inputFile, 'r')
newData = f.read()
f.close()

# clear unwanted spaces
newData = re.sub(' [ ]+?([^ ])', r' \1', newData, flags=re.M)
newData = re.sub('^ ', '', newData, flags=re.M)
newData = re.sub(' $', '', newData, flags=re.M)

# parse book no.
newData = re.sub(r'^\\toc3 Gen', r'《1》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Exo', r'《2》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Lev', r'《3》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Num', r'《4》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Deu', r'《5》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Jos', r'《6》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Jdg', r'《7》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Rut', r'《8》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 1Sa', r'《9》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 2Sa', r'《10》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 1Ki', r'《11》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 2Ki', r'《12》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 1 Ki', r'《11》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 2 Ki', r'《12》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 1Ch', r'《13》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 2Ch', r'《14》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Ezr', r'《15》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Neh', r'《16》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Est', r'《17》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Job', r'《18》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Psa', r'《19》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Pro', r'《20》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Ecc', r'《21》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Sng', r'《22》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Isa', r'《23》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Jer', r'《24》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Lam', r'《25》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Ezk', r'《26》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Dan', r'《27》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Hos', r'《28》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Jol', r'《29》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Amo', r'《30》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Oba', r'《31》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Jon', r'《32》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Mic', r'《33》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Nam', r'《34》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Hab', r'《35》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Zep', r'《36》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Hag', r'《37》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Zec', r'《38》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Mal', r'《39》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Mat', r'《40》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Mrk', r'《41》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Luk', r'《42》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Jhn', r'《43》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Act', r'《44》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Rom', r'《45》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 1Co', r'《46》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 2Co', r'《47》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Gal', r'《48》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Eph', r'《49》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Php', r'《50》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Col', r'《51》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 1Th', r'《52》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 2Th', r'《53》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 1Ti', r'《54》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 2Ti', r'《55》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Tit', r'《56》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Phm', r'《57》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Heb', r'《58》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Jas', r'《59》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 1Pe', r'《60》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 2Pe', r'《61》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 1Jn', r'《62》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 2Jn', r'《63》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 3Jn', r'《64》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Jud', r'《65》', newData, flags=re.M)
newData = re.sub(r'^\\toc3 Rev', r'《66》', newData, flags=re.M)

# parse chapter no.
newData = re.sub(r'^\\c ([0-9]+?)$', r'〈\1〉', newData, flags=re.M)

# parse verse no.
newData = re.sub(r'\\v ([0-9]+?)$', r'〔\1〕｛\1｝', newData, flags=re.M)
newData = re.sub(r'\\v ([0-9]+?) ', r'〔\1〕｛\1｝', newData, flags=re.M)
newData = re.sub(r'\\v ([0-9]+?)\-([0-9]+?) ', r'〔\1〕｛\1-\2｝', newData, flags=re.M)

# remove lines
newData = re.sub(r'([^\n])\\', r'\1\n\\', newData, flags=re.M)
newData = re.sub(r'(\\\*|\\w\*)', '', newData, flags=re.M)
newData = re.sub(r'^\\zaln-e\\\*', '', newData, flags=re.M)
newData = re.sub(r'^\\(usfm|id|h|toc|mt|zaln).*?$', '', newData, flags=re.M)

p = re.compile('《([0-9]+?)(》[^《》]*?〈)([0-9]+?〉)', flags=re.M)
s = p.search(newData)
while s:
    newData = p.sub(r'《\1\2\1.\3', newData)
    s = p.search(newData)

p = re.compile('〈([0-9]+?\.[0-9]+?)(〉[^〈〉]*?〔)([0-9]+?〕)', flags=re.M)
s = p.search(newData)
while s:
    newData = p.sub(r'〈\1\2\1.\3', newData)
    s = p.search(newData)

# remove \s5
newData = re.sub(r'^\\s5', '', newData, flags=re.M)
newData = re.sub(r'^\\s2 ', r'<br><br>', newData, flags=re.M)
newData = re.sub(r'^\\(q|li)[0-9]*? ', r'<br>&emsp;&emsp;', newData, flags=re.M)
newData = re.sub(r'^\\(q|li)[0-9]*?$', r'<br>&emsp;&emsp;', newData, flags=re.M)
newData = re.sub(r'^\\q[0-9]*?(["—\'\(])', r'<br>&emsp;&emsp;\1', newData, flags=re.M)
newData = re.sub(r'\\qa ', r'<br><br>', newData, flags=re.M)
newData = re.sub(r'\\qs\*', r'<br><br>', newData, flags=re.M)
newData = re.sub(r'\\qs ', r'&emsp;&emsp;', newData, flags=re.M)
newData = re.sub(r'^\\pi', r'<br><br>&emsp;&emsp;', newData, flags=re.M)
newData = re.sub(r'^\\p', r'<br><br>', newData, flags=re.M)
newData = re.sub(r'^\\(mi|m)', r'<br>', newData, flags=re.M)
newData = re.sub(r'^\\sp (.*?)$', r'<u><b>\1</b></u><br>', newData, flags=re.M)
newData = re.sub(r'^\\d (.*?)$', r'\1<br>', newData, flags=re.M)

newData = re.sub(r'^\\w( .*?)\|.*?$', r'\1', newData, flags=re.M)

newData = re.sub(r'^\\nb$', '', newData, flags=re.M)
newData = re.sub(r'^\\cl.*?$', '', newData, flags=re.M)
newData = re.sub('^<br>s Book (One|Two|Three|Four|Five)$', '', newData, flags=re.M)

newData = re.sub(r'\\fqa (.*?)$', r' <i>\1</i>', newData, flags=re.M)
newData = re.sub(r'\\fqa\* ', '', newData, flags=re.M)
newData = re.sub(r'\\fqa\*', '', newData, flags=re.M)
newData = re.sub(r'\\f \+', r' [', newData, flags=re.M)
newData = re.sub(r'\\ft', '', newData, flags=re.M)
newData = re.sub(r'\\f\*', r' ]', newData, flags=re.M)

newData = re.sub('〔', r'\n〔', newData, flags=re.M)
newData = re.sub(' [ ]+?([^ ])', r' \1', newData, flags=re.M)
newData = re.sub(r'\n[\n]+?([^\n])', r'\n\1', newData, flags=re.M)
newData = re.sub('\n([^〔])', r' \1', newData, flags=re.M)

newData = re.sub('《[0-9]+?》〈', r'〈', newData, flags=re.M)
p = re.compile('〉<br>', flags=re.M)
s = p.search(newData)
while s:
    newData = p.sub(r'〉', newData)
    s = p.search(newData)
newData = re.sub('〈[^\n〈〉]*?〉', r'\n-|\n', newData, flags=re.M)
newData = re.sub('\' s ', '\'s ', newData, flags=re.M)
newData = re.sub('｝" ', r'｝"', newData, flags=re.M)
newData = re.sub('," ', ', "', newData, flags=re.M)

# format verse number
newData = re.sub('〔([0-9]+?)\.([0-9]+?)\.([0-9]+?)〕｛([^\n｛｝]*?)｝', r'<vid id="v\1.\2.\3" onclick="luV(\3)">\4</vid> ', newData, flags=re.M)

# fix words before verse 1

p = re.compile('\n(<[^v].*?)\n(<vid[^\n<>]*?>.*?</vid> )', flags=re.M)
s = p.search(newData)
while s:
    newData = p.sub(r'\n\2\1', newData)
    s = p.search(newData)

# remove temporary book number
newData = re.sub(' 《[0-9]+?》[ ]*?$', '', newData, flags=re.M)

# clear empty lines
newData = re.sub('\n[\n]+?([^\n])', r'\n\1', newData, flags=re.M)
newData = re.sub('\A\n', '', newData, flags=re.M)

p = re.compile('\n([^<\-].*?)\n(<vid[^\n<>]*?>.*?</vid> )', flags=re.M)
s = p.search(newData)
while s:
    newData = p.sub(r'\n\2\1', newData)
    s = p.search(newData)

# formatting for import into sqlite

# clear empty lines again
newData = re.sub('\n[\n]+?([^\n])', r'\n\1', newData, flags=re.M)

# Notes:
# check if "\" is present
# clear \b
newData = re.sub(r'\\b', '', newData, flags=re.M)
# clear \v 14
newData = re.sub(r'\\v 14$', '', newData, flags=re.M)

# remove tab
newData = re.sub('\t', ' ', newData, flags=re.M)

# extract book and chapter number
newData = re.sub('^(.*?<vid id="v)([0-9]+?)\.([0-9]+?)\.', r'\2\t\3\t\1\2.\3.', newData, flags=re.M)

# deal with chapter 0
p = re.compile(r'^([0-9]+?\t)0\t(.*?\n)\1([0-9]+?\t)', flags=re.M)
s = p.search(newData)
while s:
    newData = p.sub(r'\1\3\2\1\3', newData)
    s = p.search(newData)

# combine verses into chapters
#p = re.compile(r'^([0-9]+?\t[0-9]+?\t)(.*?)\n\1', flags=re.M)
#s = p.search(newData)
#while s:
#    newData = p.sub(r'\1\2 ', newData)
#    s = p.search(newData)

# remove chapter divider
newData = re.sub('^\-\|\n', '', newData, flags=re.M)
# remove extra spaces
newData = re.sub(' [ ]+?([^ ])', r' \1', newData, flags=re.M)


# The following lines simplify the format for use with mobile apps, Android & iOS versions of UniqueBible.app
newData = re.sub('^([0-9]+?\t[0-9]+?\t)<vid id="v[0-9]+?\.[0-9]+?\.[0-9]+?" onclick="luV\([0-9]+?\)">([0-9]+?)</vid> ', r'\1\2\t', newData, flags=re.M)
newData = re.sub('^([0-9]+?\t[0-9]+?\t)<vid id="v[0-9]+?\.[0-9]+?\.[0-9]+?" onclick="luV\([0-9]+?\)">([0-9]+?)\-([0-9]+?)</vid> (.*?)$', r'\1\2\t\4\n\1\3\t', newData, flags=re.M)

newData = re.sub('<i>|</i>', '', newData, flags=re.M)
newData = re.sub('<br>|<u><b>|</b></u>|&emsp;|&ensp;', ' ', newData, flags=re.M)

newData = re.sub(' [ ]+?([^ ])', r' \1', newData, flags=re.M)

newData = re.sub('(“|‘|❛|\(|\[) ', r'\1', newData, flags=re.M)
newData = re.sub(' (”|\)|\]|\.|\?|\!|,|:|;|’)', r'\1', newData, flags=re.M)

newData = re.sub(' [ ]+?([^ ])', r' \1', newData, flags=re.M)
newData = re.sub(' \t|\t ', '\t', newData, flags=re.M)

newData = re.sub('"', '\\"', newData, flags=re.M)
newData = re.sub('^([0-9]+?)\t([0-9]+?)\t([0-9]+?)\t(.*?)$', r'{"bNo": \1, "cNo": \2, "vNo": \3, "vText": "\4"},', newData, flags=re.M)

# close & save file
f = open(outputFile, 'w')
f.write(newData)
f.close()

