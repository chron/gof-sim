require '../lib/gof-sim'

#p GauntletOfFools::Encounter.all.size; exit

p =	[
	GauntletOfFools::Player.from_names('Zombie', 'Zombie', 'Mace', ['With One Arm Tied', 'Without Breakfast']),
	GauntletOfFools::Player.from_names('AM', 'Armsmaster', ['Deadly Fists', 'Demonic Blade'])
]
e = %w(Giant\ Spider Giant\ Scorpion Gopher Unicorn Ogre Minotaur).map { |n| GauntletOfFools::Encounter[n] }
GauntletOfFools::EncounterPhase.test_encounter(*e).run(*p)
