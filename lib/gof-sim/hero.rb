module GauntletOfFools
	class Hero < GameObject
		attr_reader :defense, :tokens, :number_of_weapons

		def initialize name, defense, tokens
			@number_of_weapons = 1
			@defense, @tokens = defense, tokens

			super(name)
		end

		Hero.new('Adventurer', 15, 2)
			# token -> after an encounter, once per encounbter, visit that encounter again

		Hero.new('Alchemist', 14, 2) { # FIXME: need AI hook for this?
			hooks(:after_encounter) { |player, encounter| player.has?(:killed_this_round) && player.has?(:dodged_this_round) && player.wounds > 0 && player.spend_hero_token && player.heal(1) }
		}

		Hero.new('Armorer', 13, 2) { # FIXME: AI hook
			hooks(:instead_of_treasure) { |player| player.spend_hero_token && player.gain_bonus(:defense, 3) }
		}

		Hero.new('Artificer', 15, 2) { # FIXME: AI hook
			hooks(:instead_of_treasure) { |player| player.spend_hero_token && player.gain_bonus(:dice, 1) }
		}

		Hero.new('Avenger', 16, 2) {
			hooks(:after_rolling) { |player, encounter, rolls|
				n = player.opponents.count { |p| p.dead? } # FIXME: dead on PREVIOUS turns
				player.decide(:use_avenger, rolls) && player.gain_temp(:attack,3*n)
			}
		}

		Hero.new('Barbarian', 18, 0)

		Hero.new('Berserker', 14, 2) {
			hooks(:before_rolling) { |player, encounter| player.decide(:use_berserker) && player.spend_hero_token && player.gain_temp(:dice, player.wounds) && player.gain(:berserk) }
			hooks(:after_attack) { |player, encounter| player.has?(:berserk) && player.has?(:killed_this_round) && player.gain(:dodge_next) }
		}

		#Hero.new('Jester', 14, 2) 
			# token -> before rolling, switch monster's attack and defense

		Hero.new('Knight', 16, 2) {
			hooks(:instead_of_damage) { |player, encounter| player.decide(:use_knight) && player.spend_hero_token && player.wound(1) } # case of zero wounds?
		}

		Hero.new('Monk', 10, 4) {
			hooks(:before_damage) { |player, encounter| player.decide(:use_monk) && player.spend_hero_token && player.gain_temp(:dice) && player.gain_temp(:defense, 4) }
		}

		Hero.new('Necromancer', 16, 2)
			# Has all abilities of heroes killed on previous turns (includes passives?)

		Hero.new('Ninja', 17, 0) {
			hooks(:at_start) { |player| player.weapon_tokens *= 2 }
		}

		Hero.new('Priest', 14, 2) { # FIXME: zero attack = don't attack?
			hooks(:before_encounter) { |player| player.wounds > 0 && player.decide(:use_priest) && player.spend_hero_token && player.heal(1) && player.gain(:zero_attack) && player.gain(:no_weapon_tokens)}
		}

		Hero.new('Prospector', 15, 0) {
			hooks(:after_encounter) { |player,encounter| !player.dead? && player.gain_treasure(1)}
		}

		Hero.new('Thief', 13, 2) {
			# FIXME: dodge traps also
			hooks(:after_attack) { |player, encounter| player.decide(:use_thief) && player.spend_hero_token && player.gain(:dodge_next) }
		}

		Hero.new('Trapper', 16, 2) {
			hooks(:before_rolling) { |player, encounter| player.decide(:use_trapper) && player.spend_hero_token && player.gain(:trapper_bounty) } # use once per fight but lasts whole turn
			hooks(:extra_treasure) { |player, encounter| player.has?(:trapper_bounty) && player.gain_treasure(2) }
		}

		Hero.new('Warlord', 12, 2) {
			hooks(:attack_dice) { |player, encounter, dice| dice + 1 }
			hooks(:after_rolling) { |player, encounter, rolls| # FIXME: one by one? check mace etc too
				n = player.decide(:use_warlord, rolls)
				player.spend_hero_token(n) && (rolls + player.roll(n))
			}
		}

		Hero.new('Wizard', 15, 2) {
			hooks(:before_encounter) { |player, encounter| player.decide(:use_wizard) && player.spend_hero_token && player.gain(:skip_encounter) }
		}

		Hero.new('Zealot', 15, 2) { # zeroes defense but you can still raise it?
			hooks(:before_rolling) { |player, encounter| player.decide(:use_zealot) && player.spend_hero_token && player.gain(:kill_next) && player.gain(:zero_defense)}
		}

		#Hero.new('Zombie', 13, 2)
			# Class Ability: Spend a token if another player is alive to play a turn even though you are dead.

		Hero.new('Armsmaster', 14, 0) {
			@number_of_weapons = 2
		} # FIXME: hook for this maybe?
	end
end