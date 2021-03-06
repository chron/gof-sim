require '../lib/gof-sim'

total_seconds = 60 * 60 * 3
players_per_game = 4

results = Hash.new { |h,k| h[k] = [] }

combinations = GauntletOfFools::Hero.all.reject { |h| h.name == 'Armsmaster' }.map do |h| # .select { |h| h.name == 'Ninja' }
	weapons = GauntletOfFools::Weapon.all
	weapons = weapons.product(weapons).reject { |w1,w2| w1 == w2 }.map(&:sort).uniq if h.number_of_weapons == 2

	weapons.map do |w|
		GauntletOfFools::Option.new(h, [*w], 'Nameless', [])
	end
end.flatten

start_time = Time.now

until (Time.now - start_time >= total_seconds)
	combinations.shuffle.each_slice(players_per_game) do |opts|
		players = opts.map(&:to_player)
		GauntletOfFools::EncounterPhase.new(:log => nil).run(*players)
		players.each { |p| results["#{p.hero}/#{p.weapons*?+}"] << p.treasure } # treasure weapon_tokens hero_tokens
	end
end


display = results.map { |n,v| [*n.split(?/), v.mean, v.median, v.stdev, v.min, v.max, v.size] }

puts '%11s %-28s %6s %6s %6s %3s %3s %5s' % ['hero', 'weapon', 'mean', 'median', 'stdev', 'min', 'max', 'n']
display.sort_by { |a| -a[2] }.each do |a|
	puts '%11s %-28s %6.2f %6.2f %6.2f %3i %3i %5i' % a
end

display_by_hero = results.inject(Hash.new { |h,k| h[k] = [] }) { |h,d| h[d[0][/(.+)\//, 1]].concat(d[1]); h }.map { |n,v| [*n, v.mean, v.median, v.stdev, v.min, v.max, v.size] }

puts '%11s %-28s %6s %6s %6s %3s %3s %5s' % ['hero', '', 'mean', 'median', 'stdev', 'min', 'max', 'n']
display_by_hero.sort_by { |a| -a[1] }.each do |a|
	puts '%11s                              %6.2f %6.2f %6.2f %3i %3i %5i' % a
end

# ignores armsmaster currently
display_by_weapon = results.reject { |k,v| k =~ /^Armsmaster/ }.inject(Hash.new { |h,k| h[k] = [] }) { |h,d| h[d[0][/\/(.+)/, 1]].concat(d[1]); h }.map { |n,v| [*n, v.mean, v.median, v.stdev, v.min, v.max, v.size] }

puts '%11s %-28s %6s %6s %6s %3s %3s %5s' % ['', 'weapon', 'mean', 'median', 'stdev', 'min', 'max', 'n']
display_by_weapon.sort_by { |a| -a[1] }.each do |a|
	puts '            %-28s %6.2f %6.2f %6.2f %3i %3i %5i' % a
end
