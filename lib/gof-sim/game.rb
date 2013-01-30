module GauntletOfFools
	class BragPhase
		attr_reader :player_names, :options

		def initialize *player_names
			@player_names = player_names

			# FIXME: ever any reason to keep these?
			hero_deck = Hero.all.shuffle
			weapon_deck = Weapon.all.shuffle

			@options = @player_names.inject([]) do |a,n|
				hero = hero_deck.pop
				weapons = weapon_deck.pop(hero.number_of_weapons)

				a + [Option.new(hero, weapons, nil, [])]
			end

			@finished = false
		end

		def bid player, opt, *additional_brags # FIXME: check for duplicates
			opt = opt.parent_opt if opt.parent_opt

			raise "Brag phase over" if @finished
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
		def self.test_encounter *e
			obj = new
			obj.instance_eval { @encounters = e }
			obj
		end

		def initialize
			@encounters = Encounter.all.shuffle
		end

		def draw_encounter
			a = []

			until (a.last && !a.last.instant)
				return [] if @encounters.empty?
				a << @encounters.shift
			end

			[a.pop.dup, a]
		end

		def run *players
			raise "no players" if players.empty?

			dead_players = []
			current_mods = []
			turn = 0

			players.each do |p| 
				p.opponents = players.reject { |o| o == p }
				p.run_hook(:at_start) 
			end

			Logger.log('New dungeon: %s' % [players.map(&:name)*'/'])

			until @encounters.empty?
				encounter, encounter_mods = *draw_encounter
				break if encounter.nil?

				current_mods += encounter_mods

				if !encounter.non_combat?
					current_mods.each { |em| em.call_hook(:modifies_next_encounter, encounter) }
					current_mods.clear
				end

				turn += 1

				Logger.log "Turn %i: %s" % [turn, encounter.display_name]

				players.each do |p|
					Logger.log ' * %s (%s) -> $%i' % [p, p.dead? ? 'dead' : p.wounds, p.treasure]
				end

				players.each do |player|
					player.run_hook(:encounter_while_dead) if player.dead?
					next if player.dead?

					player.begin_turn
					player.queue_fight(encounter)

					until player.fight_queue.empty?
						new_encounter = player.fight_queue.shift || draw_encounter.first
						break if new_encounter.nil?
						new_encounter.call_hook(:encounter_selection, self)

						Logger.log ('%s vs %s (%.2f%% chance to hit)') % [player.name, new_encounter.name, 100 * player.chance_to_hit(new_encounter.defense)] if !new_encounter.non_combat?
						fight(player, new_encounter)
					end
				end

				(players.select { |p| p.dead? } - dead_players).each do |p|
					dead_players << p
					Logger.log("%s is defeated at age %i with %i coins." % [p.name, p.age, p.treasure])
				end

				break if players.all? { |p| p.dead? }
			end

			players
		end

		def fight player, encounter
			player.current_encounter = encounter
			
			if player.has? :optional_encounter
				if !player.decide(:visit_encounter)
					player.gain(:skip_encounter) # FIXME: does this run before/after hooks?
				end
			end

			player.run_hook(:before_encounter)

			if player.has? :skip_encounter
				Logger.log '%s skips the encounter completely.' % [player.name]
			else
				if encounter.hooks?(:instead_of_combat) # FIXME: could this be used for wizard?
					encounter.call_hook(:instead_of_combat, player)
				else
					player.run_hook(:before_rolling) # FIXME: one-use dice go hereish

					player_hits = if player.has? :kill_next
						Logger.log "%s kills %s using a power." % [player.name, encounter.name]
						player.clear_effect :kill_next
						true
					else 
						dice_roll = player.roll(player.attack_dice)
						dice_result = player.run_hook(:after_rolling, dice_roll)

						# FIXME: better way to manage this than checking :kill_next twice?
						if player.has? :kill_next
							Logger.log "%s kills %s using a power." % [player.name, encounter.name]
							player.clear_effect :kill_next
							true
						else
							total_attack = player.calculate_attack(dice_result)

							Logger.log "%s attacks %s => %s%p%+i = %i" % [
								player.name, encounter.name, player.attack_factor == 1 ? '' : "#{player.attack_factor}*", dice_result.sort, player.bonus_attack, total_attack
							]

							total_attack >= encounter.defense
						end
					end

					if player_hits
						Logger.log "%s has slain %s!" % [player.name, encounter.name]
						player.gain(:killed_this_round) 
					else
						Logger.log "%s misses %s." % [player.name, encounter.name]
					end

					player.run_hook(:after_attack)

					encounter_hits = if player.has? :dodge_next
						false
					else
						Logger.log "%s attacks for %i. %s defense is %i." % [encounter.name, encounter.attack, player.name, player.defense]
						encounter.attack >= player.defense
					end

					player.gain(:dodged_this_round) if !encounter_hits

					if player_hits
						if player.hero.call_hook(:instead_of_treasure, player) # FIXME
							Logger.log("%s uses a power instead of gaining treasure." % [player.name]) # FIXME
						else
							loot = encounter.treasure
							loot -= 1 if player.has?(:blindfolded) && !player.has?(:ignore_brags) && !encounter_hits

							player.gain_treasure(loot) if loot > 0
							player.run_hook(:extra_treasure)
						end
					end

					if encounter_hits
						if player.hero.call_hook(:instead_of_damage, player, encounter)
							Logger.log "%s uses a power instead of taking damage." % [player.name]
						else
							damage_multiplier = 2 ** player.effects.count(:take_double_damage)
							player.wound(encounter.damage * damage_multiplier) if encounter.damage > 0

							damage_multiplier.times { player.run_hook(:extra_damage) }
						end
					else
						Logger.log "%s dodges." % [player.name]
					end
				end

				if !encounter.instant
					player.wound(1) if player.has? :poison # VVV this
					player.run_hook(:after_encounter) # FIXME: after_encounter hooks if encounter is skipped?
				end

				player.current_encounter = nil
			end
		end
	end
end
