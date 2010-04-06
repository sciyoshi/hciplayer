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

class Rules(dict):
	def __setitem__(self, name, value):
		if name in self:
			self[name] << value
		else:
			value = value.setResultsName(name)
			value.setParseAction(lambda: {'type': name})
			super(Rules, self).__setitem__(name, value)

	def __getitem__(self, name):
		if name in self:
			return super(Rules, self).__getitem__(name)
		else:
			self[name] = value = pp.Forward()
			return value

	@property
	def commands(self):
		return pp.Or(self.values()).setResultsName('command')

	def parse(self, str):
		try:
			return self.commands.parseString(str)[0]
		except:
			return {}

	def transform(self, item, top=False):
		if item in self.values() and not top:
			return '<%s>' % item.resultsName
		elif isinstance(item, pp.Literal):
			return unicode(item.match).upper()
		elif isinstance(item, pp.And):
			return ' '.join(self.transform(x) for x in item.exprs)
		elif isinstance(item, pp.Optional):
			return '[ %s ]' % self.transform(item.expr)
		elif isinstance(item, pp.Group):
			return '( %s )' % self.transform(item.expr)
		elif isinstance(item, pp.Suppress):
			return self.transform(item.expr)
		elif isinstance(item, (pp.MatchFirst, pp.Or)):
			return ' | '.join(self.transform(x) for x in item.exprs)
		return unicode(item)

	def to_jsgf(self):
		yield '#JSGF V1.0;'
		yield 'grammar hciplayer;'
		yield 'public <commands> = %s;' % self.transform(self.commands, True)
		for name, rule in self.items():
			yield '%s = %s;' % (self.transform(rule), self.transform(rule, True))

			

artist_list = ['coldplay', 'tool', 'rage against the machine']
album_list = ['a rush of blood to the head', 'lateralus', 'evil empire']
title_list = [
	'politik', 'in my place', 'god put a smile upon your face', 'the scientist', 'clocks', 'daylight', 'green eyes', 'warning sign', 'a whisper', 'a rush of blood to the head', 'amsterdam',
	'the grudge', 'eon blue apocalypse', 'the patient', 'mantra', 'schism', 'parabol', 'parabola', 'ticks and leeches', 'lateralus', 'disposition', 'reflection', 'triad', 'faaip de oiad',
	'people of the sun', 'bulls on parade', 'vietnow', 'revolver', 'snakecharmer', 'tire me', 'down rodeo', 'without a face', 'wind below', 'roll right', 'year of tha boomerang'
]

rules = Rules()

rules['play'] = pL('play')

rules['pause'] = pG(pL('pause') | pL('stop'))

rules['next'] = pS(pO('play'), pL('next'), pO(pL('song') | pL('track')))

rules['previous'] = pS(pO('play'), pL('previous'), pO(pL('song') | pL('track')))

rules['replay'] = pL('replay') + pO(pL('song') | pL('track'))

rules['info'] = pP('what\'s playing') | pP('what is playing') | pP('now playing') | pP('info')

rules['help'] = pP('list available commands') | pP('help me') | pP('what can i say')

rules['exit'] = pP('exit')

rules['tutorial'] = pP('tutorial')

values = pG(pP('on') | pP('off') | pI(pP('toggle'))).setResultsName('value')

rules['shuffle'] = pO(pG(pP('set') | pP('turn') | pP('toggle'))) + pP('shuffle') + pO(values)
rules['repeat'] = pO(pG(pP('set') | pP('turn') | pP('toggle'))) + pP('repeat') + pO(values)
rules['listItems'] = pP('list') + pO(pP('selected'))+ pO(pG(pP('items') | pP('tracks') | pP('songs')))

artists = pG(pp.MatchFirst([pL(artist) for artist in artist_list])).setResultsName('artist')
albums = pG(pp.MatchFirst([pL(album) for album in album_list])).setResultsName('album')
titles = pG(pp.MatchFirst([pL(title) for title in title_list])).setResultsName('title')
	
#artists = pG(pP('coldplay') | pP('tool') | pP('rage against the machine')).setResultsName('artist')
#albums = pG(pP('a rush of blood to the head') | pP('lateralus') | pL('evil empire')).setResultsName('album')
#titles = pG(pL('clocks') | pL('green eyes') | pL('the grudge') | pL('bulls on parade')).setResultsName('title')



filter = pO( \
		pS(pO('all') +  pO(pG(pL('songs') | pL('tracks'))) ) \
	) + \
	pO( \
		pG(pP('by') | pP('from')) + \
		pO(pP('artist')) + \
		artists + \
		pO( \
			pG(pP('on') | pP('from')) + \
			pP('album') + albums
		) \
	)

select = pG( \
		pS( \
			pO( \
				pG(pP('song') | pP('track')) \
			) + \
			titles + \
			pO( \
				pP('by') + \
				pO('artist') + \
				artists \
			) + \
			pO( \
				pG(pP('on') | pP('from')) + \
				pO(pP('album')) + \
				albums \
			) \
		) | \
		pS( \
			pP('artist') + \
			artists +\
			pO( \
				pP('album') + \
				albums \
			) + \
			pO( \
				pG(pP('song') | pP('track')) + \
				titles \
			) \
		) | \
		pS( \
			pP('album') + \
			albums + \
			pO( \
				pG(pP('track') | pP('song')) + \
				titles
			) \
		) \
	).setResultsName('select')



rules['playItems'] = pS(pG(pP('put on') | pP('play') | pP('could you play')) + select)# + pO(pP('and') + select) + pO(pP('and') + select) + pO(pP('and') + select))
rules['selectItems'] = pG(pP('select') | pP('filter')) + select
rules['queueItems'] = pG(pP('queue') | pP('play next')) + select

def val(a):
	try:
		return str(a[0])
	except:
		return ''

def action(toks):
	return {'type':'playItems', 'args': [{'title': val(toks.select.title), 'albumTitle':val(toks.select.album), 'artist':val(toks.select.artist)},]}
rules['playItems'].setParseAction(action)

def action(toks):
	return {'type':'shuffle', 'args': val(toks.value)}
rules['shuffle'].setParseAction(action)

def action(toks):
	return {'type':'repeat', 'args': val(toks.value)}
rules['repeat'].setParseAction(action)

def action(toks):
	return {'type':'queueItems', 'args': [{'title': val(toks.select.title), 'albumTitle':val(toks.select.album), 'artist':val(toks.select.artist)},]}
rules['queueItems'].setParseAction(action)

def action(toks):
	return {'type':'selectItems', 'args': [{'title': val(toks.select.title), 'albumTitle':val(toks.select.album), 'artist':val(toks.select.artist)},]}
rules['selectItems'].setParseAction(action)

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
	test('play album lateralus')
	test('queue album evil empire')
	test('turn shuffle on')
	test('shuffle toggle')
	test('queue song green eyes')

