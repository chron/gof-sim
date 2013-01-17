module GauntletOfFools
	class BragPhase
		attr_reader :player_names, :options

		def initialize *player_names
			@player_names = player_names
			n = player_names.size

			heroes = Hero.all.shuffle.take(n)
			weapons = Weapon.all.shuffle.take(n)

			@options = heroes.zip(weapons).map { |h,w| Option.new(h, w, nil, []) }
			@finished = false
		end

		def bid player, opt, *additional_brags
			raise "Brag phase over" if @finished
			raise "Unknown brag" if additional_brags.any? { |b| !BRAGS.include?(b) }
			raise "Already has something" if @options.any? { |o| o.current_owner == player }
			raise "Invalid player" unless @player_names.include?(player)

			new_brags = (opt.brags + additional_brags).uniq

			if !opt.is_assigned? || new_brags.size > opt.brags.size
				Logger.log "%s takes the %s%s" % [player, opt.hero.name, additional_brags.size>0 ? " adding #{additional_brags}" : '']
				opt.current_owner = player
				opt.brags += additional_brags
			end

			@finished = true if @options.all? { |o| o.is_assigned? }
		end

		def finished?
			@finished
		end

		def create_players
			raise  "phase not finished" unless @finished
			@options.map { |o| o.to_player }.shuffle # FIXME: shuffle?
		end
	end

	class EncounterPhase
		def initialize #encounter_seed=nil
			#srand(encounter_seed) if encounter_seed
			@encounters = Encounter.all.shuffle

			#srand if encounter_seed
		end

		def run *players
			raise "no players" if players.empty?

			active_players = players.dup

			@encounters.each_with_index do |encounter, i|
				Logger.log "Encounter %i: %s" % [i+1, encounter.display_name]

				active_players.each do |player|
					player.fight(encounter)
				end

				active_players.delete_if do |p|
					d = p.dead? 
					Logger.log("%s is defeated with %i coins." % [p.name, p.treasure]) if d
					d
				end
				break if active_players.empty?
			end

			players
		end
	end

	#puts
	#@players.sort_by { |p| -p.treasure }.each do |p| # TODO: tiebreaker?
	#	puts "%3i %10s | %-30s" % [p.treasure, p.name, "#{p.hero.name}/#{p.weapon.name} + #{p.brags}"]
	#end
end

games = (0...1000).map { GauntletOfFools::EncounterPhase.new }
results = Hash.new { |h,k| h[k] = Hash.new { |h2,k2| h2[k2] = []}}
brag_opts = [[], *GauntletOfFools::BRAGS]

combinations = GauntletOfFools::Hero.all.product(GauntletOfFools::Weapon.all).map do |h,w|
	n = "#{h.name}#{w.name.tr(' ','')}"
	opt = GauntletOfFools::Option.new(h, w, n, [])
end

combinations.each do |opt|
	brag_opts.each do |b| # *GauntletOfFools::BRAGS
		games.each do |g|
			opt.brags = [*b]
			p = opt.to_player
			g.run(p)
			results["#{p.hero}/#{p.weapon}"][b] << p.treasure
		end
	end
end

puts ('%50s' + (' %12s' * brag_opts.size)) % ['', *brag_opts]

# averages
results = results.to_a.map { |n,b| [n, b.map { |k,v| v.inject { |a,c| a + c}.to_f / v.size}] }

results.sort_by { |n,r| -r[0] }.each do |n,r|
	#o = r[0]
	#r.map! { |v| v / o }
	puts ('%50s' + (' %12.2f' * r.size)) % [n, *r]
end