$:<<?.
require 'gof-sim/support'
require 'gof-sim/weapon'
require 'gof-sim/hero'
require 'gof-sim/encounter'
require 'gof-sim/basic-ai'
require 'gof-sim/player'
require 'gof-sim/gof'

=begin
# Number of encounters that can hit x armor
combats = GauntletOfFools::Encounter.all.select { |e| e[:attack] }
t = combats.size
0.upto(30) do |armor|
	n = combats.select { |e| e.attack >= armor }.size
	puts '%2i %s' % [armor, ?# * (n.to_f/t * 77)]
end
exit
=end

=begin
p = GauntletOfFools::Player.new('Tester', GauntletOfFools::Hero['Alchemist'], GauntletOfFools::Weapon['Sack of Loot'], [])
e = GauntletOfFools::Encounter['Gargoyle']
GauntletOfFools::EncounterPhase.test_encounter(e).run(p)
exit
=end

=begin
def sim(trials, *opts)
	results = Hash.new { |h,k| h[k] = [] }

	trials.times do |t|
		players = opts.map { |o| o.to_player("#{o.hero.name}#{o.weapon.name.tr(' ', '')}") }
		GauntletOfFools::EncounterPhase.new.run(*players)

		players.each do |p|
			# FIXME: dumb
			o = opts.find { |o| o.hero == p.hero && o.weapon == p.weapon && o.brags == p.brags }
			results[o] << p.treasure
		end
	end

	Hash[results.map { |k,v| [k, v.sum.to_f / v.size]}]
end

players = %w(One Two Three Four)
b = GauntletOfFools::BragPhase.new *players

GauntletOfFools::Logger.logging = false
players.cycle do |p|
	break if b.finished?
	next if b.player_assigned?(p)

	puts '%s choosing: ' % [p]
	choices = b.options.map { |o| o.current_owner ? o.with_any_new_brag : o.copy }.flatten
	rated_choices = sim(100, *choices) #choices.map { |c| [c, 10]}.sort_by { |k,v| -v }

	rated_choices.sort_by { |k,v| -v }.each_with_index { |(o,v),i| puts '%2i %5.2f %-p' % [i, v, o] }
	puts

	choice = rated_choices.max_by { |k,v| v }[0]
	puts '%s chooses %s + %p.' % [p, choice.hero, choice.brags]
	puts

	b.bid p, choice, *choice.brags
end
GauntletOfFools::Logger.logging = true

e = GauntletOfFools::EncounterPhase.new
players = b.create_players

players.each { |p| puts ' * %s' % [p] }

e.run(*players)

players.sort_by { |p| -p.treasure }.each do |p|
	puts '%i %s' % [p.treasure, p.name, p]
end
=end

trials = 200
results = Hash.new { |h,k| h[k] = Hash.new { |h2,k2| h2[k2] = []}}
brag_opts = [[]] #, *GauntletOfFools::BRAGS]

combinations = GauntletOfFools::Hero.all.product(GauntletOfFools::Weapon.all).map do |h,w| # .select { |w| w.name == 'Axe'}
	n = "#{h.name}#{w.name.tr(' ','')}"
	opt = GauntletOfFools::Option.new(h, w, n, [])
end

trials.times do |t|
	brag_opts.each do |b|
		players = combinations.map { |opt| opt.brags = [*b]; opt.to_player }
		#GauntletOfFools::EncounterPhase.new.run(*players)
		#players.each { |p| results["#{p.hero}/#{p.weapon}"][b] << p.treasure }

		players.each do |p|
			GauntletOfFools::EncounterPhase.new.run(p)
			results["#{p.hero}/#{p.weapon}"][b] << p.treasure
		end
	end
end

puts ('%50s' + (' %12s' * brag_opts.size)) % ['', *brag_opts]

# averages
results = results.to_a.map { |n,b| [n, b.map { |k,v| [v.mean, v.stdev]}] }

results.sort_by { |n,r| -r[0][0] }.each do |n,r|
	#o = r[0]
	#r.map! { |v| v / o }
	puts ('%50s' + (' %12.2f %12.2f' * r.size)) % [n, *r.flatten]
end