require 'yaml'

module GauntletOfFools
	class Valuator
		DATA_STORE = 'score_history.yaml'

		def initialize
			@history = if File.exist? DATA_STORE
				YAML::load(File.read(DATA_STORE)) || {}
			else
				{}
			end
		end

		def record game
			if game.game_over?
				game.players.each do |player|
					@history[player.hero.name] ||= {}
					@history[player.hero.name][player.weapon.name] ||= {}
					@history[player.hero.name][player.weapon.name][player.brags.sort*?,] ||= []
					@history[player.hero.name][player.weapon.name][player.brags.sort*?,] << player.treasure
				end
			end

			save_file
		end

		def save_file
			File.open(DATA_STORE, ?w) do |f|
				f.puts YAML::dump(@history)
			end
		end

		def averages
			@history.map do |hero, weapons|
				weapons.map do |weapon,brag_lists|
					brag_lists.map do |brags,t|
						[hero, weapon, brags, t.inject { |s,c| s + c}.to_f / t.size]
					end
				end
			end.flatten(2)
		end
	end
end
