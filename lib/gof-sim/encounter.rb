module GauntletOfFools
	class Encounter < GameObject		
		attr_accessor :attack, :defense, :damage, :treasure
		attr_reader :instant

		def initialize name, attack=0, defense=0, damage=0, treasure=0
			super(name)

			@attack, @defense, @damage, @treasure = attack, defense, damage, treasure
		end

		def non_combat?
			@attack == 0
		end

		def display_name
			name + (self.attack > 0 ? " (#{attack}/#{defense})" : '')
		end

		def add_prefix prefix # FIXME: this is kind of dumb
			@name = prefix + ' ' + @name
		end

		def instant!
			@instant = true
		end

		Encounter.new('Banshee', 23, 16, 1, 4) {
			# damage = choose 1 wound or -3 def
		}

		Encounter.new('Behemoth', 20, 21, 1, 4) {
			# You may pay weapon token to skip this fight. 
		}

		Encounter.new('Brass Golem', 16, 15, 1, 2)
			# treasure -> receive 2 more if you both killed and dodged

		Encounter.new('Dancing Sword', 21, 8, 1, 3) {
			hooks(:extra_treasure) { |player| player.bonus_attack += 1 }
		}

		Encounter.new('Doppelgänger', 14, 0, 1, 3)
			# defense = your heros' defense
			# needs to factor buffs etc as well (eg monk!)

		Encounter.new('Fire Elemental', 18, 14, 1, 0) {
			hooks(:extra_treasure) { |player| player.gain_treasure(player.defense / 3) }
		}

		Encounter.new('Gargoyle', 13, 19, 1, 2)

		Encounteer.new('Giant', 24, 20, 1, 5)

		Encounter.new('Giant Cockroach', 11, 12, 1, 2) {
			hooks(:extra_treasure) { |player| player.bonus_defense -= 1 }
		}

		Encounter.new('Giant Crab', 8, 18, 1, 2)
			# treasure -> +1 bonus armor

		Encounter.new('Giant Scorpion', 19, 12, 2, 3) {
			hooks(:extra_damage) { |player| player.gain :cannot_die }
		}

		Encounter.new('Giant Spider', 17, 19, 0, 3)
			# damage = poison (no damage this turn!)

		Encounter.new('Giant Toad', 14, 12, 1, 2) {
			# treasure -> and a one-time dice
		}

		Encounter.new('Giant Turtle', 9, 14, 1, 1)

		Encounter.new('Gladiator', 15, 15, 1, 3) {
			# bet up to 5, receieve double
		}

		Encounter.new('Goblin', 13, 10, 1, 2)

		Encounter.new('Gopher', 6, 7, 0, 1)

		Encounter.new('Griffin', 11, 13, 1, 3) {
			hooks(:extra_damage) { |player| player.gain_treasure -2}
		}

		Encounter.new('Guardian', 10, 16, 1, 0) {
			# treasure = Turn over an Encounter that only you get to use, if you want. (skip and discard modifiers)
		}

		Encounter.new('Hellhound', 16, 10, 1, 3) {
			# treasure -> you may take 1 wound for extra 3 gold
		}

		Encounter.new('Mercenary', 18, 14, 2, 4) {
			# you may pay 1 to skip this fight
		}

		Encounter.new('Minotaur', 20, 14, 1, 4)

		Encounter.new('Mummy', 18, 14, 0, 3) {
			hooks(:extra_damage) { |player| player.next_turn :take_double_damage }
		}

		Encounter.new('Ogre', 16, 13, 1, 3)

		Encounter.new('Skelephant', 13, 8, 1, 2)

		Encounter.new('Slime Monster', 22, 18, 1, 4) {
			hooks(:extra_damage) { |player| player.bonus_dice -= 1 }
		}

		Encounter.new('Troll', 20, 15, 1, 4) {
			# If you don't Kill this, fight it a 2nd time.
		}

		Encounter.new('Unicorn', 12, 8, 1, 0)
			# extra treasure -> one time dice

		Encounter.new('Vampire', 21, 18, 0, 4) {
			hooks(:extra_damage) { |player| player.wound(player.wounds => 2 ? 2 : 1) }
		}

		Encounter.new('Will-o-wisp', 19, 15, 9, 2)
			# extra damage -> lose hero token

		Encounter.new('Witch', 15, 10, 1, 2) {
			hooks(:extra_damage) { |player| player.bonus_defense -= 3 }
		}

		Encounter.new('Wolf', 12, 11, 1, 1)

		Encounter.new('Extra Scary') {
			instant!
			hooks(:modifies_next_encounter) { |encounter| encounter.add_prefix(name); encounter.attack += 3 }
		}

		Encounter.new('Extra Bitey') {
			instant!
			hooks(:modifies_next_encounter) { |encounter| encounter.add_prefix(name); encounter.damage *= 2 } # FIXME: use take_double_damage
		}

		Encounter.new('Extra Tough') {
			instant!
			hooks(:modifies_next_encounter) { |encounter| encounter.add_prefix(name); encounter.defense += 3 }
		}

		Encounter.new('Extra Wealthy') {
			instant!
			hooks(:modifies_next_encounter) { |encounter| encounter.add_prefix(name); encounter.treasure += 3 } # check this value
		}

		#Encounter.new('Side Passage')

		Encounter.new('Cache') {
			hooks(:instead_of_combat) { |player| player.gain_treasure 2 }
		}

		Encounter.new('Gold Vein')
			# roll an attack, 1 gold per 5 attack ( round down)

		Encounter.new('Healing Pool') {
			hooks(:instead_of_combat) { |player| player.heal 1 } # penalties?
		}

		Encounter.new('Magic Pool') {
			hooks(:instead_of_combat) { |player| player.gain_weapon_token; player.hero_tokens += 1 } # should be a choice
		}

		Encounter.new('Spear Trap') { # TODO: THIS CAN BE DODGED
			hooks(:instead_of_combat) { |player| player.wound 1 }
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
# 		| Giant Cockr. 	| Griffin 		| Wolf			| Pixie 		| Slime Monster	|
# 		| Behemoth 		| Fire Elemental	| Gargoyle 		| Gold Vein		| Cache |
	end
end