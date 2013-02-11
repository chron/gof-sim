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
		def self.test_encounter *e
			obj = new
			obj.instance_eval { @encounters = e }
			obj
		end

		def initialize args={}
			@encounters = Encounter.all.shuffle
			@players = []
			@current_mods = []
			@turn = 0
			@log = args.include?(:log) ? args[:log] : File.open('log.txt', ?w)
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

		def run *players
			raise "no players" if players.empty?

			@players = players
			dead_players = []
			current_mods = []
			turn = 0

			players.each do |p| 
				p.game = self
				p.opponents = players.reject { |o| o == p }
				p.run_hook(:at_start) 
			end

			# log('New dungeon: %s' % [players.map(&:name)*'/'])

			until @encounters.empty?
				play_turn
				break if players.all? { |p| p.dead? }
			end

			players
		end

		def play_turn
			dead_players = @players.select { |p| p.dead? }
			encounter, encounter_mods = *draw_encounter
			
			if encounter.nil?
				log 'Encounter deck has been exhausted.'
				return
			end

			@turn += 1

			log "Turn %i: %s" % [@turn, encounter.display_name]

			@players.each do |p|
				widest_name = @players.map { |e| e.name.length }.max
				widest_hero = @players.map { |e| e.hero.name.length }.max
				widest_weapon = @players.map { |e| e.weapons.join(' ').length }.max

				log ' -> %*s %*s %-*s %1s %p' % [
					widest_name, p.name, widest_hero, p.hero, widest_weapon, p.weapons*?+, p.dead? ? "X" : ' ', p.instance_eval { @tokens }.merge(:weapon_tokens => p.weapon_tokens)
				]
			end

			@players.each do |player|
				# This is the only hook that gets run for dead players.
				# CHECK: zombie/wand interaction - only if alive?
				player.run_hook(:start_of_turn, self)
				next if player.dead?

				player.begin_turn
				player.queue_fight(encounter)

				until player.fight_queue.empty?
					new_encounter = player.fight_queue.shift || draw_encounter
					break if new_encounter.nil?

					new_encounter.call_hook(:encounter_selection, player, new_encounter, self)

					log ('%s vs %s (%.2f%% chance to hit)') % [player.name, new_encounter.name, 100 * player.chance_to_hit(new_encounter.defense)] if !new_encounter.non_combat?

					fight(player, new_encounter)
				end

				player.run_hook(:end_of_turn)
			end

			(@players.select { |p| p.dead? } - dead_players).each do |p|
				log("%s is defeated at age %i with %i coins." % [p.name, p.age, p.treasure])
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
				log '%s skips the encounter completely.' % [player.name]
			else
				if encounter.non_combat? #.hooks?(:instead_of_combat)
					encounter.call_hook(:instead_of_combat, player)
				else
					player.run_hook(:before_rolling)

					if !player.has? :kill_next
						dice_roll = player.roll(player.attack_dice)
						dice_result = player.run_hook(:after_rolling, dice_roll)
					end

					player_hits = if player.has? :kill_next
						log "%s kills %s using a power." % [player.name, encounter.name]
						player.clear_effect :kill_next
						true
					else
						total_attack = player.calculate_attack(dice_result)

						log "%s attacks %s => %s%p%+i = %i" % [
							player.name, encounter.name, player.attack_factor == 1 ? '' : "#{player.attack_factor}*", dice_result.sort, player.bonus_attack, total_attack
						]

						total_attack >= encounter.defense
					end

					if player_hits
						log "%s has slain %s!" % [player.name, encounter.name]
						player.gain(:killed_this_round) 
					else
						log "%s misses %s." % [player.name, encounter.name]
					end

					player.run_hook(:after_attack)

					encounter_hits = if player.has?(:dodge_next)
						false
					else
						log "%s attacks for %i. %s defense is %i." % [encounter.name, encounter.attack, player.name, player.defense]
						encounter.attack >= player.defense
					end

					player.gain(:dodged_this_round) if !encounter_hits

					player.receive_treasure_from(encounter) if player_hits
					player.take_damage_from(encounter) if encounter_hits
				end

				player.run_hook(:after_encounter)

				player.current_encounter = nil
			end
		end
	end
end
