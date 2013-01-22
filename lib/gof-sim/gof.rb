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
			@encounter_mods = Hash.new { |h,k| h[k] = [] }
			#srand if encounter_seed
			@current_player, @current_encounter = nil, nil
		end

		def run *players
			raise "no players" if players.empty?

			players.each do |p| # FIXME: move this
				@current_player = p
				run_hooks(:at_start)
			end

			active_players = players.dup

			Logger.log('New dungeon: %s' % [players.map(&:name)*'/'])

			@encounters.each_with_index do |encounter, i|
				Logger.log "Encounter %i: %s" % [i+1, encounter.display_name]

				active_players.each do |player|
					fight(player, encounter)
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

		def hooks? hook_name
			[@current_encounter,@current_player.hero,@current_player.weapon].find do |obj|
				obj && obj[hook_name]
			end
		end

		def run_hooks hook_name
			[@current_encounter,@current_player.hero,@current_player.weapon].map do |obj| 
				if obj && proc=obj[hook_name]
					proc[@current_player, @current_encounter]
				end
			end.compact
		end

		def fight player, encounter
			encounter = encounter.dup
			@current_player, @current_encounter = player, encounter

			player.begin_turn # FIXME: turn != encounter

			if encounter[:modifies_next_encounter] || encounter[:instead_of_combat]
				encounter.instead_of_combat[player] if encounter[:instead_of_combat]
					
				if encounter[:modifies_next_encounter]
					@encounter_mods[player] << encounter[:modifies_next_encounter]
				end
			else
				if @encounter_mods[player].size > 0
					@current_encounter = encounter = encounter.dup # FIXME
					@encounter_mods[player].each { |m| m[encounter] }
					@encounter_mods[player].clear
				end

				run_hooks(:before_rolling)

				if player.kill_next
					Logger.log "%s kills %s." % [player.name, encounter.name]
					killed = true
					player.kill_next = false
				else 
					dice_result = player.roll(player.attack_dice)
					modified_dice_result = dice_result.reject { |d| player.brags.include?(:one_arm) && d <= 2 }

					total_bonus = player.bonus_attack + run_hooks(:bonus_damage).sum

					total_attack = if player.weapon[:damage_calc]
						player.weapon[:damage_calc][modified_dice_result, total_bonus] 
					else
						modified_dice_result.sum + total_bonus
					end

					Logger.log "%s attacks %s => %id6+%i = %p = %i" % [player.name, encounter.name, player.attack_dice, total_bonus, dice_result, total_attack]
					killed = total_attack >= encounter.defense
				end

				player.gain(:killed_this_round) if killed
				run_hooks(:after_attack)

				if player.dodge_next
					encounter_hits = false
					player.dodge_next = false
				else
					encounter_hits = encounter.attack >= player.defense
				end

				# FIXME: still displays on autododge
				Logger.log "%s attacks for %i. %s defense is %i." % [encounter.name, encounter.attack, player.name, player.defense]

				if encounter_hits
					damage_multiplier = 2 ** player.effects.count(:take_double_damage)
					player.wound(encounter.damage * damage_multiplier) if encounter.damage > 0

					damage_multiplier.times { run_hooks(:extra_damage) } # FIXME: text
				else
					Logger.log "%s dodges." % [player.name]
				end

				player.gain(:dodged_this_round) if !encounter_hits

				if killed
					Logger.log "%s has slain %s!" % [player.name, encounter.name]

					if player.hero[:instead_of_treasure] && player.hero[:instead_of_treasure][player] # FIXME
						Logger.log("%s uses a power instead of gaining treasure." % [player.name]) # FIXME
					else
						loot = encounter.treasure
						loot -= 1 if player.brags.include?(:blindfold) && !encounter_hits

						player.gain_treasure(loot) if loot > 0
						run_hooks(:extra_treasure)
					end

					if player.effects.include? :hangover
						player.bonus_dice += 1
						player.bonus_defense += 2
						player.clear_effect :hangover

						Logger.log "%s has recovered from his hangover!" % [player.name]
					end
				else
					Logger.log "%s misses %s." % [player.name, encounter.name]
				end

				if !encounter.instant
					player.wound(1) if player.has? :poison
					run_hooks(:after_encounter) 
				end

				player.end_turn
			end
		end
	end

	#puts
	#@players.sort_by { |p| -p.treasure }.each do |p| # TODO: tiebreaker?
	#	puts "%3i %10s | %-30s" % [p.treasure, p.name, "#{p.hero.name}/#{p.weapon.name} + #{p.brags}"]
	#end
end

trials = 100
results = Hash.new { |h,k| h[k] = Hash.new { |h2,k2| h2[k2] = []}}
brag_opts = [[]] #, *GauntletOfFools::BRAGS]

combinations = GauntletOfFools::Hero.all.product(GauntletOfFools::Weapon.all).map do |h,w|
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