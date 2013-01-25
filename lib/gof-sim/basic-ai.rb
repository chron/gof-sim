module GauntletOfFools
	class BasicAI
		PREFIXES = %w(decide_whether_to decide_how_many_times_to)
		def initialize player
			@player = player
			@encounter = nil
		end

		def decide decision, encounter, *args
			PREFIXES.each do |p| 
				if respond_to?(m = p + '_' + decision.to_s)
					@encounter = encounter
					return send(m, *args)
				end
			end

			raise "#{decision}?"
		end

		def about_to_die? # FIXME: special damage
			@encounter.attack >= @player.defense && (@player.wounds + @encounter.damage) >= 4
		end

		def really_needs_a_kill
			%w(Artificer Armorer).include?(@player.hero.name) && @player.hero_tokens > 0
		end

		def kill_chance
			@player.chance_to_hit(@encounter.defense)
		end

		def kill_chance_with_more_dice n
			@player.chance_to_hit(@encounter.defense, n)
		end

		def getting_hit
			@encounter.attack >= @player.defense && !@player.has?(:dodge_next)
		end

		def severe_damage
			@encounter.damage > 1 || @encounter.hooks?(:extra_damage) # FIXME: how to evaluate actual extra damage done
		end

		def expected_value
			kill_chance * @encounter.treasure # FIXME: extra treasure
		end

		# Hero decisions
		def decide_whether_to_use_priest # assume you have at least one wound
			about_to_die? || (kill_chance <= 0.4 || @encounter.treasure < 2) # FIXME: about to die doesn't account for overkill
		end

		def decide_whether_to_use_knight
			getting_hit && severe_damage
		end

		def decide_whether_to_use_trapper
			about_to_die? || kill_chance > 0.8
		end

		def decide_whether_to_use_wizard # fixme: work with non_combat encounters
			(getting_hit && severe_damage) || (getting_hit && kill_chance < 0.6) || kill_chance < 0.35
		end

		def decide_whether_to_use_zealot
			about_to_die? || (getting_hit && kill_chance < 0.5)
		end

		# Weapon decisions
		def decide_whether_to_use_dagger
			about_to_die? || kill_chance <= 0.5 || (really_needs_a_kill && kill_chance < 0.8)
		end

		def decide_whether_to_use_deadly_fists
			(kill_chance < 0.9 && about_to_die?) || (kill_chance < 0.7 && getting_hit) || really_needs_a_kill
		end

		def decide_whether_to_use_bow
			about_to_die? || (getting_hit && severe_damage)
		end

		def decide_whether_to_use_axe
			return false if @player.has?(:zero_attack)
			about_to_die? || kill_chance <= 0.8 || (really_needs_a_kill && kill_chance < 0.9)
		end

		def decide_whether_to_use_morning_star rolls
			#return false if @player.has?(:zero_attack)
			return false if @player.calculate_attack(rolls) >= @encounter.defense

			# FIXME: hmm
			d = rolls.size - @player.attack_dice
			raise "what" if d < 0

			kill_chance_with_more_dice(d) > 0.8
		end

		def decide_whether_to_use_spear rolls
			@player.calculate_attack(rolls) < @encounter.defense && @player.calculate_attack([14]) >= @encounter.defense 
		end

		def decide_whether_to_use_scimitar rolls
			return false if @player.calculate_attack(rolls) >= @encounter.defense
			return @player.calculate_attack((rolls.sort[2..-1] || [])+[3,4]) >= @encounter.defense # average of 2 dice, this is dumb
		end

		def decide_how_many_times_to_use_mace rolls
			return 0 if @player.has?(:zero_attack)
			return @player.weapon_tokens if about_to_die?

			current_attack = @player.calculate_attack(rolls)

			diff = @encounter.defense - current_attack

			return 0 if diff <= 0

			dice_needed = (diff / 3.5 ).ceil # FIXME

			if dice_needed <= @player.weapon_tokens
				dice_needed
			else
				0
			end
		end

		def decide_how_many_times_to_use_throwing_stars
			return 0 if @player.has?(:zero_attack)
			return @player.weapon_tokens if about_to_die?

			0.upto(@player.weapon_tokens) do |v| 
				return v if kill_chance_with_more_dice(v) >= 0.75
			end

			return 0
		end

		def decide_how_many_times_to_use_demonic_blade
			return 0 if @player.has?(:zero_attack)
			return @player.weapon_tokens if about_to_die?

			0.upto(@player.weapon_tokens) do |v| 
				return v if kill_chance_with_more_dice(2*v) >= 0.75
			end

			return 0
		end

		
		def decide_how_many_times_to_use_staff
			defense_uses = ((@encounter.attack - @player.defense).to_f / 6).ceil
			defense_uses = 0 if defense_uses < 0 || defense_uses > @player.weapon_tokens || (defense_uses > 1 && !severe_damage)

			remaining_tokens = @player.weapon_tokens - defense_uses

			attack_uses = (0..remaining_tokens).find do |v| 
				kill_chance_with_more_dice(2*v) >= 0.75
			end 

			[attack_uses || 0, defense_uses]
		end
	end
end