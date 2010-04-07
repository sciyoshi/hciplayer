#!/usr/bin/env python
import pyparsing as pp
import json

pL = pp.Literal
pK = pp.Keyword
pS = lambda *args: pp.And(args)
pP = lambda str: pp.And([pL(x) for x in str.split()])
pO = pp.Optional
pG = pp.Group
pI = pp.Suppress
pOoM = pp.OneOrMore

class Commands(set):
	def __init__(self, rules):
		self.rules = rules

	def __setitem__(self, name, value):
		self.rules[name] = value
		self.add(name)

	@property
	def parser(self):
		return pp.Or([self.rules[name] for name in self])

class Grouping(pp.TokenConverter):
	pass

class Rules(object):
	def __init__(self, parser, public='commands'):
		self.parser = parser
		self.public = public
		self.rules = {}
		self.commands = Commands(self)

		ruleName = pp.Combine(pp.Suppress('<') + pp.Word(pp.alphanums + '.') + pp.Suppress('>'))
		ruleName.setParseAction(lambda toks: self[toks[0]])

		expr = pp.Forward()

		seq = pp.Group(pp.delimitedList(expr, delim=pp.Empty()))
		seq.setParseAction(lambda toks: pp.And(toks[0]))

		self.rule = alt = pp.Group(pp.delimitedList(seq, delim='|'))
		alt.setParseAction(lambda toks: pp.Or(toks[0]))

		optExpr = pp.nestedExpr(opener='[', closer=']', content=alt)
		optExpr.setParseAction(lambda toks: pp.Optional(toks[0][0]))

		groupExpr = pp.nestedExpr(opener='(', closer=')', content=alt)
		groupExpr.setParseAction(lambda toks: Grouping(toks[0][0]))

		word = pp.Word(pp.alphanums + r".&'\"")
		word.setParseAction(lambda toks: pp.Keyword(toks[0]))

		token = pp.Or([ruleName, groupExpr, optExpr, word])

		zeroOrMore = token + pp.Suppress(pp.Literal('*'))
		zeroOrMore.setParseAction(lambda toks: pp.ZeroOrMore(toks[0]))

		oneOrMore = token + pp.Suppress(pp.Literal('+'))
		oneOrMore.setParseAction(lambda toks: pp.OneOrMore(toks[0]))

		elem = pp.Or([token, oneOrMore, zeroOrMore])

		expr << (elem + pp.Optional(pp.Combine(pp.Suppress('/') + pp.Word(pp.alphanums + '.'))).setResultsName('tag'))
		expr.setParseAction(self.parseExpr)

	def parseExpr(self, tokens):
		token = tokens[0]
		if tokens.tag:
			token = pp.Group(token).setResultsName(tokens.pop(1))
			token.setParseAction(lambda toks: toks[0])
		return token

	def __setitem__(self, name, value):
		if isinstance(value, (str, unicode)):
			value = self.rule.parseString(value)[0].setResultsName(name)

		if name in self.rules:
			self.rules[name] << value
		else:
			self.rules[name] = value

	def __getitem__(self, name):
		if name not in self.rules:
			self.rules[name] = pp.Forward()
			self.rules[name] = self.rules[name].setResultsName(name)
		return self.rules[name]

	def __delitem__(self, name):
		del self.rules[name]

	def parse(self, str):
		for k, v in word_map.iteritems():
			str = re.sub(r'`%s`'% v, k, str)
		print str
		try:
			result = self.commands.parser.parseString(str)
		except:
			return
		for command in self.commands:
			if command in result:
				return self.parser(command, result)

	def transform(self, item, top=False):
		if item in self.rules.values() and not top:
			return '<%s>' % item.resultsName
		elif isinstance(item, (pp.Literal, pp.Keyword)):
			return unicode('`' + word_map.get(item.match) + '`' if item.match in word_map else item.match).upper()
		elif isinstance(item, (pp.Group, Grouping)):
			return '( %s )' % self.transform(item.expr)
		elif isinstance(item, pp.And):
			return ' '.join(self.transform(x) for x in item.exprs)
		elif isinstance(item, pp.Optional):
			return '[ %s ]' % self.transform(item.expr)
		elif isinstance(item, pp.OneOrMore):
			return '%s +' % self.transform(item.expr)
		elif isinstance(item, pp.ZeroOrMore):
			return '%s *' % self.transform(item.expr)
		elif isinstance(item, (pp.Forward, pp.Suppress)):
			return self.transform(item.expr)
		elif isinstance(item, (pp.MatchFirst, pp.Or)):
			return ' | '.join(self.transform(x) for x in item.exprs)
		return unicode(item)

	def to_jsgf(self):
		yield '#JSGF V1.0;'
		yield 'grammar hciplayer;'
		yield 'public <commands> = %s;' % self.transform(self.commands.parser, True)
		for name, rule in self.rules.items():
			yield '%s = %s;' % (self.transform(rule), self.transform(rule, True))



