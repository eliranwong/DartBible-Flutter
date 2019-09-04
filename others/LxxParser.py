import re, os

class LxxParser:

    def processLXX(self, inputFile):
        # set output filename here
        path, file = os.path.split(inputFile)
        outputFile = os.path.join(path, "export_{0}".format(file))

        # open file and read input text
        try:
            f = open(inputFile,'r')
            newData = f.read()
            f.close()
        except:
            print("File not found! Please make sure if you enter filename correctly and try again.")

        if newData:
            # parse the opened text
            newData = self.lxx(newData)
    
            # save output text in a separate file
            f = open(outputFile,'w')
            f.write(newData)
            f.close()

    def lxx(self, text):
        searchReplace = {
            ('^[0-9]+?\t[0-9]+?\t', ''),
            ('([^\n])<verse>', r'\1\n<verse>'),
            ('<div class="int"><wform>.*?onmouseout="hl0\({0}(.*?){0},{0}(.*?){0},{0}(.*?){0}\)">(.*?)</grk></wform><br><wsbl>(.*?)</wsbl><br><wphono>(.*?)</wphono><br><ref onclick="lex\({0}.*?{0}\)"><wlex><grk>(.*?)</grk></wlex></ref><br><ref onclick="lxxmorph\({0}.*?{0}\)"><wmorph>(.*?)</wmorph></ref><br><wsn>&nbsp;</wsn><br><wgloss>(.*?)</wgloss></div>'.format("'"), r'「\1｜\2｜\3｜\4｜\5｜\6｜\7｜\8｜\9」'),
        }
        for search, replace in searchReplace:
            dataText = re.sub(search, replace, text, flags=re.M)
        return dataText

if __name__ == '__main__':
    inputName = input("Enter a file name: ")
    parser = LxxParser()
    parser.processLXX(inputName)
    del parser
