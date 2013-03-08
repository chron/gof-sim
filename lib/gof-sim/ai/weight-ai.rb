module GauntletOfFools
	# TODO: gold is more valuable if you're about to die, context?
	
	class WeightAI
		WEIGHTS = {
			:treasure => 1,
			:wound => -5,
			:poison => -10,
			:hero_token => 3,
			:weapon_token => 3,
			:attack => 1,
			:defense => 2,
			:dice => 5,
			:one_use_die => 2,
			:reduced_defense => -2,
			:reduced_dice => -5,
			:reduced_attack => -1
		}

		def initialize player
			@player = player
		end

		def decide decision, player=@player
			trail, value = decision_tree(player).max_by { |k,v| v }

			trail.find { |k,v| k == decision }.last
		end

		def decision_tree player, trail=[]
			if player.advance_until_event! == :turn_complete
				r = evaluate_state(player)
				puts "Decision Tree: #{trail.inspect} => #{r}"
				{trail => r}
			else
				player.decisions.map do |d|
					choices = d.possible_choices(player)
					p choices
					choices.map do |o|
						player_clone = player.clone
						player_clone.make_decision(d, o)
						decision_tree(player_clone, trail + [[d, o]])
					end
				end.flatten.inject(&:merge)
			end
		end

		def evaluate_state player
			WEIGHTS.inject(0) do |sum,(token,weight)|
				amount = token == :weapon_token ? player.weapon_tokens : player.tokens(token)
				sum + amount * weight
			end
		end

		#def expected_wounds_per_encounter
		#	Encounter.all.map { |e| @player.defense <= e.attack ? e.damage : 0 }.mean
		#end

		#def expected_gold_per_encounter
		#	Encounter.all.map { |e| @player.chance_to_hit(e.defense) * e.treasure }.mean
		#end
	end
end