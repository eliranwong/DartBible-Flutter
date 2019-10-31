import re, glob, os

class SearchReplaceHelper:

    def searchText(self, text):
        # example of simple search
#        searchReplace = {
#            ('^([0-9]+?\t[0-9]+?\t[0-9]+?\t)(.*?)\t(.*?)$', r'\1\2 ｜＠\3'),
#        }
#        text = self.simpleSearch(text, searchReplace)
        # example of loop search
#        searchPattern = '^([0-9]+?\t[0-9]+?\t[0-9]+?\t)(.*?)\n{0}'.format(r'\1')
#        searchReplace = {
#            (searchPattern, r'\1\2 ｜'),
#        }
#        text = self.loopSearch(text, searchPattern, searchReplace)
        return text

    def simpleSearch(self, text, searchReplace):
        for search, replace in searchReplace:
            text = re.sub(search, replace, text, flags=re.M)
        return text

    def loopSearch(self, text, searchPattern, searchReplace):
        p = re.compile(searchPattern, flags=re.M)
        while p.search(text):
            for search, replace in searchReplace:
                text = re.sub(search, replace, text, flags=re.M)
        return text

    def searchFile(self, inputFile):
        # set output filename here
        path, file = os.path.split(inputFile)
        outputFile = os.path.join(path, "replaced_{0}".format(file))
        # open file and read input text
        try:
            f = open(inputFile,'r')
            newData = f.read()
            f.close()
        except:
            print("Filename not found! Please correct it and try again.")
        # if it is not empty
        if newData:
            # search the opened text
            newData = self.searchText(newData)
            # save output text in a separate file
            f = open(outputFile,'w')
            f.write(newData)
            f.close()

    def searchFilesInFolder(self, folder):
        fileList = glob.glob(folder+"/*")
        for file in fileList:
            if os.path.isfile(file):
                self.searchFile(file)

    def startSearching(self, inputName):
        # check if user's input is a file or a folder
        if os.path.isfile(inputName):
            self.searchFile(inputName)
        elif os.path.isdir(inputName):
            self.searchFilesInFolder(inputName)
        else:
            print("\""+inputName+"\"", "is not found!")

if __name__ == '__main__':
    # Interaction with user
    # ask for filename or folder name
    inputName = input("Enter a file / folder name here: ")

    SearchReplaceHelper().startSearching(inputName)
    
    print("Done! Check file(s) with name(s) starting with 'replaced_'")