def parser(item, result):
	if item in ['play', 'pause', 'next', 'previous', 'replay', 'info', 'help', 'exit', 'tutorial']:
		return {'type': item}
	elif item in ['shuffle', 'repeat']:
		return {'type': item, 'args': result.get('stateValue', [''])[0]}
	elif item in ['playItems', 'queueItems', 'selectItems', 'listItems']:
		if 'filterValue' in result:
			args = [{
				'title': ' '.join(filter[0].get('filterTitle', [])),
				'artist': ' '.join(filter[0].get('filterArtist', [])),
				'albumTitle': ' '.join(filter[0].get('filterAlbum', []))
			} for filter in result._ParseResults__tokdict['filterValue']]
		else:
			args = list(result.get('selectorValue', []) or [''])

		return {'type': item, 'args': args}

import re

music_items = [{'album': u'A Rush of Blood to the Head', 'artist': u'Coldplay', 'title': u'Amsterdam'}, {'album': u'Evil Empire', 'artist': u'Rage Against the Machine', 'title': u'Bulls on Parade'},{'album': u'A Rush of Blood to the Head', 'artist': u'Coldplay', 'title': u'Clocks'}, {'album': u'A Rush of Blood to the Head', 'artist': u'Coldplay', 'title': u'Daylight'},{'album': u'Lateralus', 'artist': u'Tool', 'title': u'Disposition'}, {'album': u'Evil Empire', 'artist': u'Rage Against the Machine', 'title': u'Down Rodeo'},{'album': u'Lateralus', 'artist': u'Tool', 'title': u'Eon Blue Apocalypse'}, {'album': u'Lateralus', 'artist': u'Tool', 'title': u'Faaip de Oiad'},{'album': u'A Rush of Blood to the Head', 'artist': u'Coldplay', 'title': u'God Put a Smile Upon Your Face'}, {'album': u'A Rush of Blood to the Head', 'artist': u'Coldplay', 'title': u'Green Eyes'},{'album': u'Lateralus', 'artist': u'Tool', 'title': u'The Grudge'}, {'album': u'A Rush of Blood to the Head', 'artist': u'Coldplay', 'title': u'In My Place'},{'album': u'Lateralus', 'artist': u'Tool', 'title': u'Lateralus'}, {'album': u'Lateralus', 'artist': u'Tool', 'title': u'Mantra'}, {'album': u'Lateralus', 'artist': u'Tool', 'title': u'Parabol'},{'album': u'Lateralus', 'artist': u'Tool', 'title': u'Parabola'}, {'album': u'Lateralus', 'artist': u'Tool', 'title': u'The Patient'},{'album': u'Evil Empire', 'artist': u'Rage Against the Machine', 'title': u'People of the Sun'}, {'album': u'A Rush of Blood to the Head', 'artist': u'Coldplay', 'title': u'Politik'},{'album': u'Lateralus', 'artist': u'Tool', 'title': u'Reflection'}, {'album': u'Evil Empire', 'artist': u'Rage Against the Machine', 'title': u'Revolver'},{'album': u'Evil Empire', 'artist': u'Rage Against the Machine', 'title': u'Roll Right'}, {'album': u'A Rush of Blood to the Head', 'artist': u'Coldplay', 'title': u'A Rush of Blood to the Head'},{'album': u'Lateralus', 'artist': u'Tool', 'title': u'Schism'}, {'album': u'A Rush of Blood to the Head', 'artist': u'Coldplay', 'title': u'The Scientist'},{'album': u'Evil Empire', 'artist': u'Rage Against the Machine', 'title': u'Snakecharmer'}, {'album': u'Lateralus', 'artist': u'Tool', 'title': u'Ticks & Leeches'},{'album': u'Evil Empire', 'artist': u'Rage Against the Machine', 'title': u'Tire Me'}, {'album': u'Lateralus', 'artist': u'Tool', 'title': u'Triad'},{'album': u'Evil Empire', 'artist': u'Rage Against the Machine', 'title': u'Vietnow'}, {'album': u'A Rush of Blood to the Head', 'artist': u'Coldplay', 'title': u'Warning Sign'},{'album': u'A Rush of Blood to the Head', 'artist': u'Coldplay', 'title': u'A Whisper'}, {'album': u'Evil Empire', 'artist': u'Rage Against the Machine', 'title': u'Wind Below'},{'album': u'Evil Empire', 'artist': u'Rage Against the Machine', 'title': u'Without a Face'}, {'album': u'Evil Empire', 'artist': u'Rage Against the Machine', 'title': u'Year of tha Boomerang'}]
word_map = {'&':'and'}

