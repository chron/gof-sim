module GauntletOfFools
	class Option < Struct.new(:hero, :weapon, :current_owner, :brags)
		def inspect
			"%s/%s+%p%s" % [hero.name, weapon.name, brags, current_owner ? " (#{current_owner})" : '']
		end

		def is_assigned?
			current_owner
		end
	end

	class Game
		def initialize
			@player_names = []
			@players = nil
			@encounters = []

			@options = []

			@encounters = Encounter.all.shuffle # FIXME: do we need the whole decks generated?
			@heroes = Hero.all.shuffle
			@weapons = Weapon.all.shuffle
		end

		def << new_player
			raise "bidding already finished" if finished_bidding?

			@player_names << new_player
			@options << Option.new(@heroes.pop, @weapons.pop, nil, [])
			self
		end

		def options
			@options
		end

		def bid player, option_index, *additional_brags
			raise "Unknown brag" if additional_brags.any? { |b| !BRAGS.include?(b) }
			raise "Already has something" if @options.any? { |o| o.current_owner == player }
			opt = @options[option_index]

			new_brags = (opt.brags + additional_brags).uniq

			if !opt.is_assigned? || new_brags.size > opt.brags.size
				puts "%s takes the %s%s" % [player, opt.hero.name, additional_brags.size>0 ? " adding #{additional_brags}" : '']
				opt.current_owner = player
				opt.brags += additional_brags
			end

			assign_players if @options.all? { |o| o.is_assigned? }
		end

		def assign_players
			@players = @options.map { |o| Player.new(o.current_owner, o.hero, o.weapon, o.brags)}.shuffle
		end

		def finished_bidding?
			@players
		end

		def play
			raise "no players" if !@players

			active_players = @players.dup

			@encounters.each_with_index do |encounter, i|
				puts "Encounter %i: %s" % [i+1, encounter.display_name]

				active_players.each do |player|
					player.fight(encounter)
				end

				active_players.delete_if { |p| p.dead? && !puts("%s is defeated with %i coins." % [p.name, p.treasure])}
				break if active_players.empty?
			end

			puts
			@players.sort_by { |p| -p.treasure }.each do |p| # TODO: tiebreaker?
				puts "%3i %10s | %-30s" % [p.treasure, p.name, "#{p.hero.name}/#{p.weapon.name} + #{p.brags}"]
			end
		end
	end
end

game = GauntletOfFools::Game.new
game << "One" << "Two"
p game.options

game.bid "One", 0
game.bid "Two", 0, :no_breakfast
game.bid "One", 1

game.play