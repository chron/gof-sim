module GauntletOfFools
	class BasicAI
		PREFIXES = %w(decide_whether_to decide_how_many_times_to decide)

		def initialize player
			@player = player
			@encounter = nil
			@owner = nil
		end

		def decide decision, encounter, *args
			PREFIXES.each do |p| 
				if respond_to?(m = p + '_' + decision.name.downcase.tr(' -','_'))
					@encounter = encounter
					@owner = decision.owner

					return send(m, *args)
				end
			end

			raise "#{decision}?"
		end

		def weapon_tokens
			@player.weapon_tokens(@owner)
		end

		def future_self
			f = @player.clone
			f.take_damage_from(@encounter) if getting_hit
			#f.receive_treasure_from(@encounter)
			f.run_hook(:end_of_turn)

			f
		end		

		def about_to_die # FIXME: doesn't run all hooks, eg treasure for mushroom man
			future_self.dead?
		end

		def really_needs_a_kill
			%w(Artificer Armorer).include?(@player.hero.name) && @player.tokens(:hero_token) > 0
		end

		def kill_chance e=@encounter
			@player.chance_to_hit(e.defense)
		end

		def kill_chance_with_more_dice n
			@player.chance_to_hit(@encounter.defense, n)
		end

		def getting_hit e=@encounter
			e.attack >= @player.defense && !@player.has?(:dodge_next)
		end

		def severe_damage
			# FIXME: how to evaluate actual extra damage done 
			@encounter.damage > 1 || (@encounter.damage > 0 && @encounter.hooks?(:extra_damage)) || (@player.has?(:take_double_damage) && @encounter.damage > 0) || @encounter.name == 'Giant Spider'
		end

		def add_dice_up_to_max max
			return 0 if @player.has?(:zero_attack)
			return max if about_to_die

			current_attack = @player.calculate_attack

			diff = @encounter.defense - current_attack

			return 0 if diff <= 0

			dice_needed = (diff / 3.5 ).ceil # FIXME

			if dice_needed <= max
				dice_needed
			else
				0
			end
		end

		def decide_which_weapon_dice weapons
			# FIXME: sometimes might not want to kill, e.g. cockroach
			weapons.max_by { |w| w.dice }
		end

		def decide_which_encounter *encounters
			encounters.max_by { |e| value_of_encounter(e) }
		end

		def decide_reorder_encounter_deck *encounters
			encounters
		end

		# This will only offer weapons with tokens available
		def decide_which_weapon_token_to_discard weapons
			weapons[0]
		end

		def decide_which_weapon_to_gain_token_for
			@player.weapons[0]
		end

		def decide_whether_to_use_one_use_die
			return false if @player.has?(:zero_attack)
			return true if about_to_die
			return false if kill_chance > 0.75
			# FIXME: may have more than 1
			return true if kill_chance_with_more_dice(1) >= 0.75
		end

		# FIXME: ugly
		def decide_whether_to_visit_encounter
			(@encounter.non_combat? && @encounter.name != 'Spear Trap') || !getting_hit
		end

		def decide_whether_to_take_extra_hellhound_treasure
			@player.wounds >= 4 # FIXME
		end

		# Encounter decisions
		def decide_how_many_times_to_bet_on_gladiator
			kill_chance > 0.6 ? [5, @player.treasure].min : 0
		end

		def decide_whether_to_heal_from_healing_pool
			@player.wounds > 0 && @player.tokens(:poison) == 0 && @player.tokens(:reduced_defense) < 3
		end

		def decide_whether_to_take_weapon_from_magic_pool
			# FIXME
			%w(Armsmaster Barbarian Ninja).include?(@player.hero.name)
		end

		def decide_whether_to_take_gold_from_bees
			about_to_die || %w(Barbarian Armsmaster).include?(@player.hero.name)
		end

		def decide_whether_to_take_wound_from_banshee
			@player.wounds != 3 && @player.defense > 10
		end

		def decide_whether_to_skip_mercenary
			getting_hit
		end

		def decide_whether_to_skip_behemoth
			about_to_die || (getting_hit && kill_chance < 0.5) # FIXME: certain combos probably value tokens more than this
		end

		# Hero decisions
		def decide_whether_to_use_adventurer
			@player.dead? || (!getting_hit && kill_chance > 0.75 && @encounter.hooks?(:extra_treasure) && @encounter.name != 'Giant Cockroach')
		end

		def decide_whether_to_use_alchemist
			true
		end

		def decide_whether_to_use_armorer
			!about_to_die && (@encounter.name == 'Giant Cockroach' || !@encounter.hooks?(:extra_treasure))
		end

		def decide_whether_to_use_artificer
			!about_to_die && (@encounter.name == 'Giant Cockroach' || !@encounter.hooks?(:extra_treasure))
		end

		def decide_whether_to_use_avenger dead_opponents
			delta = @encounter.defense - @player.calculate_attack # FIXME: interaction with attack_factors etc
			delta > 0 && delta <= 3*dead_opponents 
		end

		def decide_whether_to_use_berserker # FIXME: multiuse?
			old_kill_chance = kill_chance
			new_kill_chance = kill_chance_with_more_dice(@player.wounds)
			improvement = new_kill_chance - old_kill_chance

			about_to_die || (getting_hit && severe_damage && improvement > 0.1) || (getting_hit && improvement > 0.1 && new_kill_chance > 0.75)
		end

		def decide_whether_to_use_priest # assume you have at least one wound
			about_to_die || (kill_chance <= 0.4 || @encounter.treasure < 2) # FIXME: about to die doesn't account for overkill
		end

		def decide_whether_to_use_jester
			# FIXME: purely defensive consideration
			getting_hit && @encounter.defense < @player.defense
		end

		def decide_whether_to_use_knight
			getting_hit && severe_damage
		end

		def decide_whether_to_use_thief
			about_to_die || (getting_hit && severe_damage)
		end

		def decide_whether_to_use_thief_for_trap
			@player.wounds >= 3 # TODO: check this in relation to damage factors
		end

		def decide_whether_to_use_trapper
			about_to_die || kill_chance > 0.8
		end

		def decide_whether_to_use_warlord
			add_dice_up_to_max(@player.tokens(:hero_token))
		end

		def decide_whether_to_use_wizard # fixme: work with non_combat encounters
			(getting_hit && severe_damage) || (getting_hit && kill_chance < 0.6) || kill_chance < 0.35
		end

		def decide_whether_to_use_zealot
			about_to_die || (getting_hit && !severe_damage && kill_chance < 0.5)
		end

		def decide_whether_to_use_zombie
			kill_chance > 0.6
		end

		def decide_how_many_times_to_use_monk # FIXME: purely defensive consideration atm
			defensive_uses_required = ((@encounter.attack - @player.defense + 1).to_f / 4).ceil

			return 0 if defensive_uses_required < 1
			return 0 if defensive_uses_required > @player.tokens(:hero_token)

			if about_to_die || severe_damage || defensive_uses_required == 1
				defensive_uses_required
			else
				0
			end
		end

		# Weapon decisions
		def decide_whether_to_use_dagger
			about_to_die || kill_chance <= 0.5 || (really_needs_a_kill && kill_chance < 0.8)
		end

		def decide_whether_to_use_deadly_fists
			(kill_chance < 0.9 && about_to_die) || (kill_chance < 0.7 && getting_hit) || really_needs_a_kill || (getting_hit && severe_damage)
		end

		def decide_whether_to_use_bow
			about_to_die || (getting_hit && severe_damage)
		end

		def decide_whether_to_use_axe
			return false if @player.has?(:zero_attack)
			about_to_die || kill_chance <= 0.6 || (really_needs_a_kill && kill_chance < 0.75)
		end

		def decide_whether_to_use_flaming_sword
			# FIXME: don't use if about to take lethal from scorpion
			about_to_die || (@player.wounds < 2 && really_needs_a_kill && kill_chance < 0.75) || (getting_hit && severe_damage)
		end

		def decide_whether_to_use_holy_sword
			@player.has?(:poison) # FIXME: implement this
		end

		def decide_whether_to_use_morning_star
			return false if @player.calculate_attack >= @encounter.defense

			# FIXME: hmm
			d = @player.current_roll.size - @player.attack_dice
			raise "what" if d < 0

			kill_chance_with_more_dice(d) > 0.5
		end

		def decide_whether_to_use_sling
			about_to_die || (getting_hit && kill_chance < 0.8) || (getting_hit && severe_damage)
		end

		def decide_whether_to_use_spear
			@player.calculate_attack < @encounter.defense && @player.calculate_attack([14]) >= @encounter.defense 
		end

		def decide_whether_to_use_scepter
			true
		end

		def decide_whether_to_use_scimitar
			return false if @player.calculate_attack >= @encounter.defense
			return @player.calculate_attack((@player.current_roll.sort[2..-1] || [])+[3,4]) >= @encounter.defense # average of 2 dice, this is dumb
		end

		def decide_whether_to_use_spiked_shield
			@player.calculate_attack < @encounter.defense
		end

		def decide_whether_to_use_whip
			about_to_die || (getting_hit && severe_damage)
		end

		def decide_how_many_times_to_use_sword
			uses_required = ((@encounter.attack - @player.defense + 1).to_f / 3).ceil

			return 0 if uses_required < 1
			return 0 if uses_required > @player.weapon_tokens('Sword')

			if about_to_die || severe_damage
				uses_required
			else
				0
			end
		end

		def decide_whether_to_use_mace
			delta = @player.calculate_attack - @encounter.defense
			delta < 0 && delta > -3.5 * weapon_tokens || (about_to_die && delta >= -6 * weapon_tokens)
		end

		def decide_how_many_times_to_use_throwing_stars
			return 0 if @player.has?(:zero_attack)
			return @player.weapon_tokens('Throwing Stars') if about_to_die

			0.upto(@player.weapon_tokens('Throwing Stars')) do |v| 
				return v if kill_chance_with_more_dice(v) >= 0.8
			end

			return 0
		end

		def decide_how_many_times_to_use_demonic_blade
			return 0 if @player.has?(:zero_attack)
			return weapon_tokens if about_to_die

			0.upto(weapon_tokens) do |v| 
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