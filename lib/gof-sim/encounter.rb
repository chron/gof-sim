module GauntletOfFools
	class Encounter < Deck
		attr_accessor :name, :attack, :defense, :damage, :treasure
		attr_reader :instead_of_combat, :modifies_next_encounter, :instead_of_damage
		
		def initialize name
			@damage, @treasure, = 1, 0 # FIXME: define default attack/defense?
			@name = name
		end

		def to_s
			name
		end

		def display_name
			name + (attack ? " (#{attack}/#{defense})" : '')
		end

		def add_prefix prefix # FIXME: this is kind of dumb
			@name = prefix + ' ' + @name
		end

		goblin {
			attack 13
			defense 10
			treasure 2
		}

		skelephant {
			attack 13
			defense 8
			treasure 2
		}

		banshee {
			attack 23
			defense 16
			treasure 4
			# damage = choose 1 wound or -3 def
		}

		gladiator {
			attack 15
			defense 15
			treasure 3 # bet up to 5, receieve double
		}

		giant_turtle {
			attack 9
			defense 14
			treasure 1
		}

		mummy {
			attack 18
			defense 14
			treasure 3
			modifies_next_encounter { |encounter| encounter.damage *= 2 }
		}

		giant_scorpion {
			attack 19
			defense 12
			treasure 3
			damage 2 # but you won't die this turn
		}

		witch {
			attack 15
			defense 10
			treasure 2
			isntead_of_damage { |player| player.wound 1; player.bonus_defense -= 3 }
		}

		troll {
			attack 20
			defense 15
			treasure 4
			# If you don't Kill this, fight it a 2nd time.
		}

		ogre {
			attack 16
			defense 13
			treasure 3
		}

		gargoyle {
			attack 13
			defense 19
			treasure 2
		}

		minotaur {
			attack 20
			defense 14
			treasure 4
		}

		mercenary {
			attack 18
			defense 14
			treasure 4
			damage 2
			# you may pay 1 to skip this fight
		}

		behemoth {
			attack 20
			defense 21
			treasure 4
			# You may pay weapon token to skip this fight. 
		}

		giant_toad {
			attack 14
			defense 12
			treasure 2 # and a one-time dice
		}

		vampire {
			attack 21
			defense 18
			treasure 3
			instead_of_damage { |player| player.wound(player.wounds >= 2 ? 2 : 1) }
		}

		giant_cockroach {
			attack 11
			defense 12
			instead_of_treasure { |player| player.gain_treasure 1; player.bonus_defense -= 1 }
		}

		slime_monster {
			attack 22
			defense 18
			treasure 4
			instead_of_damage { |player| player.wound 1; player.bonus_dice -= 1 }
		}

		guardian {
			attack 10
			defense 16
			# treasure = Turn over an Encounter that only you get to use, if you want.
			unfinished!
		}

		fire_elemental {
			attack 18
			defense 14
			instead_of_treasure { |player| player.gain_treasure(player.defense / 3) }
		}

		griffin {
			attack 11
			defense 13
			treasure 3
			instead_of_damage { |player| player.wound 1; player.gain_treasure -2}
		}

		extra_scary {
			foo 'test'
			modifies_next_encounter { |encounter| encounter.add_prefix(name); encounter.attack += 3 }
		}

		extra_bitey {
			modifies_next_encounter { |encounter| encounter.add_prefix(name); encounter.damage *= 2 }
		}

		extra_tough {
			modifies_next_encounter { |encounter| encounter.add_prefix(name); encounter.defense += 3 }
		}

		extra_wealthy {
			modifies_next_encounter { |encounter| encounter.add_prefix(name); encounter.treasure += 3 } # check this value
		}

		cache {
			instead_of_combat { |player| player.gain_treasure 2 }
		}

		healing_pool {
			instead_of_combat { |player| player.heal 1 }
		}

		magic_pool {
			instead_of_combat { |player| player.weapon_tokens += 1 } # possible to choose hero token?
		}

		spear_trap {
			instead_of_combat { |player| player.wound 1 }
		}

=begin
Giant Crab
Titan
Mushroom Man	
Ooze
Doppelgänger	
Demon 
Side Passage
Carniv. Plant
Shadow
Gopher
Bandit
Hellhound
Unicorn
Giant
Danc. Sword
Brass Golem
Will-o-wisp
Bee Swarm
Griffin
Wolf
Pixie
Gold Vein
=end

#		| Extra Bitey 	| Giant Crab		| Titan			| Mushroom Man	| Giant Toad |
# 		| Healing Pool 	| Ooze			| Doppelgänger	| Mercenary		| Giant Scorp. |
# 		| Vampire 		| Demon 			| Gladiator (P)	| Guardian		| Side Passage |
# 		| Mummy 			| Carniv. Plant	| Shadow 		| Ogre			| Gopher |
# 		| Extra Tough 	| Skelephant 	| Bandit 		| Witch			| Hellhound |
# 		| Unicorn 		| Minotaur 		| Giant 			| Troll			| Danc. Sword |
# 		| Extra Wealthy | Brass Golem 	| Extra Scary 	| Will-o-wisp	| Banshee |
# 		| Goblin 		| Giant Turtle 	| Spear Trap 	| Magic Pool	| Bee Swarm |
# 		| Giant Cockr. 	| Griffin | Wolf	| Pixie 		| Slime Monster	|
# 		| Behemoth 		| Fire Elemental	| Gargoyle 		| Gold Vein		| Cache |
	end
end