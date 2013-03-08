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
		attr_reader :current_encounter

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

		def log message
			@log.puts(message) if @log
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

		def start
			# FIXME: decisions may need to be made here in future
			@players.each { |p| p.run_hook(:at_start) }
			new_turn
		end

		def new_turn_if_ready
			if @players.all? { |p| p.current_state == :turn_complete }
				new_turn
			end
		end

		def new_turn
			@current_encounter = draw_encounter

			if @current_encounter.nil?
				log 'Encounter deck has been exhausted.'
				game_end
			else
				@turn += 1
				log "Turn %i: %s" % [@turn, @current_encounter.display_name]
				log_player_summary

				@players.each { |p| p.advance!(:begin_turn) }
			end
		end

		def check_for_game_over
			if @players.all? { |p| p.dead? }
				game_end
			end
		end

		def game_end
			@players.each { |p| p.current_state = :game_over }
			log_player_summary
		end

		def finished?
			@players.all? { |p| p.current_state == :game_over }
		end

	end
end
