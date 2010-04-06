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

class Rules(object):
	def __init__(self):
		self.rules = {}

		ruleName = pp.Combine(pp.Suppress('<') + pp.Word(pp.alphanums) + pp.Suppress('>'))
		ruleName.setParseAction(lambda toks: self[toks[0]])

		expr = pp.Forward()

		seq = pp.Group(pp.delimitedList(expr, delim=pp.Empty()))
		seq.setParseAction(lambda toks: pp.And(toks[0]))

		self.rule = alt = pp.Group(pp.delimitedList(seq, delim='|'))
		alt.setParseAction(lambda toks: pp.Or(toks[0]))

		optExpr = pp.nestedExpr(opener='[', closer=']', content=alt)
		optExpr.setParseAction(lambda toks: pp.Optional(toks[0][0]))

		groupExpr = pp.nestedExpr(opener='(', closer=')', content=alt)
		groupExpr.setParseAction(lambda toks: pp.Group(toks[0][0]))

		word = pp.Word(pp.alphanums + r"'\"")
		word.setParseAction(lambda toks: pp.Suppress(pp.Keyword(toks[0])))

		expr << pp.Or([ruleName, optExpr, groupExpr, word])

	def __setitem__(self, name, value):
		manual = False

		if isinstance(name, tuple):
			name, manual = name
		elif not isinstance(value, (str, unicode)):
			manual = True

		if isinstance(value, (str, unicode)):
			value = self.rule.parseString(value)[0].setResultsName(name)

		if not manual:
			value = value.setResultsName(name)
			value.setParseAction(lambda: {'type': name})

		if name in self.rules:
			self.rules[name] << value
		else:
			self.rules[name] = value

	def __getitem__(self, name):
		if name in self.rules:
			return self.rules[name]
		else:
			self.rules[name] = pp.Forward().setResultsName(name)
			self.rules[name].setParseAction(lambda: {'type': name})
			return self.rules[name]

	def __delitem__(self, name):
		del self.rules[name]

	@property
	def commands(self):
		return pp.Or(self.rules.values()).setResultsName('command')

	def parse(self, str):
		try:
			return self.commands.parseString(str)[0]
		except:
			return {}

	def transform(self, item, top=False):
		if item in self.rules.values() and not top:
			return '<%s>' % item.resultsName
		elif isinstance(item, (pp.Literal, pp.Keyword)):
			return unicode(item.match).upper()
		elif isinstance(item, pp.And):
			return ' '.join(self.transform(x) for x in item.exprs)
		elif isinstance(item, pp.Optional):
			return '[ %s ]' % self.transform(item.expr)
		elif isinstance(item, pp.Group):
			return '( %s )' % self.transform(item.expr)
		elif isinstance(item, (pp.Suppress, pp.Forward)):
			return self.transform(item.expr)
		elif isinstance(item, (pp.MatchFirst, pp.Or)):
			return ' | '.join(self.transform(x) for x in item.exprs)
		return unicode(item)

	def to_jsgf(self):
		yield '#JSGF V1.0;'
		yield 'grammar hciplayer;'
		yield 'public <commands> = %s;' % self.transform(self.commands, True)
		for name, rule in self.rules.items():
			yield '%s = %s;' % (self.transform(rule), self.transform(rule, True))


artist_list = ['coldplay', 'tool', 'rage against the machine']
album_list = ['a rush of blood to the head', 'lateralus', 'evil empire']
title_list = [
	'politik', 'in my place', 'god put a smile upon your face', 'the scientist', 'clocks', 'daylight', 'green eyes', 'warning sign', 'a whisper', 'a rush of blood to the head', 'amsterdam',
	'the grudge', 'eon blue apocalypse', 'the patient', 'mantra', 'schism', 'parabol', 'parabola', 'ticks and leeches', 'lateralus', 'disposition', 'reflection', 'triad', 'faaip de oiad',
	'people of the sun', 'bulls on parade', 'vietnow', 'revolver', 'snakecharmer', 'tire me', 'down rodeo', 'without a face', 'wind below', 'roll right', 'year of tha boomerang'
]

