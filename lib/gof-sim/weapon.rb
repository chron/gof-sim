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

		Weapon.new('Demonic Blade', 4, 2) { # check number of tokens
			hooks(:before_rolling) { |player,encounter| 
			n = player.decide(:use_demonic_blade)
			player.spend_weapon_token(n) && player.gain_temp_dice(2*n) } # FIXME: multiples
		}

		# Weapon.new('Flaming Sword', 0, 0)

		# Weapon.new('holy_sword', 5, 2) # Spend a token before rolling, discard all Penalty tokens, and ignore your Boasts this turn.
		
		Weapon.new('Mace', 5, 2) { # check tokens
			hooks(:after_rolling) { |player, encounter, rolls|
				n = player.decide(:use_mace, rolls)
				player.spend_weapon_token(n) && (rolls + player.roll(n))
			}
		}

		Weapon.new('Morning Star', 5, 2) {
			hooks(:after_rolling) { |player, encounter, rolls|
				player.decide(:use_morning_star, rolls) && player.spend_weapon_token && player.roll(rolls.size)
			}
		}

		Weapon.new('Sack of Loot', 3, 0) {
			hooks(:bonus_damage) { |player,encounter| player.treasure }
			hooks(:at_start) { |player| player.gain_treasure(1) }
		}

		Weapon.new('Scimitar', 4, 2) { # FIXME: can this be used multiple times?
			# FIXME: doesn't have to be 2 lowest
			hooks(:after_rolling) { |player, encounter, rolls|
				if player.decide(:use_scimitar, rolls) && player.spend_weapon_token
					# FIXME: what if they only had < 2 dice to begin with
					rolls.sort[2..-1] + player.roll(2)
				end
			}
		}

		# Weapon.new('Spear', 0, 0) { # use 14 instead of your roll

		Weapon.new('Spiked Shield', 3, 2) {
			hooks(:at_start) { |player| player.bonus_defense += 1 }
			hooks(:before_rolling) { |player,encounter| encounter.attack >= player.defense && player.spend_weapon_token && player.gain(:kill_next) } # condition not quite right
			# Spend a token after rolling, to Kill a Monster that Damaged you.
		}

		# Weapon.new('Staff', 3, 4) { # Spend a token before rolling, either +2 Attack Dice or +6 Defense this turn..

		Weapon.new('Throwing Stars', 2, 20) { 
			hooks(:before_rolling) { |player,encounter| 
				n = player.decide(:use_throwing_stars)
				player.spend_weapon_token(n) && player.gain_temp_dice(n)
			}
		}

		# Weapon.new('Wand', 5, 2)
			# at the start of each turn, you may look at and reorder the top two cards in the encounter deck
			# pay 1 token -> discard one

		Weapon.new('Whip', 4, 2) {
			hooks(:after_attack) { |player,encounter| !player.has?(:killed_this_round) && player.spend_weapon_token && player.gain(:dodge_next) }
		}

		# Weapon.new('Cleaver', 1, 0) { # PROMO CARD
		#	hooks(:attack_calc) { |rolls,bonuses,factor| (rolls.inject(0) { |total,d| total + 4*d } + bonuses) * factor }
		#	hooks(:hit_chance_calc) { |player,defense| # FIXME: DRY this a bit
		#		d = Player::DISTRIBUTION[player.attack_dice].map { |k,v| [(4*k + player.bonus_attack) * player.attack_factor, v] }
		#		d.inject(0) { |s,(k,v)| s + (k >= defense ? v : 0) }.to_f / d.transpose.last.sum
		#	}
		#}
	end
end