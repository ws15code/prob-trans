## Paul Hager
## Native Transcription to Phoneme Transcription Script
## 7.15.16 -
## sbs_create_phntrans_UR.py

## Script should be run with the following options:
## python script.py <list of utterance IDs> <character to phoneme dictionary filename> <data directory>

##Update: 7.15.16 Select an arbitrary phone that is not 'eps' for all graphemes with many possible phonemes.
##Do not throw away 'eps' phonemes 

##If running on real data be sure that utterance_ID = utterance[:-1] not [:-5]

import string
import sys
import codecs

def main(argv):
	utterance_list = argv[0]	
	char_to_phone_dict_filename = argv[1]
	data_dir = argv[2]

	utterance_list = open(utterance_list, 'r')
	char_to_phone_dict = open(char_to_phone_dict_filename, 'r')
	phone_dict = {}

	#Create a rough source language character to phoneme dictionary
	for line in char_to_phone_dict:
		items = line.split();
		phone_dict[unicode(items[0], encoding='utf-8')] = " ".join(items[1:])
	urdu_dict = {}
	for utterance in utterance_list:
		
		## Below line can be used when the list of utterances are the form XXXX.wav	
		utterance_ID = utterance[:-1]

		## codecs code is borrowed from Spencer Green
		## See more at: http://www.spencegreen.com/2008/12/19/python-arabic-unicode/#sthash.BkRHT3pK.dpuf

		filename = data_dir + '/' + utterance_ID + '.txt'
		IN_FILE = codecs.open(filename,'r', encoding='utf-8')
		words = IN_FILE.readline().split()

		phone_tran_line = '' 
		for word in words:
			first = ""
			last = word
			while last != "":
				index = 1
				phones = ""
				while (last[:index] in phone_dict.keys()) and (index <= len(last)):
					phones = phone_dict[last[:index]]
					index += 1
				first = first + " " + phones
				if index>1:
					last = last[index-1:]
				else:
					last = last[index:]

			phone_tran_line += first
		IN_FILE.close()
	
		sys.stdout.write(string.lstrip(phone_tran_line) + '\n')
	utterance_list.close()

if __name__ == "__main__":
	main(sys.argv[1:])
