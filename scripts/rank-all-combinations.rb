require '../lib/gof-sim'

total_trials = 500
results = Hash.new { |h,k| h[k] = [] }

combinations = GauntletOfFools::Hero.all.map do |h|
	weapons = GauntletOfFools::Weapon.all
	weapons = weapons.product(weapons).reject { |w1,w2| w1 == w2 }.map(&:sort).uniq if h.number_of_weapons == 2 # FIXME so dumb

	weapons.map do |w|
		n = "#{h.name}#{[*w].map(&:name).join.tr(' ','')}"
		opt = GauntletOfFools::Option.new(h, [*w], n, [])
	end
end.flatten
trials = (total_trials.to_f / combinations.size).ceil

puts "#{combinations.size} combinations, #{trials} trials per combination."

trials.times do |t|
	combinations.each do |opt|
		p = opt.to_player
		GauntletOfFools::EncounterPhase.new.run(p)
		results["#{p.hero}/#{p.weapons*','}"] << [p.treasure, p.age]
	end
end

results = results.to_a.map { |n,v| v1,v2 = v.transpose; [n, v1.mean, v1.stdev, v2.mean, v2.stdev] }

puts '%50s %12s %12s %12s %12s' % ['', '$ mean', '$ stdev', 'age mean', 'age stdev']
results.sort_by { |a| -a[1] }.each do |a|
	puts ('%50s %12.2f %12.2f %12.2f %12.2f') % a
end