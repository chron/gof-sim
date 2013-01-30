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

		Encounter.new('Bandit', 14, 14, 1, 3)
			# treasure -> get 1 weapon token

		Encounter.new('Bee Swarm', 10, 6, 1, 0)
			# treasure -> choose 2 gold or 1 hero token

		Encounter.new('Banshee', 23, 16, 0, 4) {
			hooks(:extra_damage) { |player, encounter| player.decide(:take_wound_from_banshee) ? player.wound(1) : player.gain_bonus(:defense, -3) }
		}

		Encounter.new('Behemoth', 20, 21, 1, 4) {
			hooks(:before_encounter) { |player, encounter| 
				if player.weapon_tokens >= 1 && player.decide(:skip_behemoth) 
					player.gain_weapon_token(-1)
					player.gain(:skip_encounter)
					Logger.log '%s pays 1 weapon token to skip the fight.' % [player.name]
				end
			}
		}

		Encounter.new('Brass Golem', 16, 15, 1, 2) {
			hooks(:extra_treasure) { |player| player.has?(:dodged_this_turn) && player.gain_treasure(2) }
		}

		Encounter.new('Cache') {
			hooks(:instead_of_combat) { |player| player.gain_treasure 2 }
		}

		Encounter.new('Carnivorous Plant', 10, 16, 1, 1)

		Encounter.new('Dancing Sword', 21, 8, 1, 3) {
			hooks(:extra_treasure) { |player| player.gain_bonus(:attack, 1) }
		}

		Encounter.new('Demon', 17, 17, 1, 4)
			# no hero tokens or weapon tokens this fight

		Encounter.new('Doppelganger', 14, 0, 1, 3) {# Doppelgänger
			hooks(:before_encounter) { |player, encounter| self.defense = player.defense } # this is so it displays correctish at start
			hooks(:after_rolling) { |player, encounter, rolls| self.defense = player.defense; rolls } # FIXME: or return nil?
		}

		Encounter.new('Extra Bitey') {
			instant!
			hooks(:modifies_next_encounter) { |encounter| encounter.add_prefix(name); encounter.damage *= 2 } # FIXME: use take_double_damage
		}

		Encounter.new('Extra Scary') {
			instant!
			hooks(:modifies_next_encounter) { |encounter| encounter.add_prefix(name); encounter.attack += 3 }
		}

		Encounter.new('Extra Tough') {
			instant!
			hooks(:modifies_next_encounter) { |encounter| encounter.add_prefix(name); encounter.defense += 3 }
		}

		Encounter.new('Extra Wealthy') {
			instant!
			hooks(:modifies_next_encounter) { |encounter| encounter.add_prefix(name); encounter.treasure += 3 } # check this value
		}

		Encounter.new('Fire Elemental', 18, 14, 1, 0) {
			hooks(:extra_treasure) { |player| player.gain_treasure(player.defense / 3) }
		}

		Encounter.new('Gargoyle', 13, 19, 1, 2)

		Encounter.new('Giant', 24, 20, 1, 5)

		Encounter.new('Giant Cockroach', 11, 12, 1, 2) {
			hooks(:extra_treasure) { |player| player.gain_bonus(:armor, -1) }
		}

		Encounter.new('Giant Crab', 8, 18, 1, 2) {
			hooks(:extra_treasure) { |player| player.gain_bonus(:armor) }
		}

		Encounter.new('Giant Scorpion', 19, 12, 2, 3) {
			hooks(:extra_damage) { |player| player.gain(:cannot_die) }
		}

		Encounter.new('Giant Spider', 17, 19, 0, 3) {
			hooks(:extra_damage) { |player| player.gain(:poison) }
		}

		Encounter.new('Giant Toad', 14, 12, 1, 2) {
			hooks(:extra_treasure) { |player| player.gain_bonus(:one_use_die) }
		}

		Encounter.new('Giant Turtle', 9, 14, 1, 1)

		Encounter.new('Gladiator', 15, 15, 1, 3) { # PROMO
			# bet up to 5, receieve double
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
			hooks(:instead_of_combat) { |player| player.heal(1) } # penalties?
		}

		Encounter.new('Hellhound', 16, 10, 1, 3) {
			hooks(:extra_treasure) { |player| player.decide(:take_extra_hellhound_treasure) && player.wound(1) && player.gain_treasure(3) }
		}

		Encounter.new('Magic Pool') {
			hooks(:instead_of_combat) { |player| player.gain_weapon_token; player.gain_hero_token } # should be a choice
		}

		Encounter.new('Mercenary', 18, 20, 2, 4) {
			hooks(:before_encounter) { |player, encounter| 
				if player.treasure >= 1 && player.decide(:skip_mercenary) 
					player.gain_treasure(-1)
					player.gain(:skip_encounter)
					Logger.log '%s pays 1 coin to skip the fight.' % [player.name]
				end
			}
		}

		Encounter.new('Minotaur', 20, 14, 1, 4)

		Encounter.new('Mummy', 18, 14, 0, 3) {
			hooks(:extra_damage) { |player| player.next_turn(:take_double_damage) }
		}

		Encounter.new('Mushroom Man', 15, 14, 2, 2)
			# treasure -> heal 1 wound after combat

		Encounter.new('Ogre', 16, 13, 1, 3)

		Encounter.new('Ooze', 20, 11, 1, 3)
			# damage -> lose 1 weapon token

		Encounter.new('Pixie', 14, 11, 0, 2)
			# damage -> lose 3 gold

		Encounter.new('Shadow', 12, 9, 0, 1)
			# damage: 2 if you have no more than 1, otherwise 0

		Encounter.new('Skelephant', 13, 8, 1, 2)

		Encounter.new('Side Passage') {
			hooks(:encounter_selection) { |game|  # FIXME: existing mods? do mods stack onto second card?
				@options = [game.draw_encounter[0], game.draw_encounter[0]].compact # FIXME: what happens if you run out of cards?
				Logger.log 'Side Passage options: %s.' % [@options*' or ']
			} 
			hooks(:instead_of_combat) { |player| player.queue_fight(player.decide(:which_encounter, *@options)) } # FIXME: is it ok to assume #decide will return a valid selection
		}

		Encounter.new('Slime Monster', 22, 18, 1, 4) {
			hooks(:extra_damage) { |player| player.gain_bonus(:dice, -1) }
		}

		Encounter.new('Spear Trap') { # TODO: check this in relation to damage factors, eg mummy?
			hooks(:instead_of_combat) { |player| !player.has?(:dodge_next_trap) && player.wound(1) }
		}

		Encounter.new('Titan', 22, 24, 1, 5)

		Encounter.new('Troll', 20, 15, 1, 4) { # FIXME: does the second version still have mods?
			hooks(:after_encounter) { |player, encounter| !player.has?(:regenerated_troll) && !player.has?(:killed_this_round) && player.gain(:regenerated_troll) && player.queue_fight(encounter) }
		}

		Encounter.new('Unicorn', 12, 8, 1, 0) {
			hooks(:extra_treasure) { |player| player.gain_bonus(:one_use_die) }
		}

		Encounter.new('Vampire', 21, 18, 0, 4) {
			hooks(:extra_damage) { |player| player.wound(player.wounds >= 2 ? 2 : 1) }
		}

		Encounter.new('Will-o-wisp', 19, 15, 0, 2) { # check damage
			hooks(:extra_damage) { |player| player.gain_hero_token(-1) }
		}

		Encounter.new('Witch', 15, 10, 1, 2) {
			hooks(:extra_damage) { |player| player.gain_bonus(:defense, -3) }
		}

		Encounter.new('Wolf', 12, 11, 1, 1)
	end
end

