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
			hooks(:after_attack) { |player,encounter| player.has? :killed_this_round && player.decide(:use_bow) && player.spend_weapon_token && player.dodge }
		}

		Weapon.new('Dagger', 3, 4) {
			hooks(:before_rolling) { |player,encounter| player.decide(:use_dagger) && player.spend_weapon_token && player.kill }
		}

		Weapon.new('Deadly Fists', 3, 2) {
			hooks(:before_rolling) { |player,encounter| player.decide(:use_deadly_fists) && player.spend_weapon_token && player.kill && player.dodge }
		}

		Weapon.new('Demonic Blade', 4, 2) { # check number of tokens
			hooks(:before_rolling) { |player,encounter| 
			n = player.decide(:use_demonic_blade)
			player.spend_weapon_token(n) && player.gain_temp_dice(2*n) } # FIXME: multiples
		}

		# Weapon.new('Flaming Sword', 0, 0)

		# Weapon.new('holy_sword', 5, 2) # Spend a token before rolling, discard all Penalty tokens, and ignore your Boasts this turn.
		
		#Weapon.new('Mace', 5, 0) { # check tokens
		#	# Spend a token after rolling, roll an extra Attack Dice.
		#}

		#Weapon.new('Morning Star', 5, 2) {
			# Spend a token after rolling, re-roll all dice.
		#}

		Weapon.new('Sack of Loot', 3, 0) {
			hooks(:bonus_damage) { |player,encounter| player.treasure }
			hooks(:at_start) { |player| player.treasure += 1 }
		}

		# Weapon.new('Scimitar', 4, 2) { # weapon token: after rolling, reroll 2 dice

		# Weapon.new('Spear', 0, 0) { # use 14 instead of your roll

		Weapon.new('Spiked Shield', 3, 2) {
			hooks(:at_start) { |player| player.bonus_defense += 1 }
			hooks(:before_rolling) { |player,encounter| encounter.attack >= player.defense && player.spend_weapon_token && player.kill } # condition not quite right
			# Spend a token after rolling, to Kill a Monster that Damaged you.
		}

		# Weapon.new('Staff', 3, 4) { # Spend a token before rolling, either +2 Attack Dice or +6 Defense this turn..

		Weapon.new('Throwing Stars', 2, 20) { 
			hooks(:before_rolling) { |player,encounter| 
				n = player.decide(:use_throwing_stars)
				player.spend_weapon_token(n) && player.gain_temp_dice(n)
			}
		}

		# Weapon.new('Wand', 0, 0)

		Weapon.new('Whip', 4, 2) {
			hooks(:after_attack) { |player,encounter| !player.has?(:killed_this_round) && player.spend_weapon_token && player.dodge }
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