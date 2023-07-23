import urllib.parse
import urllib.error
import urllib.request
import json
import sys

def kprint(s):
	print(s)

def make_request(param_dict):
	params = urllib.parse.urlencode(param_dict)
	paramsdata = params.encode("ascii")
	headerdict = {'Content-Type': 'application/x-www-form-urlencoded', 'Accept': 'application/json'}
	url = 'https://cadhan.com/api/intergaelic/3.0'
	req = urllib.request.Request(url, paramsdata, headers=headerdict)
	try:
		with urllib.request.urlopen(req) as response:
			try:
				array_of_pairs = json.loads(response.read())
			except ValueError:
				kprint('Malformed JSON returned from the server')
				return []
			return array_of_pairs
	except urllib.error.URLError as e:
		kprint('Unable to connect with the server: ' + e.reason)
		return []
	except urllib.error.HTTPError as e:
		kprint('HTTP error from server: ' + e.code)
		return []
	
def usage():
	kprint('Usage: python client.py [ga|gd|gv]')

def main():
	if len(sys.argv) != 2:
		usage()
		sys.exit(1)
	if sys.argv[1] != 'ga' and sys.argv[1] != 'gd' and sys.argv[1] != 'gv':
		usage()
		sys.exit(1)
	slurped = sys.stdin.read()
	pairs = make_request({'foinse': sys.argv[1], 'teacs': slurped})
	for pair in pairs:
		kprint(pair[0] + ' => ' + pair[1])

if __name__ == '__main__':
	main()
