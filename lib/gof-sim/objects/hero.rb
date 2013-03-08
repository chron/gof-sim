module GauntletOfFools
	class Hero < GameObject
		attr_reader :defense, :tokens, :number_of_weapons

		def initialize name, defense, tokens
			@number_of_weapons = 1
			@defense, @tokens = defense, tokens

			super(name)
		end

		Hero.new('Adventurer', 15, 2) {
			decision_at(:after_encounter) {
				only_if { |player| !player.has?(:second_adventure) }
				spend_hero_token_to { |player| player.gain(:second_adventure) && player.queue_fight(player.current_encounter) }
			}
		}

		Hero.new('Alchemist', 14, 2) {
			decision_at(:end_of_turn) { 
				only_if { |player| player.has?(:killed_this_round) && player.has?(:dodged_this_round) && player.wounds > 0 }
				spend_hero_token_to { |player| player.heal(1) }
			}
		}

		Hero.new('Armorer', 13, 2) {
			decision_at(:after_combat) {
				only_if { |player| player.has?(:killed_this_round) }
				spend_hero_token_to { |player| player.gain_token(:defense, 3) && player.gain(:no_treasure) }
			}
		}

		Hero.new('Armsmaster', 14, 0) { # PROMO CARD
			@number_of_weapons = 2
		} 

		Hero.new('Artificer', 15, 2) {
			decision_at(:after_combat) { 
				only_if { |player| player.has?(:killed_this_round) }
				spend_hero_token_to { |player| player.gain_token(:dice, 1) && player.gain(:no_treasure) }
			}
		}

		Hero.new('Avenger', 16, 2) {
			hooks(:end_of_turn) { |player| player.opponents.count { |p| p.dead? }.times { player.next_turn(:fallen_comrade) }} # has to have died on previous turns
			decision_at(:after_rolling) {
				# CHECK: is this once per turn?
				only_if { |player| player.number_of(:fallen_comrade) > 0 }
				spend_hero_token_to { |player| player.gain_token(:temp_attack,3*player.number_of(:fallen_comrade)) }
			}
		}

		Hero.new('Barbarian', 18, 0)

		Hero.new('Berserker', 14, 2) {
			decision_at(:before_rolling) {
				spend_hero_token_to { |player| player.gain_token(:temp_dice, player.wounds) && player.gain(:berserk) }
			}
			hooks(:after_attack) { |player, encounter| player.has?(:berserk) && player.has?(:killed_this_round) && player.gain(:dodge_next) }
		}

		Hero.new('Jester', 14, 2)  {
			decision_at(:before_rolling) {
				spend_hero_token_to { |player| player.gain(:swap_attack_and_defense) }
				# CHECK: only lasts for this fight?
			}
			hooks(:after_encounter) { |player| player.clear_effect(:swap_attack_and_defense) }
		}

		Hero.new('Knight', 16, 2) {
			decision_at(:after_attack) { # CHECK: is this the right hook?
				spend_hero_token_to { |player| player.gain(:no_damage) && player.wound(1) } # CHECK: case of zero wounds?
			}
		}

		Hero.new('Monk', 10, 4) { # FIXME: before_damage??? what hook is this supposed to be
			decision_at(:before_rolling) {
				spend_n_hero_tokens_to { |player, value| player.gain_token(:temp_dice, value) && player.gain_token(:temp_defense, 4*value) }
			}
		}

		# CHECK: does this include passives?
		#Hero.new('Necromancer', 16, 2) { # FIXME: check interaction with zombie + prospector
		#	# CHECK: zombies using their power? zombies that have become alive again?
		#	hooks(:end_of_turn) { |player| player.opponents.each { |p| p.dead? && !player.delegates.include?(p.hero) && p.delegates << p.hero }} # has to have died on previous turns
		#}

		Hero.new('Ninja', 17, 0) {
			hooks(:at_start) { |player| player.gain_weapon_token(player.weapon_tokens) }
		}

		Hero.new('Priest', 14, 2) { # FIXME: zero attack = don't attack?
			decision_at(:before_rolling) { 
				only_if { |player| player.wounds > 0 } 
				spend_hero_token_to { |player| player.heal(1) && player.gain(:zero_attack, :no_weapon_tokens) }
			}
		}

		Hero.new('Prospector', 15, 0) {
			hooks(:after_encounter) { |player,encounter| !player.dead? && player.gain_treasure(1) }
		}

		Hero.new('Thief', 13, 2) {
			decision_at(:before_rolling, 'Use Thief For Trap') { 
				only_if { |player| player.current_encounter.name == "Spear Trap" }
				spend_hero_token_to { |player| player.gain(:dodge_next_trap) }
			}
			decision_at(:after_attack) {
				spend_hero_token_to { |player| player.gain(:dodge_next) }
			}
		}

		Hero.new('Trapper', 16, 2) {
			decision_at(:before_rolling) {
				# FIXME: once per fight, lasts whole turn: multiples?
				only_if { |player| !player.has?(:trapper_bounty) }
				spend_hero_token_to { |player| player.gain(:trapper_bounty) }
			}
			hooks(:extra_treasure) { |player, encounter| player.has?(:trapper_bounty) && player.gain_treasure(2) } 
		}

		Hero.new('Warlord', 12, 2) {
			hooks(:attack_dice) { |player, encounter, dice| dice + 1 } # FIXME: broken
			decision_at(:after_rolling) {
				repeatable!
				spend_hero_token_to { |player| player.current_roll.concat(player.roll(1)) }
			}
		}

		Hero.new('Wizard', 15, 2) { # NB: should be able to skip demons
			decision_at(:before_rolling) {
				spend_hero_token_to { |player| player.gain(:skip_encounter) }
			}
		}

		Hero.new('Zealot', 15, 2) { # zeroes defense but you can still raise it after, unlike zero_attack
			decision_at(:before_rolling) {
				spend_hero_token_to { |player| player.gain(:kill_next) && player.gain(:zero_defense) }
			}
		}

		Hero.new('Zombie', 13, 2) {
			decision_at(:start_of_turn) { 
				only_if { |player| player.dead? }
				spend_hero_token_to { |player| player.gain(:cannot_die) }
			}
		}
	end
end