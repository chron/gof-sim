module GauntletOfFools
	class Weapon < Deck
		attr_reader :name
		attr_reader :bonus_damage, :damage_calc
		
		def initialize name
			super()

			@name = name
			self[:dice] = 4
			self[:tokens] = 0
		end

		def to_s
			name
		end

		def on_attach(hero)
			# do nothing
		end

		axe {
			dice 5
			tokens 2
			#Spend a token to once per fight, before rolling double your attack value, but zero it our for the following turn.

			unfinished!
		}

		bow {
			dice 4
			tokens 2
			after_attack { |player,encounter| player.has? :killed_this_turn && player.spend_weapon_token && player.dodge }
		}

		dagger {
			dice 3
			tokens 4
			before_rolling { |player,encounter| player.spend_weapon_token && player.kill }
		}

		deadly_fists {
			dice 3
			tokens 2
			before_rolling { |player,encounter| player.spend_weapon_token && player.kill && player.dodge }
		}

		demonic_blade {
			dice 4
			tokens 2 # CHECK THIS
			before_rolling { |player,encounter| player.spend_weapon_token && player.gain_temp_dice(2) } # FIXME: multiples
		}

		flaming_sword {
			unfinished!
		}

		holy_sword {
			dice 5
			tokens 2
			# Spend a token before rolling, discard all Penalty tokens, and ignore your Boasts this turn.

			unfinished!
		}
		
		mace {
			dice 5
			# Spend a token after rolling, roll an extra Attack Dice.

			unfinished!
		}

		morning_star {
			dice 5
			tokens 2
			# Spend a token after rolling, re-roll all dice.

			unfinished!
		}

		sack_of_loot {
			dice 3
			bonus_damage { |player,encounter| player.treasure }
			at_start { |player| player.treasure += 1 }
		}

		scimitar {
			dice 4
			tokens 2
			# weapon token: after rolling, reroll 2 dice

			unfinished!
		}

		spear {
			# use 14 instead of your roll
			unfinished!
		}

		spiked_shield {
			dice 3
			tokens 2
			at_start { |player| player.bonus_defense += 1 }
			before_rolling { |player,encounter| encounter.attack >= player.defense && player.spend_weapon_token && player.kill } # condition not quite right
			# Spend a token after rolling, to Kill a Monster that Damaged you.
		}

		staff {
			dice 3
			tokens 4
			# Spend a token before rolling, either +2 Attack Dice or +6 Defense this turn..

			unfinished!
		}

		throwing_stars {
			dice 2
			tokens 20

			# tokens add 1 dice
			unfinished!
		}

		wand {
			unfinished!
		}

		whip {
			dice 4
			tokens 2
			after_attack { |player,encounter| !player.has?(:killed_this_turn) && player.spend_weapon_token && player.dodge }
		}

		cleaver { # PROMO CARD
			dice 1
			damage_calc { |rolls,bonuses| rolls.inject(0) { |total,d| total + (d * 4) } + bonuses }
		}
	end
end