#!/usr/bin/env python

from BeautifulSoup import BeautifulSoup
import urlupload
import urllib2
import urlparse
import tempfile
import subprocess

jsgf = tempfile.TemporaryFile()

from language import rules
jsgf.write('\n'.join(rules.to_jsgf()))

jsgf.seek(0)

fsg = open('dict/grammar.fsg', 'w+')

subprocess.Popen(['sphinx_jsgf2fsg'], stdin=jsgf, stdout=fsg, stderr=subprocess.PIPE).wait()

jsgf.close()

fsg.seek(0)

words = set()
for line in fsg:
	if line.startswith('TRANSITION'):
		word = line.split(' ', 4)[4:]
		if word:
			words.add(word[0].strip())

fsg.close()

print ', '.join(words)

corpus = tempfile.TemporaryFile()
corpus.writelines('%s\n' % word for word in words)
corpus.seek(0)

req = urllib2.urlopen('http://www.speech.cs.cmu.edu/cgi-bin/tools/lmtool/run', {
	'formtype': 'simple',
	'corpus': corpus
})

soup = BeautifulSoup(req.read())

dic = urlparse.urljoin(req.url, [a['href'] for a in soup('a') if a['href'].endswith('.dic')][0])

f = open('dict/grammar.dic', 'w')
f.write(urllib2.urlopen(dic).read())
f.close()
