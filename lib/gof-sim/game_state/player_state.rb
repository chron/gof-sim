module GauntletOfFools
	class Player
		# at_start
		#
		TURN_PHASES = [
			:at_start,
				:begin_turn,
				:start_of_turn, #
				:skip_if_dead,
				:encounter_selection, #
				:decide_whether_to_visit,
					:start_of_encounter,
					:before_rolling, #
					:attack_roll,
					:after_rolling, #
					:player_attacks,
					:after_attack, #
					:encounter_attacks,
					:after_combat, #
					:treasure_and_damage,
					:after_encounter, #
					:end_of_encounter,
				:end_of_turn, #
				:turn_complete
		].freeze
		# non_combat_encounter
		# modifies_next_encounter instead_of_combat extra_damage extra_treasure

		def advance! to_state=nil
			return false if @current_state == :game_over

			if @decisions.empty?
				next_state = to_state || TURN_PHASES[TURN_PHASES.index(@current_state) + 1]

				if next_state
					@current_state = next_state

					if respond_to?(next_state)
						send(next_state)
					else
						run_hook(next_state)
					end

					next_state
				end
			end
		end

		def advance_until_event! 
			while decisions.empty?
				break unless advance!
			end

			@current_state
		end

		def begin_turn
			@age += 1
			@current_effects.clear
			@current_effects.concat(@next_turn_effects)
			@next_turn_effects.clear
			TEMP_TOKENS.each { |t| @tokens.delete(t.intern) }
			queue_fight(@game.current_encounter)
		end

		def skip_if_dead
			if dead?
				@current_phase = :turn_complete
			end
		end

		def decide_whether_to_visit
			must_decide(Decision['Visit Encounter'])
		end

		def start_of_encounter
			log ('%s vs %s (%.2f%% chance to hit)') % [name, current_encounter.name, 100 * chance_to_hit(current_encounter.defense)] if !current_encounter.non_combat?

			clear_effect :killed_this_round
			clear_effect :dodged_this_round

			if has?(:skip_encounter)
				log '%s skips the encounter completely.' % [name]

				@current_phase = :end_of_encounter
			else
				if current_encounter.non_combat?
					# FIXME: decision point here?
					current_encounter.call_hook(:instead_of_combat, self)
					@current_phase = :encounter_end
				else
					# FIXME: find somewhere better for this
					must_decide(Decision['Use One-use Die'])
				end
			end
		end

		def attack_roll
			if !has?(:kill_next)
				@current_roll = roll(attack_dice)
			end
		end

		def player_attacks
			player_hits = if has? :kill_next
				log "%s kills %s using a power." % [name, current_encounter.name]
				clear_effect :kill_next
				true
			else
				total_attack = calculate_attack

				log "%s attacks %s => %s%p%+i = %i" % [
					name, current_encounter.name, attack_factor == 1 ? '' : "#{attack_factor}*", current_roll.sort, bonus_attack, total_attack
				]

				total_attack >= current_encounter.defense
			end

			if player_hits
				log "%s has slain %s!" % [name, current_encounter.name]
				gain(:killed_this_round) 
			else
				log "%s misses %s." % [name, current_encounter.name]
			end
		end

		def encounter_attacks
			if has?(:dodge_next)
				log "%s dodges the attack." % [name]
				clear_effect(:dodge_next)
				gain(:dodged_this_round)
			else
				log "%s attacks for %i. %s defense is %i." % [current_encounter.name, current_encounter.attack, name, defense]
				gain(:dodged_this_round) if current_encounter.attack < defense
			end
		end

		def treasure_and_damage
			receive_treasure_from(current_encounter) if has?(:killed_this_round)
			take_damage_from(current_encounter) if !has?(:dodged_this_round)
		end

		def end_of_encounter
			fight_queue.shift

			if fight_queue.size > 0
				# For a nil in fight_queue, draw a new encounter from the deck
				if fight_queue.first.nil?
					fight_queue.shift
					queue_fight(@game.draw_encounter) # CHECK: should this be sans-modifiers
				end

				@current_state = :start_of_encounter
			end
		end

		def turn_complete
			# FIXME: zombies die again
			if dead?
				log("%s is defeated at age %i with %i coins." % [name, age, treasure])

				@game.check_for_game_over if @game
			end

			@game.new_turn_if_ready if @game
		end
	end
end