artists = {}
titles = {}
albums = {}
for item in music_items:
    if item['artist'] not in artists:
        artist = artists[item['artist']] = {'name':item['artist'].lower(), 'albums':[], 'titles':[]}
    else:
        artist = artists[item['artist']]

    if item['album'] not in albums:
        album = albums[item['album']] = {'name':item['album'].lower(), 'artist':artist, 'titles':[]}
        artist['albums'].append(album)
    else:
        album = albums[item['album']]

    if item['title'] not in titles:
        title = titles[item['title']] = {'name':item['title'].lower(), 'artist':artist, 'album':album}
        album['titles'].append(title)
        artist['titles'].append(title)

def _(str):
    return re.sub('[\W]+', '', str).strip().lower()


rules = Rules(parser)

rules.commands['play'] = 'play'

rules.commands['pause'] = 'pause | stop'

rules.commands['next'] = '[ play ] next [ song | track ]'

rules.commands['previous'] = '[ play ] previous [ song | track ]'

rules.commands['replay'] = 'replay [ song | track ]'

rules.commands['info'] = r"what's playing | what is playing | now playing | info"

rules.commands['help'] = 'list available commands | help me | what can i say'

rules.commands['exit'] = 'exit'

rules.commands['tutorial'] = 'tutorial'

rules['state'] = '( on | off ) /stateValue | toggle'

rules.commands['shuffle'] = '[ set | turn | toggle ] shuffle [ <state> ]'

rules.commands['repeat'] = '[ set | turn | toggle ] repeat [ <state> ]'

rules['selectors'] = '[ selected | all ] /selectorValue [ songs | tracks | items ]'

for artist in artists.values():
	rules['hciplayer.%s' % ( _(artist['name']) )] = '( %s )' % artist['name']
	for album in artist['albums']:
		rules['hciplayer.%s.%s' % (_(album['artist']['name']), _(album['name']))] = '(%s)' % album['name']
		rules['hciplayer.%s.%s.titles' % (_(album['artist']['name']), _(album['name']))] = '( %s )' % (' | '.join([title['name'] for title in album['titles']]))




