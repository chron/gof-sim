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
				requires_weapon_token
				hooks(:apply) { |player| player.spend_weapon_token(@owner) && player.gain(:double_attack) && player.next_turn(:zero_attack) }
			}
		}

		Weapon.new('Bow', 4, 2) {
			decision_at(:after_attack) { 
				hooks(:prereqs) { |player| player.has?(:killed_this_round) && player.weapon_tokens(@owner) >= 1 }
				hooks(:apply) { |player| player.spend_weapon_token(@owner) && player.gain(:dodge_next) }
			}
		}

		Weapon.new('Cleaver', 1, 0) {
			@dice_factor = 4
		}

		Weapon.new('Dagger', 3, 4) {
			decision_at(:before_rolling) { 
				requires_weapon_token
				hooks(:apply) { |player| player.spend_weapon_token(@owner) && player.gain(:kill_next) }
			}
		}

		Weapon.new('Deadly Fists', 3, 2) {
			decision_at(:before_rolling) { 
				requires_weapon_token
				hooks(:apply) { |player| player.spend_weapon_token(@owner) && player.gain(:kill_next, :dodge_next) }
			}
		}

		Weapon.new('Demonic Blade', 4, 0) {
			hooks(:extra_treasure) { |player| player.gain_weapon_token(1, @owner)  }
			decision_at(:before_rolling) {
				requires_weapon_token
				limit_values_to { |value| value >= 0 && value <= player.weapon_tokens(@owner) }
				hooks(:apply) { |player, value| player.spend_weapon_token(@owner) && player.gain_token(:temp_dice, 2*value) }
			}
		}

		Weapon.new('Flaming Sword', 5, 2) {
			decision_at(:before_rolling) {
				hooks(:prereqs) { |player| player.weapon_tokens(@owner) >= 1 }
				hooks(:apply) { |player| player.spend_weapon_token(@owner) && player.wound && player.gain(:kill_next, :dodge_next) }
			}
		}

		Weapon.new('Holy Sword', 5, 2) {
			decision_at(:before_rolling) {
				requires_weapon_token # FIXME: check for penalty tokens / boasts
				hooks(:apply) { |player| player.spend_weapon_token(@owner) && player.discard_all_penalty_tokens && player.gain(:ignore_boasts) }
			}
		}

		Weapon.new('Mace', 5, 2) { # CHECK: how do these after_rolling dice interact with multiple encounters in a turn?
			decision_at(:after_rolling) {
				repeatable!
				requires_weapon_token
				hooks(:apply) { |player| player.spend_weapon_token(@owner) && player.current_roll.concat(player.roll(1)) }
			}
		}

		Weapon.new('Morning Star', 5, 2) {
			hooks(:after_rolling) { |player, encounter|
				player.decide(:use_morning_star) && spend_weapon_token(player) && player.current_roll = player.roll(player.current_roll.size)
			}
		}

		Weapon.new('Sack of Loot', 3, 0) {
			hooks(:bonus_attack) { |player, encounter| player.treasure }
			hooks(:at_start) { |player| player.gain_treasure(1) }
		}

		Weapon.new('Scepter', 4, 2) {
			decision_at(:before_rolling) { 
				hooks(:prereqs) { |player| player.current_encounter.attack < player.current_encounter.defense && player.weapon_tokens(@owner) >= 1 }
				hooks(:apply) { |player| player.spend_weapon_token(@owner) && player.gain(:kill_next) }
			}
		}

		Weapon.new('Scimitar', 4, 2) { # FIXME: can this be used multiple times?
			hooks(:after_rolling) { |player, encounter|
				if !player.current_roll.empty? && player.decide(:use_scimitar) && spend_weapon_token(player)
					if rolls.size == 1
						player.current_roll = player.roll(1)
					else # FIXME: doesn't have to be 2 lowest
						player.current_roll = player.current_roll.sort[2..-1] + player.roll(2)
					end
				end
			}
		}

		Weapon.new('Sling', 3, 2) {
			decision_at(:before_rolling) { 
				hooks(:prereqs) { |player| player.current_encounter.attack >= 20 && player.weapon_tokens(@owner) >= 1 }
				hooks(:apply) { |player| player.spend_weapon_token(@owner) && player.gain(:kill_next, :dodge_next) }
			}
		}

		Weapon.new('Spear', 4, 2) {
			decision_at(:after_rolling) {
				requires_weapon_token
				# FIXME: make sure this can't be rerolled?
				hooks(:apply) { |player| player.spend_weapon_token(player) && player.current_roll = [14] }
			}
		}

		Weapon.new('Spiked Shield', 3, 2) {
			hooks(:defense) { |player, encounter, defense| defense + 1 }
			# FIXME: doesn't account for :dodge_next properly, timing?
			hooks(:after_rolling) { |player, encounter| encounter.attack >= player.defense && !player.has?(:dodge_next) && player.decide(:use_spiked_shield) && spend_weapon_token(player) && player.gain(:kill_next) }
		}

		Weapon.new('Staff', 3, 4) {
			hooks(:before_rolling) { |player, encounter|
				n1, n2 = player.decide(:use_staff)
				(n1 || n2) && spend_weapon_token(player, n1+n2) && player.gain_token(:temp_dice,2*n1) && player.gain_token(:temp_defense, 6*n2)
			}
		}

		Weapon.new('Sword', 4, 2) {
			hooks(:after_attack) { |player, encounter| 
				n = player.decide(:use_sword)
				spend_weapon_token(player, n) && player.gain_token(:temp_defense, 3*n)
			}
		}

		Weapon.new('Throwing Stars', 2, 20) { 
			hooks(:before_rolling) { |player,encounter| 
				n = player.decide(:use_throwing_stars)
				spend_weapon_token(player, n) && player.gain_token(:temp_dice, n)
			}
		}

		#Weapon.new('Wand', 5, 2) {
			# at the start of each turn, you may look at and reorder the top two cards in the encounter deck
			# pay 1 token -> discard one
		#	hooks(:start_of_turn) { |player, game| player.decide(:reorder_encounter_deck, *game.peek_at_deck(2))}
		#}

		Weapon.new('Whip', 4, 2) {
			hooks(:after_attack) { |player,encounter| !player.has?(:killed_this_round) && spend_weapon_token(player) && player.gain(:dodge_next) }
		}
	end
end