require '../lib/gof-sim'

#p GauntletOfFools::Encounter.all.size; exit
#p GauntletOfFools::Hero.all.map { |w| w.name.length }.sort.reverse[0,2]

#GauntletOfFools::EncounterPhase.new.run(GauntletOfFools::Player.from_names('Tester', 'Artificer', 'Dagger'))
#exit

p =	[
	GauntletOfFools::Player.from_names('Adv', 'Adventurer', 'Cleaver')
]
e = %w(Giant\ Toad Griffin).map { |n| GauntletOfFools::Encounter[n] }
GauntletOfFools::EncounterPhase.test_encounter(*e).run(*p)
