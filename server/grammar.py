#!/usr/bin/env python

from BeautifulSoup import BeautifulSoup
import urlupload
import urllib2
import urlparse
import tempfile
import subprocess



#artists = ['coldplay', 'tool', 'rage against the machine']
#albums = ['a rush of blood to the head', 'lateralus', 'evil empire']
#songs = ['clocks', 'green eyes', 'the grudge', 'bulls on parade']
jfsg = tempfile.TemporaryFile()

#template = open('dict/template.jfsg', 'r').read()
#template = template.replace('{{ARTISTS}}', '|\n'.join(artists))
#template = template.replace('{{ALBUMS}}', ' |\n'.join(albums))
#template = template.replace('{{SONGS}}', ' |\n'.join(songs))

#jfsg.write(template)

from language import rules
jfsg.write('\n'.join(rules.to_jsgf()))

jfsg.seek(0)

fsg = open('dict/grammar.fsg', 'w+')

subprocess.Popen(['sphinx_jsgf2fsg'], stdin=jfsg, stdout=fsg, stderr=subprocess.PIPE).wait()

fsg.seek(0)

words = set()
for line in fsg:
	if line.startswith('TRANSITION'):
		word = line.split(' ', 4)[4:]
		if word:
			words.add(word[0].strip())

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

