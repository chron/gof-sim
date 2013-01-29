module GauntletOfFools
	class Weapon < GameObject
		attr_reader :dice, :tokens
		
		def initialize name, dice, tokens
			super(name)

			@dice, @tokens = dice, tokens
		end

		Weapon.new('Axe', 5, 2) {
			hooks(:before_rolling) { |player,encounter| player.decide(:use_axe) && player.spend_weapon_token && player.gain(:double_attack) && player.next_turn(:zero_attack) }
		}

		Weapon.new('Bow', 4, 2) {
			hooks(:after_attack) { |player,encounter| player.has? :killed_this_round && player.decide(:use_bow) && player.spend_weapon_token && player.gain(:dodge_next) }
		}

		Weapon.new('Dagger', 3, 4) {
			hooks(:before_rolling) { |player,encounter| player.decide(:use_dagger) && player.spend_weapon_token && player.gain(:kill_next) }
		}

		Weapon.new('Deadly Fists', 3, 2) {
			hooks(:before_rolling) { |player,encounter| player.decide(:use_deadly_fists) && player.spend_weapon_token && player.gain(:kill_next) && player.gain(:dodge_next) }
		}

		Weapon.new('Demonic Blade', 4, 0) {
			hooks(:extra_treasure) { |player,encounter| player.gain_weapon_token }
			hooks(:before_rolling) { |player,encounter| 
			n = player.decide(:use_demonic_blade)
			player.spend_weapon_token(n) && player.gain_temp(:dice, 2*n) } # FIXME: multiples
		}

		Weapon.new('Flaming Sword', 5, 2) {
			hooks(:before_rolling) { |player, encounter| player.decide(:use_flaming_sword) && player.spend_weapon_token && player.wound(1) && player.gain(:kill_next) && player.gain(:dodge_next) }
		}

		Weapon.new('Holy Sword', 5, 2) {
			hooks(:before_rolling) { |player, encounter| player.decide(:use_holy_sword) && player.spend_weapon_token && player.discard_all_penalty_tokens && player.gain(:ignore_boasts) }
		}

		Weapon.new('Mace', 5, 2) { # check tokens
			hooks(:after_rolling) { |player, encounter, rolls|
				n = player.decide(:use_mace, rolls)
				player.spend_weapon_token(n) && rolls + player.roll(n)
			}
		}

		Weapon.new('Morning Star', 5, 2) {
			hooks(:after_rolling) { |player, encounter, rolls|
				player.decide(:use_morning_star, rolls) && player.spend_weapon_token && player.roll(rolls.size)
			}
		}

		Weapon.new('Sack of Loot', 3, 0) {
			hooks(:bonus_attack) { |player,encounter| player.treasure }
			hooks(:at_start) { |player| player.gain_treasure(1) }
		}

		Weapon.new('Scepter', 4, 2) {
			hooks(:before_rolling) { |player, encounter| encounter.attack < encounter.defense && player.decide(:use_scepter) && player.spend_weapon_token && player.gain(:kill_next) }
		}

		Weapon.new('Scimitar', 4, 2) { # FIXME: can this be used multiple times?
			# FIXME: doesn't have to be 2 lowest
			hooks(:after_rolling) { |player, encounter, rolls|
				if player.decide(:use_scimitar, rolls) && player.spend_weapon_token
					if rolls.empty?
						[]
					elsif rolls.size == 1
						player.roll(1)
					else
						rolls.sort[2..-1] + player.roll(2)
					end
				end
			}
		}

		Weapon.new('Sling', 3, 2) {
			hooks(:before_rolling) { |player, encounter| encounter.attack >= 20 && player.decide(:use_sling) && player.spend_weapon_token && player.gain(:kill_next) && player.gain(:dodge_next) }
		}

		Weapon.new('Spear', 4, 2) {
			hooks(:after_rolling) { |player, encounter, rolls|
				player.decide(:use_spear, rolls) && player.spend_weapon_token && [14] # FIXME: make sure this can't be rerolled or whatever
			}
		}

		Weapon.new('Spiked Shield', 3, 2) {
			hooks(:at_start) { |player| player.gain_bonus(:defense, 1) }
			hooks(:after_rolling) { |player, encounter, rolls| encounter.attack >= player.defense && player.decide(:use_spiked_shield, rolls) && player.spend_weapon_token && player.gain(:kill_next) }
		}

		Weapon.new('Staff', 3, 4) { # Spend a token before rolling, either +2 Attack Dice or +6 Defense this turn.
			hooks(:before_rolling) { |player, encounter|
				n1, n2 = player.decide(:use_staff)
				(n1 || n2) && player.spend_weapon_token(n1+n2) && player.gain_temp(:dice,2*n1) && player.gain_temp(:defense, 6*n2)
			}
		}

		Weapon.new('Sword', 4, 2) {
			hooks(:after_attack) { |player, encounter| 
				n = player.decide(:use_sword)
				player.spend_weapon_token(n) && player.gain_temp(:defense, 3*n)
			}
		}

		Weapon.new('Throwing Stars', 2, 20) { 
			hooks(:before_rolling) { |player,encounter| 
				n = player.decide(:use_throwing_stars)
				player.spend_weapon_token(n) && player.gain_temp(:dice, n)
			}
		}

		# Weapon.new('Wand', 5, 2)
			# at the start of each turn, you may look at and reorder the top two cards in the encounter deck
			# pay 1 token -> discard one

		Weapon.new('Whip', 4, 2) {
			hooks(:after_attack) { |player,encounter| !player.has?(:killed_this_round) && player.spend_weapon_token && player.gain(:dodge_next) }
		}

		Weapon.new('Cleaver', 1, 0) # PROMO CARD # FIXME: this is implemented via magic
	end
end