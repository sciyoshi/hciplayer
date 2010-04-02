import pyparsing as pp

pL = pp.Literal
pS = lambda *args: pp.And(args)
pP = lambda str: pp.And([pL(x) for x in str.split()])
pO = pp.Optional

class Rules(dict):
	def __setitem__(self, name, value):
		if name in self:
			pass
		else:
			super(Rules, self).__setitem__(name, value.setResultsName(name))

	def __getitem__(self, name):
		if name in self:
			return super(Rules, self).__getitem__(name)
		else:
			self[name] = value = pp.Forward()
			return value

	def transform(self, item, top=False):
		if item in self.values() and not top:
			return '<%s>' % item.resultsName
		elif isinstance(item, pp.Literal):
			return unicode(item.match)
		elif isinstance(item, pp.And):
			return ' '.join(self.transform(x) for x in item.exprs)
		elif isinstance(item, pp.Optional):
			return '[ %s ]' % self.transform(item.expr)
		elif isinstance(item, pp.MatchFirst):
			return ' | '.join(self.transform(x) for x in item.exprs)
		return unicode(item)

	def to_jsgf(self):
		yield '#JSGF V1.0;'
		yield 'grammar hciplayer;'
		for name, rule in self.items():
			yield '%s%s = %s;' % ('public ' if name == 'commandList' else '', self.transform(rule), self.transform(rule, True))

rules = Rules()

rules['play'] = pL('play')

rules['pause'] = pL('pause') | pL('stop')

rules['next'] = pS(pO('play'), pL('next'), pO(pL('song') | pL('track')))

rules['previous'] = pS(pO('play'), pL('previous'), pO(pL('song') | pL('track')))

rules['replay'] = pL('replay') + pO(pL('song') | pL('track'))

rules['info'] = pP('what\'s playing') | pP('what is playing') | pP('now playing') | pP('info')

rules['help'] = pP('list available commands') | pP('help me') | pP('what can i say')

rules['filter'] = pO(pS(pO('all'), pO(pL('songs') | pL('tracks'))))

rules['commandList'] = pp.MatchFirst([rules[x] for x in ['play', 'pause', 'next', 'previous', 'replay', 'info', 'help', 'filter']])

library = [
	('radiohead', 'kid a', 'everything in it\'s right place'),
	('radiohead', 'kid a', 'kid a'),
]

rules

"""

<artist>
<album>
songs by <artist>
songs by <artist> on <album>
songs on <album> by <artist>

song|track <track>
song|track <track> by artist
song|track <track> by artist on album

"""

print '\n'.join(rules.to_jsgf())
