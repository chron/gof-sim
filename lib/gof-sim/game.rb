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
			@players = []
			@current_mods = []
			@turn = 0
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

			@players = players
			dead_players = []
			current_mods = []
			turn = 0

			players.each do |p| 
				p.opponents = players.reject { |o| o == p }
				p.run_hook(:at_start) 
			end

			# Logger.log('New dungeon: %s' % [players.map(&:name)*'/'])

			until @encounters.empty?
				play_turn
				break if players.all? { |p| p.dead? }
			end

			players
		end

		def play_turn
			dead_players = @players.select { |p| p.dead? }
			encounter, encounter_mods = *draw_encounter
			return if encounter.nil?

			@current_mods += encounter_mods

			if !encounter.non_combat?
				@current_mods.each { |em| em.call_hook(:modifies_next_encounter, encounter) }
				@current_mods.clear
			end

			@turn += 1

			Logger.log "Turn %i: %s" % [@turn, encounter.display_name]

			@players.each do |p|
				Logger.log ' * %20s %11s %-28s %9s %p => %i' % [
					p.name, p.hero, p.weapons*?+, p.dead? ? "dead @ #{p.age}" : p.wounds, p.instance_eval { @tokens }.merge(:weapon_tokens => p.weapon_tokens), p.treasure
				]
			end

			@players.each do |player|
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

				player.run_hook(:end_of_turn)
			end

			(@players.select { |p| p.dead? } - dead_players).each do |p|
				Logger.log("%s is defeated at age %i with %i coins." % [p.name, p.age, p.treasure])
			end
		end


		def fight player, encounter
			player.current_encounter = encounter
			player.clear_effect :killed_this_round
			player.clear_effect :dodged_this_round
			
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
					player.run_hook(:before_rolling)

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

					player.receive_treasure_from(encounter) if player_hits
					player.take_damage_from(encounter) if encounter_hits
				end

				if !encounter.instant
					player.run_hook(:after_encounter)
				end

				player.current_encounter = nil
			end
		end
	end
end
