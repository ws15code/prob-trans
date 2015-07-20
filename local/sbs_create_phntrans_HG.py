import re
import codecs
import sys, getopt

# This program reads hungarian text and converts it to IPA characters.
# It first reads through the text and tries to find English Words
# If English words are found, uses a pre-made dictionary to map the
# English word to IPA pronunciation syllables
# Any non-English word is then converted to IPA characters using a second
# Dictionary provided by Mark

#Define a file path
engPronuncToIpa = "/export/ws15-pt-data/data/misc/eng-ARPA2IPA.txt"
engToPronunciation = "/export/ws15-pt-data/data/misc/eng-cmu-dict.txt"
hungWordsToPronunciation = "/export/ws15-pt-data/data/misc/hungarian_lexicon_utf8.txt"
hungPronunciationToIpa = "/export/ws15-pt-data/data/misc/hungarian_lexicon_phoneset_dictionary.txt"
hungarianToIpa = "/export/ws15-pt-data/tkekona/HGTextStuff/HungText.txt"
Hnum = 0
Enum = 0
total = 0
def main(argv):

	#The current hardcoded locations are for test purposes. These values are overwritten by the
	#input parameters below
	htextlist = "/export/ws15-pt-data/data/lists/hungarian/train.txt"
	hungarianFileFolder = "/export/ws15-pt-data/tkekona/textfiles/hungarian/"

	try:
		opts, args = getopt.getopt(argv,"hg:u:t:",["g2p=","utts=","transdir="])
	except getopt.GetoptError:
		print 'sbs_create_phntrans_HG.py -g <grammerToPhone> -u <utterances> -t <transcriptDirectory>'
		sys.exit(2)
	for opt, arg in opts:
		if opt == '-h':
			print 'sbs_create_phntrans_HG.py -g <grammerToPhone> -u <utterances> -t <transcriptDirectory>'
			sys.exit()
		elif opt in ("-g", "--g2p"): #hungarian to IPA dictionary
			NOWIAMHARDCODINGTHIS = arg
		elif opt in ("-u", "--utts"): #.txt file list
			htextlist = arg
		elif opt in ("-t", "--transdir"): #actual location 
			hungarianFileFolder = arg

	#Make an Hungarian words to pronunciation dictionary
	HPDict = makeDictionary(hungWordsToPronunciation, '\t', True)
	#Make a Hungarian pronunciation to Ipa dictionary
	HPIDict = makeDictionary(hungPronunciationToIpa, '\t', True)
	#Chain HPDict and PIDict to make a HWIDict
	HWIDict = chainDictionaries(HPDict, HPIDict)
	
	#Make an English to Pronuncition of English word dictionary
	EPDict = makeDictionary(engToPronunciation, '  ', False)
	#Make an English Pronunciation to Ipa dictionary
	EPIDict = makeDictionary(engPronuncToIpa, '\t', True)
	#Map English words to Ipa Pronunciation by chaining EPDict and EPIDict
	EWIDict = chainDictionaries(EPDict, EPIDict)
	
	#Make an Hungarian words/transcript not found in any dictionary to Ipa dictionary
	HIDict = makeDictionary(hungarianToIpa, '\t', True)
	
	#htextlist contains a list of all the hungarian transcript file names appended with .wav
	with open(htextlist) as list:
		#Iterate through the htext file names and change text to IPA form
		first = True
		for line in list:
#			I used to have a list of all the .wave files but it is now the list of .txt files
#			line = line[:-4]
#			toIpa(hungarianFileFolder + line + "txt", HEIDict, HIDict, line)
			toIpa(hungarianFileFolder + "/" + line.strip() + ".txt", HWIDict, EWIDict, HIDict, line)
	output = open("/export/ws15-pt-data/tkekona/HGTextStuff/EnglishPriority.txt", 'a')
	output.write("Hungarian Words found using HDict: " + str(Hnum) + "\n")
	output.write("English Words found using EDict: " + str(Enum) + "\n")
	output.write("Total num words in documents: " + str(total) + "\n")
			
def chainDictionaries(LPDict, PIDict):
	#New dictionary mapping from Language words to the IPA pronunciation of the word
	newdict = {}
	
	#For every key, value pair in dict1, convert value to Ipa and map dict1 key to Ipa of value
	for key, value in LPDict.iteritems():
		newValue = pronunciationToIpa(value, PIDict)
		newdict[key] = newValue
		
	return newdict

#value is the string of pronunciation symbols
def pronunciationToIpa(value, PIDict):
	#Result string to return
	result = ""
	
	#Split the original string by whitespace
	phonemes = re.split(' ', value.strip())
	
	#Convert each phone to Ipa. If it doesn't exist, replace with a # and print an error message
	for phone in phonemes:
		if phone in PIDict:
			result += PIDict[phone].strip() + " "
		else:
			print "#" + phone + "#"
			print "#" + phone + "#" + " was not found in PIDict"
	
	return result.strip()
	
		
def makeDictionary(dictFile, parser, unicode):
	content = ""
	if unicode:
		#Open the hangarian to API character dictionary
		file = codecs.open(dictFile, 'r', 'utf-8')
		content = file.readlines()
	else:
		#We know these files are in English
		file = open(dictFile)
		content = file.readlines()
	
	#Dictionary to return
	dict = {}
	
	#If hangarian character is found, return API form of character
	for line in content:
		line = line.strip()
		if not line.startswith("#") and not line.startswith(";;;"):
			pair =  re.split(parser, line)
			if len(pair) == 2:
				dict[pair[0].strip()] = pair[1].strip()
				
	return dict
	
def toIpa(hungarianFile, Hdict, Edict, dict, line):	
	#Open file with hungarian text and read it as unicode
	hf = codecs.open(hungarianFile, 'r', 'utf-8')
	hwords = hf.read()
	
	#Build string to write to output file
	ipa = ""
	
	#Makes a list of the individual words by parsing spaces
	words = re.findall(r"[\w']+|[!.?,\"\'$;:#%^&*@-]", hwords)
	
	for word in words:
		global total
		total = total + 1
		if word in Edict:
			ipa += Edict[word] + " "
			global Enum
			Enum = Enum + 1
		elif word in Hdict:
			ipa += Hdict[word] + " "
			global Hnum
			Hnum = Hnum + 1
		else:
			#Iterate through each character in hwords and change hangarian characters to API
			for char in word:
				if char == "." or char == "!" or char == "?":
					ipa += "sil "
				elif char in dict:
					ipa += dict[char] + " "
				
	print ipa.encode('utf-8').strip()
	
main(sys.argv[1:])