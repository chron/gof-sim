module GauntletOfFools
	class BasicAI
		PREFIXES = %w(decide_whether_to decide_how_many_times_to decide)
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

		def about_to_die? # FIXME: special damage, mushroom man etc
			# FIXME: dodges/def raises from other weapons or hero abilities
			(@encounter.attack >= @player.defense) && (@player.wounds + @encounter.damage) >= 4
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
			# FIXME: how to evaluate actual extra damage done 
			@encounter.damage > 1 || @encounter.hooks?(:extra_damage) || (@player.has?(:take_double_damage) && @encounter.damage > 0)
		end

		def add_dice_up_to_max rolls, max
			return 0 if @player.has?(:zero_attack)
			return max if about_to_die?

			current_attack = @player.calculate_attack(rolls)

			diff = @encounter.defense - current_attack

			return 0 if diff <= 0

			dice_needed = (diff / 3.5 ).ceil # FIXME

			if dice_needed <= max
				dice_needed
			else
				0
			end
		end

		def decide_which_encounter *encounters
			encounters.first # FIXME
		end

		# FIXME: ugly
		def decide_whether_to_visit_encounter
			(@encounter.non_combat? && @encounter.name != 'Spear Trap') || !getting_hit
		end

		def decide_whether_to_take_extra_hellhound_treasure
			@player.wounds >= 4 # FIXME
		end

		# Encounter decisions
		def decide_whether_to_take_wound_from_banshee
			!about_to_die? || @player.defense <= 10
		end

		def decide_whether_to_skip_mercenary
			getting_hit
		end

		def decide_whether_to_skip_behemoth
			about_to_die? || (getting_hit && kill_chance < 0.5) # FIXME: certain combos probably value tokens more than this
		end

		# Hero decisions
		def decide_whether_to_use_avenger rolls
			n = @player.opponents.count { |p| p.dead? }
			return false if @player.calculate_attack(rolls) >= @encounter.defense

			(@player.calculate_attack(rolls) + n) >= @encounter.defense # FIXME: interaction with attack_factors etc
		end

		def decide_whether_to_use_berserker # FIXME: multiuse?
			old_kill_chance = kill_chance
			new_kill_chance = kill_chance_with_more_dice(@player.wounds)
			improvement = new_kill_chance - old_kill_chance

			about_to_die? || (getting_hit && severe_damage && improvement > 0.1) || (getting_hit && improvement > 0.1 && new_kill_chance > 0.75)
		end

		def decide_whether_to_use_priest # assume you have at least one wound
			about_to_die? || (kill_chance <= 0.4 || @encounter.treasure < 2) # FIXME: about to die doesn't account for overkill
		end

		def decide_whether_to_use_knight
			getting_hit && severe_damage
		end

		def decide_whether_to_use_thief
			about_to_die? || (getting_hit && severe_damage)
		end

		def decide_whether_to_use_thief_for_trap
			@player.wounds >= 3 # TODO: check this in relation to damage factors
		end

		def decide_whether_to_use_trapper
			about_to_die? || kill_chance > 0.8
		end

		def decide_whether_to_use_warlord rolls
			add_dice_up_to_max(rolls, @player.hero_tokens)
		end

		def decide_whether_to_use_wizard # fixme: work with non_combat encounters
			(getting_hit && severe_damage) || (getting_hit && kill_chance < 0.6) || kill_chance < 0.35
		end

		def decide_whether_to_use_zealot
			about_to_die? || (getting_hit && !severe_damage && kill_chance < 0.5)
		end

		def decide_whether_to_use_zombie
			true # FIXME: implement this
		end

		def decide_how_many_times_to_use_monk # FIXME: purely defensive consideration atm
			uses_required = ((@encounter.attack - @player.defense).to_f / 4).ceil

			return 0 if uses_required < 1
			return 0 if uses_required > @player.hero_tokens

			if about_to_die? || severe_damage || uses_required == 1
				uses_required
			else
				0
			end
		end

		# Weapon decisions
		def decide_whether_to_use_dagger
			about_to_die? || kill_chance <= 0.5 || (really_needs_a_kill && kill_chance < 0.8)
		end

		def decide_whether_to_use_deadly_fists
			(kill_chance < 0.9 && about_to_die?) || (kill_chance < 0.7 && getting_hit) || really_needs_a_kill || (getting_hit && severe_damage)
		end

		def decide_whether_to_use_bow
			about_to_die? || (getting_hit && severe_damage)
		end

		def decide_whether_to_use_axe
			return false if @player.has?(:zero_attack)
			about_to_die? || kill_chance <= 0.6 || (really_needs_a_kill && kill_chance < 0.75)
		end

		def decide_whether_to_use_flaming_sword
			about_to_die? || (@player.wounds < 2 && really_needs_a_kill) || (kill_chance < 0.4 && getting_hit && severe_damage)
		end

		def decide_whether_to_use_holy_sword
			false # FIXME: implement this
		end

		def decide_whether_to_use_morning_star rolls
			#return false if @player.has?(:zero_attack)
			return false if @player.calculate_attack(rolls) >= @encounter.defense

			# FIXME: hmm
			d = rolls.size - @player.attack_dice
			raise "what" if d < 0

			kill_chance_with_more_dice(d) > 0.8
		end

		def decide_whether_to_use_sling
			about_to_die? || (getting_hit && kill_chance < 0.8) || (getting_hit && severe_damage)
		end

		def decide_whether_to_use_spear rolls
			@player.calculate_attack(rolls) < @encounter.defense && @player.calculate_attack([14]) >= @encounter.defense 
		end

		def decide_whether_to_use_scepter
			true
		end

		def decide_whether_to_use_scimitar rolls
			return false if @player.calculate_attack(rolls) >= @encounter.defense
			return @player.calculate_attack((rolls.sort[2..-1] || [])+[3,4]) >= @encounter.defense # average of 2 dice, this is dumb
		end

		def decide_whether_to_use_spiked_shield rolls
			@player.calculate_attack(rolls) < @encounter.defense
		end

		def decide_how_many_times_to_use_sword
			uses_required = ((@encounter.attack - @player.defense).to_f / 3).ceil

			return 0 if uses_required < 1
			return 0 if uses_required > @player.weapon_tokens('Sword')

			if about_to_die? || severe_damage
				uses_required
			else
				0
			end
		end

		def decide_how_many_times_to_use_mace rolls
			add_dice_up_to_max(rolls, @player.weapon_tokens('Mace'))
		end

		def decide_how_many_times_to_use_throwing_stars
			return 0 if @player.has?(:zero_attack)
			return @player.weapon_tokens('Throwing Stars') if about_to_die?

			0.upto(@player.weapon_tokens('Throwing Stars')) do |v| 
				return v if kill_chance_with_more_dice(v) >= 0.75
			end

			return 0
		end

		def decide_how_many_times_to_use_demonic_blade
			return 0 if @player.has?(:zero_attack)
			return @player.weapon_tokens('Demonic Blade') if about_to_die?

			0.upto(@player.weapon_tokens('Demonic Blade')) do |v| 
				return v if kill_chance_with_more_dice(2*v) >= 0.75
			end

			return 0
		end

		
		def decide_how_many_times_to_use_staff
			defense_uses = ((@encounter.attack - @player.defense).to_f / 6).ceil
			defense_uses = 0 if defense_uses < 0 || defense_uses > @player.weapon_tokens('Staff') || (defense_uses > 1 && !severe_damage)

			remaining_tokens = @player.weapon_tokens('Staff') - defense_uses

			attack_uses = (0..remaining_tokens).find do |v| 
				kill_chance_with_more_dice(2*v) >= 0.75
			end 

			[attack_uses || 0, defense_uses]
		end
	end
end