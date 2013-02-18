module GauntletOfFools
	class Encounter < GameObject		
		attr_accessor :attack, :defense, :damage, :treasure

		def initialize name, attack=0, defense=0, damage=0, treasure=0
			@attack, @defense, @damage, @treasure = attack, defense, damage, treasure

			super(name)
		end

		def non_combat?
			hooks?(:instead_of_combat)
		end

		def display_name
			name + (self.non_combat? ? '' : " (#{attack}/#{defense > 0 ? defense : ??}/#{damage}#{hooks?(:extra_damage)? ?+ : ''}/#{treasure}#{hooks?(:extra_treasure)? ?+ : ''})")
		end

		def add_prefix prefix # FIXME: this is kind of dumb
			@name = prefix + ' ' + @name
		end

		def modifier!
			@modifier = true
		end

		def modifier?
			@modifier
		end

		def swap_attack_and_defense
			#player.log '%s has its attack and defense swapped.' % [@name] 
			@attack, @defense = @defense, @attack
		end
	end

	Encounter.new('Bandit', 14, 14, 1, 3) {
		hooks(:extra_treasure) { |player| player.gain_weapon_token }
	}

	Encounter.new('Bee Swarm', 10, 6, 1, 0) {
		decision_at(:extra_treasure, 'Take Gold from Bees') {
			hooks(:apply) { |player| player.gain_treasure(2) }
			hooks(:decline) { |player| player.gain_token(:hero_token) }
		}
	}

	Encounter.new('Banshee', 23, 16, 0, 4) {
		decision_at(:extra_damage, 'Take Wound from Banshee') { 
			hooks(:apply) { |player| player.wound(1) }
			hooks(:decline) { |player| player.gain_token(:reduced_defense, 3) }
		}
	}

	Encounter.new('Behemoth', 20, 21, 1, 4) {
		decision_at(:encounter_selection, 'Skip Behemoth') {
			hooks(:prereqs) { |player| player.weapon_tokens >= 1 }
			hooks(:apply) { |player|
				player.gain_weapon_token(-1) # FIXME: spend?
				player.gain(:skip_encounter)
				player.log '%s pays 1 weapon token to skip the fight.' % [player.name]
			}
		}
	}

	Encounter.new('Brass Golem', 16, 15, 1, 2) {
		hooks(:extra_treasure) { |player| player.has?(:dodged_this_turn) && player.gain_treasure(2) }
	}

	Encounter.new('Cache') {
		hooks(:instead_of_combat) { |player| player.gain_treasure(2) }
	}

	Encounter.new('Carnivorous Plant', 10, 16, 1, 1)

	Encounter.new('Dancing Sword', 21, 8, 1, 3) {
		hooks(:extra_treasure) { |player| player.gain_token(:attack, 1) }
	}

	Encounter.new('Demon', 17, 17, 1, 4) { # FIXME: wizard should be able to skip this
		hooks(:encounter_selection) { |player| player.gain(:no_weapon_tokens, :no_hero_tokens) }
	}

	Encounter.new('Doppelganger', 14, 0, 1, 3) {# Doppelgänger
		hooks(:encounter_selection) { |player, encounter| encounter.defense = player.defense } # this is so it displays correctish at start
		hooks(:after_rolling) { |player, encounter| encounter.defense = player.defense }
	}

	# FIXME: adventurer+eb troll is out of control
	Encounter.new('Extra Bitey') {
		modifier!
		hooks(:modifies_next_encounter) { |encounter| 
			encounter.add_prefix(name)
			encounter.hooks(:encounter_selection) { |player, encounter| player.gain(:take_double_damage) }
		}
	}

	Encounter.new('Extra Scary') {
		modifier!
		hooks(:modifies_next_encounter) { |encounter| encounter.add_prefix(name); encounter.attack += 3 }
	}

	Encounter.new('Extra Tough') {
		modifier!
		hooks(:modifies_next_encounter) { |encounter| encounter.add_prefix(name); encounter.defense += 3 }
	}

	Encounter.new('Extra Wealthy') {
		modifier!
		hooks(:modifies_next_encounter) { |encounter| encounter.add_prefix(name); encounter.treasure += 3 } # check this value
	}

	Encounter.new('Fire Elemental', 18, 14, 1, 0) {
		hooks(:extra_treasure) { |player| player.gain_treasure(player.defense / 3) }
	}

	Encounter.new('Gargoyle', 13, 19, 1, 2)

	Encounter.new('Giant', 24, 20, 1, 5)

	Encounter.new('Giant Cockroach', 11, 12, 1, 2) {
		hooks(:extra_treasure) { |player| player.gain_token(:reduced_defense, 1) }
	}

	Encounter.new('Giant Crab', 8, 18, 1, 2) {
		hooks(:extra_treasure) { |player| player.gain_token(:defense, 1) }
	}

	Encounter.new('Giant Scorpion', 19, 12, 2, 3) {
		# Somewhat thug way to prevent zombies from getting a free turn by taking damage from this
		hooks(:extra_damage) { |player| !player.has?(:cannot_die) && player.gain(:cannot_die) }
	}

	Encounter.new('Giant Spider', 17, 19, 0, 3) {
		hooks(:extra_damage) { |player| player.gain_token(:poison) && player.gain(:recently_poisoned) }
	}

	Encounter.new('Giant Toad', 14, 12, 1, 2) {
		hooks(:extra_treasure) { |player| player.gain_token(:one_use_die, 1) }
	}

	Encounter.new('Giant Turtle', 9, 14, 1, 1)

	Encounter.new('Gladiator', 15, 15, 1, 0) { # PROMO
		decision_at(:before_rolling, "Bet on Gladiator") { 
			limit_values_to { |value| v >= 0 && v <= 5 && v <= player.treasure }
			#hooks(:prereqs) { |player| player.treasure > 0 }
			hooks(:apply) { |player, value| 
				player.gain_treasure(-value) 
				value.times { player.gain(:gladiator_bet) }
			}
		}
		hooks(:extra_treasure) { |player| player.gain_treasure(2 * player.number_of(:gladiator_bet)) }
	}

	Encounter.new('Goblin', 13, 10, 1, 2)

	Encounter.new('Gold Vein') { 
		hooks(:instead_of_combat) { |player| player.gain_treasure(player.calculate_attack(player.roll(player.attack_dice)) / 5) } # FIXME: doesn't run hooks
	}

	Encounter.new('Gopher', 6, 7, 0, 1)

	Encounter.new('Griffin', 11, 13, 1, 3) {
		hooks(:extra_damage) { |player| player.gain_treasure(-2) }
	}

	Encounter.new('Guardian', 10, 16, 1, 0) {
		hooks(:extra_treasure) { |player, encounter| player.gain(:optional_encounter) && player.queue_fight }
	}

	Encounter.new('Healing Pool') {
		decision_at(:instead_of_combat, 'Heal from Healing Pool') { 
			hooks(:apply) { |player| player.heal(1) }
			hooks(:decline) { |player| player.discard_all_penalty_tokens }
		}
	}

	Encounter.new('Hellhound', 16, 10, 1, 3) {
		decision_at(:extra_treasure, 'Take Extra Hellhound Treasure') { 
			hooks(:apply) { |player| player.wound(1) && player.gain_treasure(3) }
		}
	}

	Encounter.new('Magic Pool') {
		decision_at(:instead_of_combat, 'Take Weapon from Magic Pool') { 
			hooks(:apply) { |player| player.gain_weapon_token }
			hooks(:decline) { |player| player.gain_token(:hero_token) }
		}
	}

	Encounter.new('Mercenary', 18, 20, 2, 4) {
		decision_at(:encounter_selection, 'Skip Mercenary') {
			hooks(:prereqs) { |player| player.treasure >= 1 }
			hooks(:apply) { |player|
				player.gain_treasure(-1)
				player.gain(:skip_encounter)
				player.log '%s pays 1 coin to skip the fight.' % [player.name]
			}
		}
	}

	Encounter.new('Minotaur', 20, 14, 1, 4)

	Encounter.new('Mummy', 18, 14, 0, 3) { # CHECK: how is this affected by doubling - two doubles next turn?
		hooks(:extra_damage) { |player| 
			player.log '%s is afflicted with the Mummy\'s curse!' % [player.name]
			player.next_turn(:take_double_damage) 
		}
	}

	Encounter.new('Mushroom Man', 15, 14, 2, 2) {
		hooks(:extra_treasure) { |player| player.heal(1) }
	}

	Encounter.new('Ogre', 16, 13, 1, 3)

	Encounter.new('Ooze', 20, 11, 1, 3) {
		hooks(:extra_damage) { |player| player.gain_weapon_token(-1) }
	}

	Encounter.new('Pixie', 14, 11, 0, 2) {
		hooks(:extra_damage) { |player| player.gain_treasure(-3) }
	}

	Encounter.new('Shadow', 12, 9, 0, 1) {
		hooks(:extra_damage) { |player| player.wounds <= 1 && player.wound(2) }
	}

	Encounter.new('Skelephant', 13, 8, 1, 2)

	# FIXME: figure out how to store state in Player
	# Encounter.new('Side Passage') { # FIXME: same options next game
	# 	hooks(:encounter_selection) { |player, encounter, game|
	# 		if @options.nil?
	# 			@options = [game.draw_encounter, game.draw_encounter].compact # CHECK: what happens if you run out of cards?
	# 			player.log 'Side Passage options: %s.' % [@options*' or ']
	# 		end
	# 	} 
	# 	hooks(:instead_of_combat) { |player| player.queue_fight(player.decide(:which_encounter, *@options)) } # FIXME: is it ok to assume #decide will return a valid selection
	# }

	Encounter.new('Slime Monster', 22, 18, 1, 4) {
		hooks(:extra_damage) { |player| player.gain_token(:reduced_dice, 1) }
	}

	Encounter.new('Spear Trap') { # CHECK: check this in relation to damage factors, eg mummy?
		hooks(:instead_of_combat) { |player| !player.has?(:dodge_next_trap) && player.wound(1) }
	}

	Encounter.new('Titan', 22, 24, 1, 5)

	Encounter.new('Troll', 20, 15, 1, 4) { # CHECK: does the second version still have mods?
		hooks(:after_encounter) { |player, encounter| !player.has?(:regenerated_troll) && !player.has?(:killed_this_round) && player.gain(:regenerated_troll) && player.queue_fight(encounter) }
	}

	Encounter.new('Unicorn', 12, 8, 1, 0) {
		hooks(:extra_treasure) { |player| player.gain_token(:one_use_die, 1) }
	}

	Encounter.new('Vampire', 21, 18, 0, 4) {
		hooks(:extra_damage) { |player| player.wound(player.wounds >= 2 ? 2 : 1) }
	}

	Encounter.new('Will-o-wisp', 19, 15, 0, 2) { # check damage
		hooks(:extra_damage) { |player| player.gain_token(:hero_token, -1) }
	}

	Encounter.new('Witch', 15, 10, 1, 2) {
		hooks(:extra_damage) { |player| player.gain_token(:reduced_defense, 3) }
	}

	Encounter.new('Wolf', 12, 11, 1, 1)
end

