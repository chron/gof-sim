module GauntletOfFools
	class BragPhase
		attr_reader :player_names, :options

		def initialize *player_names
			@player_names = player_names

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

			#log "%s takes the %s%s" % [player, opt.hero.name, additional_brags.size>0 ? " adding #{additional_brags}" : '']
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
		def initialize players, args={}
			raise "no players" if players.empty?

			@encounters = Encounter.all.shuffle
			@players = players
			@current_mods = []
			@current_encounter = nil
			@turn = 0
			@log = args.include?(:log) ? args[:log] : File.open('log.txt', ?w)

			@players.each do |player|
				player.game = self
				player.opponents = @players.reject { |o| o == p }
			end
		end

		def start
			@players.each { |p| p.run_hook(:at_start) }
			new_turn
		end

		def finished?
			@players.all? { |p| p.current_state == :finished }
		end

		def log message
			@log.puts(message) if @log
		end

		def peek_at_deck n=1
			@encounters.first(n)
		end

		def draw_encounter discard_modifiers=false
			e = nil

			until e
				next_card = @encounters.shift

				if next_card.nil?
					return nil
				elsif next_card.modifier?
					@current_mods << next_card if !discard_modifiers
				else
					e = next_card.clone
				end
			end

			if !e.non_combat?
				@current_mods.each { |em| em.call_hook(:modifies_next_encounter, e) }
				@current_mods.clear
			end

			e
		end

		def advance player
			#raise "#{player.current_state} -> ? " if player.next_state.nil?

			if player.decisions.empty?
				if player.current_state != player.next_state
					player.current_state = player.next_state
					player.next_state = nil

					self.send("phase_#{player.current_state}", player)
				end
			end
		end

		def advance_until_event player
			while player.decisions.empty? && player.current_state != player.next_state
				advance(player)
			end
		end

		def new_turn
			@players.each { |p| p.current_state = :new_turn }

			@current_encounter = draw_encounter

			if @current_encounter.nil?
				log 'Encounter deck has been exhausted.'
				game_end
			else
				@turn += 1
				log "Turn %i: %s" % [@turn, @current_encounter.display_name]
			
				log_player_summary

				@players.each { |p| p.next_state = :turn_start }
			end
		end

		def phase_turn_start player
			player.begin_turn
			player.queue_fight(@current_encounter)
			run_hook(player, :start_of_turn)

			if player.dead?
				player.next_state = :turn_complete
			else
				player.next_state = :encounter_start
			end
		end

		def phase_encounter_start player
			run_hook(player, :encounter_selection)
			
			player.must_decide(Decision['Visit Encounter'])

			player.next_state = :before_rolling
		end

		def phase_before_rolling player
			encounter = player.current_encounter

			player.log ('%s vs %s (%.2f%% chance to hit)') % [player.name, encounter.name, 100 * player.chance_to_hit(encounter.defense)] if !encounter.non_combat?

			player.clear_effect :killed_this_round
			player.clear_effect :dodged_this_round

			if player.has?(:skip_encounter)
				player.log '%s skips the encounter completely.' % [player.name]

				player.next_state = :encounter_end
			else
				if encounter.non_combat?
					encounter.call_hook(:instead_of_combat, player)
					player.next_state = :encounter_end
				else
					run_hook(player, :before_rolling)
					player.must_decide(Decision['Use One-use Die'])
					player.next_state = :roll
				end
			end
		end

		def phase_roll player
			if !player.has?(:kill_next)
				player.current_roll = player.roll(player.attack_dice)
				run_hook(player, :after_rolling)
			end

			player.next_state = :trade_blows
		end

		def phase_trade_blows player
			encounter = player.current_encounter

			player_hits = if player.has? :kill_next
				player.log "%s kills %s using a power." % [player.name, encounter.name]
				player.clear_effect :kill_next
				true
			else
				total_attack = player.calculate_attack

				player.log "%s attacks %s => %s%p%+i = %i" % [
					player.name, encounter.name, player.attack_factor == 1 ? '' : "#{player.attack_factor}*", player.current_roll.sort, player.bonus_attack, total_attack
				]

				total_attack >= encounter.defense
			end

			if player_hits
				player.log "%s has slain %s!" % [player.name, encounter.name]
				player.gain(:killed_this_round) 
			else
				player.log "%s misses %s." % [player.name, encounter.name]
			end

			run_hook(player, :after_attack)
			player.next_state = :after_combat
		end

		def phase_after_combat player
			encounter = player.current_encounter

			if player.has?(:dodge_next)
				player.log "%s dodges the attack." % [player.name]
				player.clear_effect(:dodge_next)
				player.gain(:dodged_this_round)
			else
				player.log "%s attacks for %i. %s defense is %i." % [encounter.name, encounter.attack, player.name, player.defense]
				player.gain(:dodged_this_round) if encounter.attack < player.defense
			end

			run_hook(player, :after_combat)
			player.next_state = :resolve_combat
		end

		def phase_resolve_combat player
			encounter = player.current_encounter

			player.receive_treasure_from(encounter) if player.has?(:killed_this_round) && !player.has?(:no_treasure)
			player.take_damage_from(encounter) if !player.has?(:dodged_this_round)

			run_hook(player, :after_encounter)
			player.next_state = :encounter_end
		end

		def phase_encounter_end player
			player.fight_queue.shift

			if player.fight_queue.empty?
				player.next_state = :turn_end
			else
				if player.fight_queue.first.nil?
					player.fight_queue.shift
					player.queue_fight(draw_encounter) # CHECK: should this be sans-modifiers
				end

				player.next_state = :encounter_start
			end
		end

		def phase_turn_end player
			run_hook(player, :end_of_turn)
			player.next_state = :turn_complete
		end

		def phase_turn_complete player
			if player.dead?
				player.log("%s is defeated at age %i with %i coins." % [player.name, player.age, player.treasure])
			end

			if @players.all? { |p| p.dead? }
				game_end
			elsif @players.all? { |p| p.current_state == :turn_complete }
				new_turn
			else
				player.next_state = :turn_complete
			end
		end

		def game_end
			@players.each { |p| p.current_state = p.next_state = :finished }
			log_player_summary
		end

		def run_hook player, hook
			decisions = player.run_hook(hook)
			#p [player, hook, decisions]
			decisions.each { |d| player.must_decide(d) }
		end

		def log_player_summary
			@players.each do |p|
				widest_name = @players.map { |e| e.name.length }.max
				widest_hero = @players.map { |e| e.hero.name.length }.max
				widest_weapon = @players.map { |e| e.weapons.join(' ').length }.max

				log ' -> %*s %*s %-*s %1s %p' % [
					widest_name, p.name, widest_hero, p.hero, widest_weapon, p.weapons*?+, p.dead? ? "X" : ' ', p.instance_eval { @tokens }.merge(:weapon_tokens => p.weapon_tokens)
				]
			end
		end
	end
end
