module GauntletOfFools
	class Weapon < GameObject
		attr_reader :dice, :tokens, :dice_factor
		
		def initialize name, dice, tokens
			@dice, @tokens = dice, tokens
			@dice_factor = 1

			super(name)
		end

		def has_weapon_token player, amount=1
			player.weapon_tokens(name) >= amount
		end

		def spend_weapon_token player, amount=1
			player.spend_weapon_token(amount, name)
		end

		def gain_weapon_token player, amount=1
			player.gain_weapon_token(amount, name)
		end

		Weapon.new('Axe', 5, 2) {
			hooks(:before_rolling) { Decision['Use Axe'].from(self) }
		}

		Weapon.new('Bow', 4, 2) {
			hooks(:after_attack) { |player,encounter| player.has?(:killed_this_round) && player.decide(:use_bow) && spend_weapon_token(player) && player.gain(:dodge_next) }
		}

		Weapon.new('Cleaver', 1, 0) {
			@dice_factor = 4
		}

		Weapon.new('Dagger', 3, 4) {
			hooks(:before_rolling) { |player,encounter| player.decide(:use_dagger) && spend_weapon_token(player) && player.gain(:kill_next) }
		}

		Weapon.new('Deadly Fists', 3, 2) {
			hooks(:before_rolling) { |player,encounter| player.decide(:use_deadly_fists) && spend_weapon_token(player) && player.gain(:kill_next, :dodge_next) }
		}

		Weapon.new('Demonic Blade', 4, 0) {
			hooks(:extra_treasure) { |player,encounter| gain_weapon_token(player)  }
			hooks(:before_rolling) { |player,encounter| 
				n = player.decide(:use_demonic_blade)
				spend_weapon_token(player, n) && player.gain_token(:temp_dice, 2*n)
			}
		}

		Weapon.new('Flaming Sword', 5, 2) {
			hooks(:before_rolling) { |player, encounter| Decision['Use Flaming Sword'] }
		}

		Weapon.new('Holy Sword', 5, 2) {
			hooks(:before_rolling) { |player, encounter| player.decide(:use_holy_sword) && spend_weapon_token(player) && player.discard_all_penalty_tokens && player.gain(:ignore_boasts) }
		}

		Weapon.new('Mace', 5, 2) {
			hooks(:after_rolling) { |player, encounter|
				n = player.decide(:use_mace)
				spend_weapon_token(player, n) && player.current_roll.concat(player.roll(n))
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
			hooks(:before_rolling) { |player, encounter| encounter.attack < encounter.defense && player.decide(:use_scepter) && spend_weapon_token(player) && player.gain(:kill_next) }
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
			hooks(:before_rolling) { |player, encounter| encounter.attack >= 20 && player.decide(:use_sling) && spend_weapon_token(player) && player.gain(:kill_next, :dodge_next) }
		}

		Weapon.new('Spear', 4, 2) {
			hooks(:after_rolling) { |player, encounter|
				player.decide(:use_spear) && spend_weapon_token(player) && player.current_roll = [14] # FIXME: make sure this can't be rerolled?
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