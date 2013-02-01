require '../lib/gof-sim'

#p GauntletOfFools::Encounter.all.size; exit
#p GauntletOfFools::Hero.all.map { |w| w.name.length }.sort.reverse[0,2]

p =	[
	#GauntletOfFools::Player.from_names('A', 'Alchemist', 'Mace'),
	#GauntletOfFools::Player.from_names('B', 'Armorer', 'Cleaver'),
	#GauntletOfFools::Player.from_names('C', 'Barbarian', 'Sword', 'With a Hangover'),
	GauntletOfFools::Player.from_names('D', 'Monk', 'Sword')
]
#e = %w(Giant\ Toad Griffin).map { |n| GauntletOfFools::Encounter[n] }
#GauntletOfFools::EncounterPhase.test_encounter(*e).run(*p)

GauntletOfFools::EncounterPhase.new.run(*p)

#7p File.readlines('log.txt').grep(/one.use/i)