require '../lib/gof-sim'

#p GauntletOfFools::Encounter.all[0].attack#.size; exit
#p GauntletOfFools::Hero.all.map { |w| w.name.length }.sort.reverse[0,2]

players = [
	#GauntletOfFools::Player.from_names('A', 'Alchemist', 'Mace'),
	#GauntletOfFools::Player.from_names('B', 'Armorer', 'Cleaver'),
	#GauntletOfFools::Player.from_names('C', 'Barbarian', 'Sword', 'With a Hangover'),
	GauntletOfFools::Player.from_names('A', 'Armorer', 'Flaming Sword'),
	GauntletOfFools::Player.from_names('N', 'Ninja', 'Axe')
	#GauntletOfFools::Player.from_names('Z', 'Zombie', 'Mace')
	#GauntletOfFools::Player.random,
	#GauntletOfFools::Player.random
	#GauntletOfFools::Player.from_names('D', 'Armsmaster', ['Throwing Stars', 'Staff'])
]


#e = %w(Giant\ Spider Healing\ Pool Extra\ Bitey Mummy Witch Griffin).map { |n| GauntletOfFools::Encounter[n] }
#GauntletOfFools::EncounterPhase.test_encounter(*e).run(*p)

g = GauntletOfFools::EncounterPhase.new(players) # (:log => nil)
g.start

limit = 0
until limit > 100 || g.finished?
	limit += 1
	players.each do |p|
		g.advance_until_event(p)
		p.decisions.each do |d| 
			r = p.decide(d.name)
			puts [p, d, r].inspect
			p.make_decision(d, r)
		end
	end
end
#p.each { |e| puts '%20s %2i %3i' % [e.name, e.age, e.treasure] }


#p File.readlines('log.txt').grep(/dopp/i)

