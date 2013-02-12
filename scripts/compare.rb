require '../lib/gof-sim'


results = Hash.new(0)

T = 100

T.times do |i|
	#print '.'
	#puts if (i+1)%50 == 0

	p =	[
		GauntletOfFools::Player.from_names('B', 'Barbarian', 'Flaming Sword'),
		GauntletOfFools::Player.from_names('Z', 'Zombie', 'Flaming Sword')
	]

	GauntletOfFools::EncounterPhase.new(:log => nil).run(*p)

	p.each { |e| results[e.name] += e.treasure }
end


results.each { |k,v| puts '%10s %5.2f' % [k, v.to_f / T] }