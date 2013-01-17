module GauntletOfFools
	class Weapon < Deck
		attr_reader :name, :dice, :tokens
		attr_reader :bonus_damage, :damage_calc
		
		def initialize name
			@name = name
			@dice = 4
			@tokens = 0
		end

		def to_s
			name
		end

		def on_attach(hero)
			# do nothing
		end

		mace {
			dice 5
			# Spend a token after rolling, roll an extra Attack Dice.

			unfinished!
		}

		sack_of_loot {
			dice 3
			bonus_damage { |player,encounter| player.treasure }
			at_start { |player| player.treasure += 1 }
		}

		cleaver { # PROMO CARD
			dice 1
			damage_calc { |rolls,bonuses| rolls.inject(0) { |total,d| total + (d * 4) } + bonuses }
		}
		
		deadly_fists {
			dice 3
			tokens 2
			before_encounter { |player,encounter| player.spend_weapon_token && player.kill && player.dodge }
		}

		spiked_shield {
			dice 3
			tokens 2
			at_start { |player| player.bonus_defense += 1 }
			before_encounter { |player,encounter| encounter.attack >= player.defense && spend_weapon_token && player.kill } # condition not quite right
			# Spend a token after rolling, to Kill a Monster that Damaged you.
		}

		staff {
			dice 3
			tokens 4
			# Spend a token before rolling, either +2 Attack Dice or +6 Defense this turn..

			unfinished!
		}

		holy_sword {
			dice 5
			tokens 2
			# Spend a token before rolling, discard all Penalty tokens, and ignore your Boasts this turn.

			unfinished!
		}

		morning_star {
			dice 5
			tokens 2
			# Spend a token after rolling, re-roll all dice.

			unfinished!
		}

		bow {
			dice 4
			tokens 2
			#after_attack { |player,encounter| killed? player.spend_weapon_token && player.dodge }

			unfinished!
		}

		axe {
			dice 5
			tokens 2
			#Spend a token to once per fight, before rolling double your attack value, but zero it our for the following turn.

			unfinished!
		}

		dagger {
			dice 3
			tokens 4
			before_encounter { |player,encounter| player.spend_weapon_token && player.kill }
		}

		whip {
			dice 4
			tokens 2
			#Spend a token to Dodge a Monster that you didn't Kill.

			unfinished!
		}

		scimitar {
			dice 4
			tokens 2
			# weapon token: after rolling, reroll 2 dice

			unfinished!
		}

		# wand, longsword, shuriken, spear, flaming sword, scimitar
	end
end