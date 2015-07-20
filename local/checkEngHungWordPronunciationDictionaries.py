import re
import codecs
import sys, getopt

engPronuncToIpa = "/export/ws15-pt-data/data/misc/eng-ARPA2IPA.txt"
engToPronunciation = "/export/ws15-pt-data/data/misc/eng-cmu-dict.txt"
hungWordsToPronunciation = "/export/ws15-pt-data/data/misc/hungarian_lexicon_utf8.txt"
hungPronunciationToIpa = "/export/ws15-pt-data/data/misc/hungarian_lexicon_phoneset_dictionary.txt"
hungarianToIpa = "/export/ws15-pt-data/tkekona/HGTextStuff/HungText.txt"

def main():
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
	
	total = 0
	same = 0
	different = 0
	
	for key, value in HWIDict.iteritems():
		total = total + 1
		if key in EWIDict:
			if HWIDict[key] == EWIDict[key]:
				same = same + 1
			else:
				different = different + 1
	output = open("/export/ws15-pt-data/tkekona/HGTextStuff/HEDictComparison.txt", 'a')
	output.write("Total: " + str(total) + "\n")
	output.write("Same: " + str(same) + "\n")
	output.write("Different: " + str(different) + "\n")
	

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
	
def chainDictionaries(LPDict, PIDict):
	#New dictionary mapping from Language words to the IPA pronunciation of the word
	newdict = {}
	
	#For every key, value pair in dict1, convert value to Ipa and map dict1 key to Ipa of value
	for key, value in LPDict.iteritems():
		newValue = pronunciationToIpa(value, PIDict)
		newdict[key] = newValue
		
	return newdict
	
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
	
main()