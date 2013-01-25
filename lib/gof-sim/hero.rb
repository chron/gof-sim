module GauntletOfFools
	class Hero < GameObject
		attr_reader :defense, :tokens, :number_of_weapons

		def initialize name, defense, tokens
			@number_of_weapons = 1
			@defense, @tokens = defense, tokens

			super(name)
		end

		#Hero.new('adventurer', 0, 0)

		Hero.new('Alchemist', 14, 2) {
			hooks(:after_encounter) { |player, encounter| player.has?(:killed_this_round) && player.has?(:dodged_this_round) && player.wounds > 0 && player.spend_hero_token && player.heal(1) }
		}

		Hero.new('Armorer', 13, 2) {
			hooks(:instead_of_treasure) { |player| player.spend_hero_token && player.gain_bonus(:defense, 3) }
		}

		Hero.new('Artificer', 14, 2) { # check defense
			hooks(:instead_of_treasure) { |player| player.spend_hero_token && player.gain_bonus(:dice, 1) }
		}

		#Hero.new('avenger', 0, 0)

		Hero.new('Barbarian', 18, 0)

		#Hero.new('berserker', 0, 0)

		#Hero.new('jester', 0, 0) 

		Hero.new('Knight', 16, 2) {
			hooks(:instead_of_damage) { |player,encounter| player.decide(:use_knight) && player.spend_hero_token && player.wound(1) } # case of zero wounds?
		}

		# Hero.new('monk', 14, 4)

		# Hero.new('Necromancer', 16, 2)
			# Has all abilities of heroes killed on previous turns

		Hero.new('Ninja', 17, 0) {
			hooks(:at_start) { |player| player.weapon_tokens *= 2 }
		}

		Hero.new('Priest', 14, 2) {
			hooks(:before_encounter) { |player| player.wounds > 0 && player.decide(:use_priest) && player.spend_hero_token && player.heal(1) && player.gain(:zero_attack) && player.gain(:no_weapon_tokens)}
		}

		Hero.new('Prospector', 15, 0) {
			hooks(:after_encounter) { |player,encounter| player.gain_treasure(1) if !player.dead?}
		}

		#Hero.new('thief', 0, 0) {
		#	before_combat { |player,encounter| player.spend_1_token && player.dodge }
#
		#	unfinished!
		#}

		Hero.new('Trapper', 16, 2) {
			hooks(:before_rolling) { |player, encounter| player.decide(:use_trapper) && player.spend_hero_token && player.gain(:trapper_bounty) } # use once per fight but lasts whole turn
			hooks(:extra_treasure) { |player, encounter| player.has?(:trapper_bounty) && player.gain_treasure(2) }
		}


		#Hero.new('warlord', 10, 0) { # FIXME: tokens
		#	at_start { |player| player.bonus_dice += 1 } # + active
		#
		#	unfinished!
		#}

		Hero.new('Wizard', 15, 2) {
			hooks(:before_encounter) { |player, encounter| player.decide(:use_wizard) && player.spend_hero_token && player.gain(:skip_encounter) }
		}

		Hero.new('Zealot', 15, 2) { # zeroes defense but you can still raise it?
			hooks(:before_rolling) { |player, encounter| player.decide(:use_zealot) && player.spend_hero_token && player.gain(:kill_next) && player.gain(:zero_defense)}
		}

		#Hero.new('zombie', 13, 2) {
		#	# Class Ability: Spend a token if another player is alive to play a turn even though you are dead.
		#}

		Hero.new('Armsmaster', 14, 0) {
			@number_of_weapons = 2
		} # FIXME: hook for this maybe?
	end
end