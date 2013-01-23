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

		def bid player, opt, *additional_brags # FIXME: check for duplicates
			opt = opt.parent_opt if opt.parent_opt

			raise "Brag phase over" if @finished
			raise "Unknown brag" if additional_brags.any? { |b| !BRAGS.include?(b) }
			raise "Invalid player" unless @player_names.include?(player)
			raise "Already has something" if player_assigned?(player)
			raise "Cannot remove brags" if (opt.brags - additional_brags).size > 0
			raise "Add brags" if opt.is_assigned? && additional_brags.size <= opt.brags.size

			Logger.log "%s takes the %s%s" % [player, opt.hero.name, additional_brags.size>0 ? " adding #{additional_brags}" : '']
			opt.current_owner = player
			opt.brags = additional_brags

			@finished = true if @options.all? { |o| o.is_assigned? }
		end

		def player_assigned? player
			@options.any? { |o| o.current_owner == player }
		end

		def finished?
			@finished
		end

		def create_players
			raise  "phase not finished" unless @finished
			@options.map { |o| o.to_player }
		end
	end

	class EncounterPhase
		def self.test_encounter e
			obj = new
			obj.instance_eval { @encounters = [e] }
			obj
		end

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
				
				@current_encounter = encounter

				if !encounter.instant
					players.each do |p|
						Logger.log ' * %s %s/%s (%s) -> $%i' % [p.name, p.hero.name, p.weapon.name, p.dead? ? 'dead' : p.wounds, p.treasure]
					end
				end

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

		def run_hooks hook_name
			[@current_encounter,@current_player.hero,@current_player.weapon].map do |obj| 
				obj && proc=obj.call_hook(hook_name, @current_player, @current_encounter)
			end.compact
		end

		def fight player, encounter
			@current_player = player
			player.current_encounter = encounter
			
			if !encounter.instant
				player.begin_turn # FIXME: turn != encounter
				run_hooks(:before_encounter)
			end

			if encounter.hooks?(:modifies_next_encounter) || encounter.hooks?(:instead_of_combat)
				encounter.call_hook(:instead_of_combat, player)
					
				if encounter.hooks?(:modifies_next_encounter)
					@encounter_mods[player] << encounter #.call_hook(:modifies_next_encounter)
				end
			else
				if @encounter_mods[player].size > 0
					@current_encounter = encounter = encounter.dup # FIXME
					@encounter_mods[player].each { |e| e.call_hook(:modifies_next_encounter, encounter) }
					@encounter_mods[player].clear
				end

				run_hooks(:before_rolling)

				if player.kill_next
					Logger.log "%s kills %s using a power." % [player.name, encounter.name]
					killed = true
					player.kill_next = false
				else 
					dice_result = player.roll(player.attack_dice)
					modified_dice_result = dice_result.reject { |d| player.brags.include?(:one_arm) && d <= 2 }

					total_attack = if player.weapon.hooks?(:attack_calc)
						player.weapon.call_hook(:attack_calc, modified_dice_result, player.bonus_attack, player.attack_factor)
					else
						(modified_dice_result.sum + player.bonus_attack) * player.attack_factor
					end

					hit_chance = 100 * if player.weapon.hooks?(:hit_chance_calc)
						player.weapon.call_hook(:hit_chance_calc, player, encounter.defense)
					else
						player.chance_to_hit(encounter.defense)
					end

					Logger.log "%s attacks %s (%.2f%% chance) => %id6%+i%s = %p = %i" % [
						player.name, encounter.name, hit_chance, player.attack_dice, player.bonus_attack, player.attack_factor == 1 ? '' : "*#{player.attack_factor}", dice_result, total_attack
					]
					killed = total_attack >= encounter.defense
				end

				if killed
					Logger.log "%s has slain %s!" % [player.name, encounter.name]
					player.gain(:killed_this_round) 
				else
					Logger.log "%s misses %s." % [player.name, encounter.name]
				end

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
					if player.hero.call_hook(:instead_of_damage, player, encounter)
						Logger.log "%s uses a power instead of taking damage." % [player.name]
					else
						damage_multiplier = 2 ** player.effects.count(:take_double_damage)
						player.wound(encounter.damage * damage_multiplier) if encounter.damage > 0

						damage_multiplier.times { run_hooks(:extra_damage) } # FIXME: text
					end
				else
					Logger.log "%s dodges." % [player.name]
				end

				player.gain(:dodged_this_round) if !encounter_hits

				if killed
					if player.hero.call_hook(:instead_of_treasure, player) # FIXME
						Logger.log("%s uses a power instead of gaining treasure." % [player.name]) # FIXME
					else
						loot = encounter.treasure
						loot -= 1 if player.brags.include?(:blindfold) && !encounter_hits

						player.gain_treasure(loot) if loot > 0
						run_hooks(:extra_treasure)
					end

					if player.has? :hangover
						player.bonus_dice += 1
						player.bonus_defense += 2
						player.clear_effect :hangover

						Logger.log "%s has recovered from his hangover!" % [player.name]
					end
				end

				if !encounter.instant
					player.wound(1) if player.has? :poison
					run_hooks(:after_encounter) 
				end

				player.current_encounter = nil
			end
		end
	end
end
