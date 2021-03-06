require '../lib/gof-sim'

ROUGH_SOLO_VALUATION = Hash.new do |h,(opt,prec)|
	h[[opt, prec]] = sim(prec, opt)[opt]
end

def sim(trials, *opts)

	results = Hash.new { |h,k| h[k] = [] }

	trials.times do |t|
		players = opts.map { |o| o.to_player("#{o.hero.name}#{[*o.weapons].map(&:name).join.tr(' ','')}") }
		GauntletOfFools::EncounterPhase.new(:log => nil).run(*players)

		players.each do |p|
			o = opts.find { |o| o.hero == p.hero && o.weapons == p.weapons && o.brags == p.brags }
			results[o] << p.treasure
		end
	end

	Hash[results.map { |k,v| [k, v.sum.to_f / v.size]}]
end

players = %w(One Two Three Four)
b = GauntletOfFools::BragPhase.new *players

players.cycle do |p|
	break if b.finished?
	next if b.player_assigned?(p)

	puts '%s choosing: ' % [p]
	choices = b.options.map { |o| o.current_owner ? o.with_any_new_brag : o.copy }.flatten
	rated_choices = choices.map { |c| [c, ROUGH_SOLO_VALUATION[[c, 500]]] }

	rated_choices.sort_by { |k,v| -v }.each_with_index { |(o,v),i| puts '%2i %5.2f %-p' % [i, v, o] }
	puts
	
	choice = rated_choices.max_by { |k,v| v }[0]
	puts '%s takes %s%s.' % [p, choice.hero, choice.brags.empty? ? '' : " with #{choice.brags*?,}"]
	puts

	b.bid p, choice, *choice.brags
end

=begin
t = 10000
r = Hash.new(0)
t.times do
	p = b.create_players
	GauntletOfFools::EncounterPhase.new.run(*p)
	p.each { |p| r[p.name] += p.treasure }
end
p r.map { |k,v| [k, v/t.to_f] }
=end

e = GauntletOfFools::EncounterPhase.new(:log => STDOUT)
players = b.create_players.sort_by { |p| players.index(p.name) }

players.each { |p| puts ' * %s' % [p] }

e.run(*players)

players.sort_by { |p| -p.treasure }.each do |p|
	puts '%3i %s (%i turn%s)' % [p.treasure, p.name, p.age, p.age==1 ? '' : 's']
end