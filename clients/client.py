#!/usr/bin/env python
# -*- coding: utf-8 -*-
# json is part of Python 2.6, not 2.5.  
import urllib
import urllib2
import json
import sys
import socket

# hack to allow piping of output w/o errors
reload(sys)
sys.setdefaultencoding('utf-8')

def kprint(s):
	print s.encode('utf-8')

def make_request(param_dict):
	params = urllib.urlencode(param_dict)
	headers = {'Content-Type': 'application/x-www-form-urlencoded', 'Accept': 'application/json'}
	try:
		req = urllib2.Request('http://borel.slu.edu/cgi-bin/seirbhis3.cgi', params, headers)
	except URLError as e:
		kprint('Unable to connect with the server: ' + e.reason)
		return []
	except urllib2.HTTPError as e:
		kprint('HTTP error from server: ' + e.code)
		return []
	else: # we're good
		r1 = urllib2.urlopen(req)
		try:
			array_of_pairs = json.loads(r1.read())
		except ValueError:
			kprint('Malformed JSON returned from the server')
			return []
		return array_of_pairs
	
def usage():
	kprint('Usage: python client.py [-d|-x]')

# ok to just read in as byte streams for now; if we eventually want UTF-8,
# can do sys.stdin = codecs.getreader('utf-8')(sys.stdin) 
def main():
	# if no -d/-x 
	#usage()
	#sys.exit(0)
	if len(sys.argv) != 2:
		usage()
		sys.exit(1)
	if sys.argv[1] != 'gd' and sys.argv[1] != 'gv':
		usage()
		sys.exit(1)
	slurped = sys.stdin.read()
	pairs = make_request({'foinse': sys.argv[1], 'teacs': slurped})
	for pair in pairs:
		kprint(pair[0] + ' => ' + pair[1])

if __name__ == '__main__':
	main()
