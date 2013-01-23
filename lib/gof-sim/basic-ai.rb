module GauntletOfFools
	class BasicAI
		PREFIXES = %w(decide_whether_to decide_how_many_times_to)
		def initialize player
			@player = player
			@encounter = nil
		end

		def decide decision, encounter
			PREFIXES.each do |p| 
				if respond_to?(m = p + '_' + decision.to_s)
					@encounter = encounter
					return send(m)
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

		def getting_hit
			@encounter.attack >= @player.defense
		end

		def severe_damage
			@encounter.damage > 1 || @encounter.hooks?(:extra_damage) # FIXME: how to evaluate actual extra damage done
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

		# Weapon decisions
		def decide_whether_to_use_dagger
			about_to_die? || kill_chance <= 0.5 || (really_needs_a_kill && kill_chance < 0.8)
		end

		def decide_whether_to_use_deadly_fists
			(kill_chance < 0.7 && getting_hit) || really_needs_a_kill
		end

		def decide_whether_to_use_bow
			about_to_die? || (getting_hit && severe_damage)
		end

		def decide_whether_to_use_axe
			return false if @player.has?(:zero_attack)
			about_to_die? || kill_chance <= 0.5 || (really_needs_a_kill && kill_chance < 0.8)
		end

		def decide_how_many_times_to_use_throwing_stars
			return 0 if @player.has?(:zero_attack)
			return @player.weapon_tokens if about_to_die?

			# FIXME: need a less hax way to simulate adding dice
			0.upto([@player.weapon_tokens, 5].min) do |v| 
				@player.temp_dice += v
				prob = @player.chance_to_hit(@encounter.defense)
				@player.temp_dice -= v
				return v if prob >= 0.8
			end

			return 0
		end

		def decide_how_many_times_to_use_demonic_blade
			return 0 if @player.has?(:zero_attack)
			return @player.weapon_tokens if about_to_die?

			# FIXME: need a less hax way to simulate adding dice
			0.upto([@player.weapon_tokens, 5].min) do |v| 
				@player.temp_dice += 2*v
				prob = @player.chance_to_hit(@encounter.defense)
				@player.temp_dice -= 2*v
				return v if prob >= 0.8
			end

			return 0
		end
	end
end