rules = Rules()

rules['play'] = 'play'

rules['pause'] = 'pause | stop'

rules['next'] = '[ play ] next [ song | track ]'

rules['previous'] = '[ play ] previous [ song | track ]'

rules['replay'] = 'replay [ song | track ]'

rules['info'] = r"what's playing | what is playing | now playing | info"

rules['help'] = 'list available commands | help me | what can i say'

rules['exit'] = 'exit'

rules['tutorial'] = 'tutorial'

rules['value'] = pG(pP('on') | pP('off') | pI(pP('toggle'))).setResultsName('value')

rules['shuffle'] = '[ set | turn | toggle ] shuffle [ <value> ]'
rules['shuffle'].setParseAction(lambda toks: {'type': 'shuffle', 'args': toks.value[0] if toks.value else ''})

rules['repeat'] = '[ set | turn | toggle ] repeat <value>'
rules['repeat'].setParseAction(lambda toks: {'type': 'repeat', 'args': toks.value[0] if toks.value else ''})

del rules['value']

rules['artists'] = pG(pp.MatchFirst([pL(artist) for artist in artist_list])).setResultsName('artists')
rules['albums'] = pG(pp.MatchFirst([pL(album) for album in album_list])).setResultsName('albums')
rules['titles'] = pG(pp.MatchFirst([pL(title) for title in title_list])).setResultsName('titles')

rules['selectors', True] = (pG(pO(pP('selected') | pP('all'))) + pO(pP('songs') | pP('tracks') | pP('items'))).setResultsName('selectors')

rules['selectors'].setParseAction(lambda toks: [toks[0] if toks[0] else ''])

rules['filters', True] = """(
	[ song | track ] <titles>
	[ by [ artist ] <artists> ]
	[ on [ album ] <albums> ]
) | (
	artist <artists>
	[ album <albums> ] 
	[ [ song | track ] <albums> ]
) | (
	album <albums>
	[ [ song | track ] <albums> ]
)"""

rules['filters'].setParseAction(lambda toks: [{
	'title': toks.filters.titles[0] if toks.filters.titles else '',
	'albumTitle': toks.filters.albums[0] if toks.filters.albums else '',
	'artist': toks.filters.artists[0] if toks.filters.artists else ''
}] if toks else [()])

rules['playItems'] = '( put on | play | could you play ) ( <selectors> | <filters> )'
rules['playItems'].setParseAction(lambda toks: {
	'type': 'playItems',
	'args': [toks[1].filters] if toks[1].filters else toks[1].selectors[0]
})

rules['queueItems'] = '( queue | play next ) ( <selectors> | <filters> )'
rules['queueItems'].setParseAction(lambda toks: {
	'type': 'queueItems',
	'args': [toks[1].filters] if toks[1].filters else toks[1].selectors[0]
})

rules['selectItems'] = '( select | filter ) ( <selectors> | <filters> )'
rules['selectItems'].setParseAction(lambda toks: {
	'type': 'selectItems',
	'args': [toks[1].filters] if toks[1].filters else toks[1].selectors[0]
})

rules['listItems'] = '( list ) ( <selectors> | <filters> )'
rules['listItems'].setParseAction(lambda toks: {
	'type': 'listItems',
	'args': [toks[1].filters] if toks[1].filters else toks[1].selectors[0]
})

del rules['artists']
del rules['albums']
del rules['titles']
del rules['selectors']
del rules['filters']

if __name__ == '__main__':
	print
	print '========= JSGF FILE ============='
	print
	print '\n'.join(rules.to_jsgf())
	print
	print '============ END ================'
	print

	def test(a):
		print 'Parsing', repr(a)
		print str(rules.parse(a))

	test('play next song')
	test('play')
	test('what can i say')
	test('next')
	test('play artist coldplay')
	test('play selected songs')
	test('play album lateralus')
	test('queue album evil empire')
	test('turn shuffle on')
	test('shuffle toggle')
	test('queue song green eyes')
	test('list')

