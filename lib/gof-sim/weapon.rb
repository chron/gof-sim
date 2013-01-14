module GauntletOfFools
	class Weapon < Deck
		attr_reader :name, :dice
		# proc hooks
		attr_reader :bonus_damage, :at_start, :damage_calc
		
		def initialize name
			@name = name
			@dice = 4
			@tokens = 2
		end

		def to_s
			name
		end

		def on_attach(hero)
			# do nothing
		end

		#dagger {
		#	dice 3
		#	tokens 0
		#}

		spear {
			dice 4
		}

		bag_of_gold {
			dice 3
			bonus_damage { |player,encounter| player.treasure }
			at_start { |player| player.treasure += 1 }
		}

		cleaver {
			dice 1
			damage_calc { |rolls,bonuses| rolls.inject(0) { |total,d| total + (d * 4) } + bonuses }
		}
		# dagger, longsword, holy sword, deadly fists, mace, shuriken, spear, bag of gold, cleaver (promo)
	end
end