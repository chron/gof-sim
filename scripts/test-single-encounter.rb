require '../lib/gof-sim'

#p GauntletOfFools::Encounter.all.size; exit
#p GauntletOfFools::Hero.all.map { |w| w.name.length }.sort.reverse[0,2]

p =	[
	#GauntletOfFools::Player.from_names('A', 'Alchemist', 'Mace'),
	#GauntletOfFools::Player.from_names('B', 'Armorer', 'Cleaver'),
	#GauntletOfFools::Player.from_names('C', 'Barbarian', 'Sword', 'With a Hangover'),
	GauntletOfFools::Player.from_names('K', 'Knight', 'Flaming Sword'),
	#GauntletOfFools::Player.from_names('D', 'Armsmaster', ['Throwing Stars', 'Staff'])
]


e = %w(Healing\ Pool Extra\ Bitey Mummy Witch Griffin).map { |n| GauntletOfFools::Encounter[n] }
GauntletOfFools::EncounterPhase.test_encounter(*e).run(*p)

#GauntletOfFools::EncounterPhase.new(:log => nil).run(*p)

#p.each { |e| puts '%20s %2i %3i' % [e.name, e.age, e.treasure] }


#p File.readlines('log.txt').grep(/dopp/i)