temp = '( %s | %s | %s ) /filterValue' % (
	' \n|\t '.join(['[song | track] %s /filterTitle [by [artist]  %s /filterArtist ] [ on [album] %s /filterAlbum ] ' % ( 
				'<hciplayer.%s.%s.titles>' % (_(album['artist']['name']), _(album['name'])), 
				'<hciplayer.%s>' % _(album['artist']['name']), 
				'<hciplayer.%s.%s>' % (_(album['artist']['name']), _(album['name'])) ) for album in albums.values()] ),
	' \n|\t '.join(['artist %s /filterArtist [ album %s /filterAlbum ] [ [song|track] %s /filterTitle ] ' % ( 
				'<hciplayer.%s>' % _(album['artist']['name']), 
				'<hciplayer.%s.%s>' % ( _(album['artist']['name']), _(album['name'])), 
				'<hciplayer.%s.%s.titles>' % ( _(album['artist']['name']), _(album['name']) ) ) for album in albums.values()] ),
	' \n|\t '.join(['album %s /filterAlbum [[song|track] %s /filterTitle ] ' % ( 
				'<hciplayer.%s.%s>' % (_(album['artist']['name']),_(album['name'])), 
				'<hciplayer.%s.%s.titles>' % (_(album['artist']['name']), _(album['name']))) for album in albums.values()] ),
)
print temp
rules['filters'] = temp

"""#
print 'asdf'
print artists.keys(), albums.keys(), titles.keys()


artists = ['coldplay', 'tool', 'rage against the machine']
albums = ['a rush of blood to the head', 'lateralus', 'evil empire']
titles = [
	'politik', 'in my place', 'god put a smile upon your face', 'the scientist', 'clocks', 'daylight', 'green eyes', 'warning sign', 'a whisper', 'a rush of blood to the head', 'amsterdam',
	'the grudge', 'eon blue apocalypse', 'the patient', 'mantra', 'schism', 'parabol', 'parabola', 'ticks and leeches', 'lateralus', 'disposition', 'reflection', 'triad', 'faaip de oiad',
	'people of the sun', 'bulls on parade', 'vietnow', 'revolver', 'snakecharmer', 'tire me', 'down rodeo', 'without a face', 'wind below', 'roll right', 'year of tha boomerang'
]
print artists, albums, titles
rules['artists'] = '( %s )' % (' | '.join(artists))
rules['albums'] = '( %s )' % (' | '.join(albums))
rules['titles'] = '( %s )' % (' | '.join(titles))

rules['flters'] = (
	[ song | track ] <titles> /filterTitle
	[ by [ artist ] <artists> /filterArtist ]
	[ on [ album ] <albums> /filterAlbum ]
|	artist <artists> /filterArtist
	[ album <albums> /filterAlbum ]
	[ [ song | track ] <titles> /filterTitle ]
|	album <albums> /filterAlbum
	[ [ song | track ] <titles> /filterTitle ]
) /filterValue
"""


rules.commands['playItems'] = '( put on | play | could you play ) ( <selectors> | ( <filters> [ and ] ) + )'

rules.commands['queueItems'] = '( queue | play next ) ( <selectors> | ( <filters> [ and ] ) + )'

rules.commands['selectItems'] = '( select | filter ) ( <selectors> | ( <filters> [ and ] ) + )'

rules.commands['listItems'] = 'list ( <selectors> | <filters> )'

if __name__ == '__main__':
	print
	print '========= JSGF FILE ============='
	print
	print '\n'.join(rules.to_jsgf())
	print
	print '============ END ================'
	print

	def test(a):
		print 'TEST:', repr(a)
		print '  ->', repr(rules.parse(a))
		print

	test('play next song')
	test('play')
	test('play all')
	test('what can i say')
	test('next')
	test('play artist coldplay')
	test('play selected songs')
	test('play album lateralus')
	test('queue song ticks `and` leeches')
	test('queue album evil empire')
	test('turn shuffle on')
	test('shuffle toggle')
	test('queue song green eyes')
	test('list')
	test('play artist coldplay and song lateralus album evil empire')
