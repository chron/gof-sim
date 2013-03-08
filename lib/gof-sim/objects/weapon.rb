module GauntletOfFools
	class Weapon < GameObject
		attr_reader :dice, :tokens, :dice_factor
		
		def initialize name, dice, tokens
			@dice, @tokens = dice, tokens
			@dice_factor = 1

			super(name)
		end

		Weapon.new('Axe', 5, 2) {
			decision_at(:before_rolling) {
				spend_weapon_token_to { |player| player.gain(:double_attack) && player.next_turn(:zero_attack) }
			}
		}

		Weapon.new('Bow', 4, 2) {
			decision_at(:after_attack) { 
				only_if { |player| player.has?(:killed_this_round) }
				spend_weapon_token_to { |player| player.gain(:dodge_next) }
			}
		}

		Weapon.new('Cleaver', 1, 0) {
			@dice_factor = 4
		}

		Weapon.new('Dagger', 3, 4) {
			decision_at(:before_rolling) { 
				spend_weapon_token_to { |player| player.gain(:kill_next) }
			}
		}

		Weapon.new('Deadly Fists', 3, 2) {
			decision_at(:before_rolling) { 
				spend_weapon_token_to { |player| player.gain(:kill_next, :dodge_next) }
			}
		}

		Weapon.new('Demonic Blade', 4, 0) {
			hooks(:extra_treasure) { |player| player.gain_weapon_token(1, @owner)  }
			decision_at(:before_rolling) {
				spend_n_weapon_tokens_to { |player, value| player.gain_token(:temp_dice, 2*value) }
			}
		}

		Weapon.new('Flaming Sword', 5, 2) {
			decision_at(:before_rolling) {
				spend_weapon_token_to { |player| player.wound && player.gain(:kill_next, :dodge_next) }
			}
		}

		Weapon.new('Holy Sword', 5, 2) {
			decision_at(:before_rolling) {
				only_if { |player| !player.brags.empty? || Player::PENALTY_TOKENS.any? { |t| player.tokens(t) >= 1 } }
				spend_weapon_token_to { |player| player.discard_all_penalty_tokens && player.gain(:ignore_brags) }
			}
		}

		Weapon.new('Mace', 5, 2) { # CHECK: how do these after_rolling dice interact with multiple encounters in a turn?
			decision_at(:after_rolling) {
				repeatable!
				spend_weapon_token_to { |player| player.current_roll.concat(player.roll(1)) }
			}
		}

		Weapon.new('Morning Star', 5, 2) {
			decision_at(:after_rolling) {
				spend_weapon_token_to { |player| player.current_roll = player.roll(player.current_roll.size) }
			}
		}

		Weapon.new('Sack of Loot', 3, 0) {
			hooks(:at_start) { |player| player.gain_treasure(1) }
			hooks(:before_rolling) { |player| player.gain_token(:temp_attack, player.treasure) } # FIXME: spams the log every turn
		}

		Weapon.new('Scepter', 4, 2) {
			decision_at(:before_rolling) { 
				only_if { |player| player.current_encounter.attack < player.current_encounter.defense }
				spend_weapon_token_to { |player| player.gain(:kill_next) }
			}
		}

		Weapon.new('Scimitar', 4, 2) { # FIXME: can this be used multiple times?
			decision_at(:after_rolling) {
				only_if { |player| !player.current_roll.empty? }
				 # FIXME: doesn't have to be 2 lowest
				spend_weapon_token_to { |player| player.current_roll = player.current_roll.size == 1 ? player.roll(1) : player.current_roll.sort[2..-1] + player.roll(2) }
			}
		}

		Weapon.new('Sling', 3, 2) {
			decision_at(:before_rolling) { 
				only_if { |player| player.current_encounter.attack >= 20 }
				spend_weapon_token_to { |player| player.gain(:kill_next, :dodge_next) }
			}
		}

		Weapon.new('Spear', 4, 2) {
			decision_at(:after_rolling) {
				# FIXME: make sure this can't be rerolled?
				spend_weapon_token_to { |player| player.current_roll = [14] }
			}
		}

		Weapon.new('Spiked Shield', 3, 2) {
			hooks(:at_start) { |player| player.gain_token(:defense, 1) }
			decision_at(:after_rolling) {
				# FIXME: doesn't account for :dodge_next properly, timing?
				only_if { |player| player.current_encounter.attack >= player.defense && !player.has?(:dodge_next) }
				spend_weapon_token_to { |player| player.gain(:kill_next) }
			}
		}

		Weapon.new('Staff', 3, 4) {
			decision_at(:before_rolling) {
				spend_weapon_token_to { |player| player.gain_token(:temp_dice, 2) }
			}

			decision_at(:before_rolling, 'Use Staff Defensively') {
				spend_weapon_token_to { |player| player.gain_token(:temp_defense, 6) }
			}
		}

		Weapon.new('Sword', 4, 2) {
			decision_at(:after_attack) {
				spend_n_weapon_tokens_to { |player, value| player.gain_token(:temp_defense, 3*value) }
			}
		}

		Weapon.new('Throwing Stars', 2, 20) { 
			decision_at(:before_rolling) {
				spend_n_weapon_tokens_to { |player, value| player.gain_token(:temp_dice, value) }
			}
		}

		#Weapon.new('Wand', 5, 2) {
			# at the start of each turn, you may look at and reorder the top two cards in the encounter deck
			# pay 1 token -> discard one
		#	hooks(:start_of_turn) { |player, game| player.decide(:reorder_encounter_deck, *game.peek_at_deck(2))}
		#}

		Weapon.new('Whip', 4, 2) {
			decision_at(:after_attack) {
				only_if { |player| !player.has?(:killed_this_round) }
				spend_weapon_token_to { |player| player.gain(:dodge_next) }
			}
		}
	end
end