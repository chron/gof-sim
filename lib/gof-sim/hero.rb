module GauntletOfFools
	class Hero < GameObject
		attr_reader :defense, :tokens, :number_of_weapons

		def initialize name, defense, tokens
			@number_of_weapons = 1
			@defense, @tokens = defense, tokens

			super(name)
		end

		Hero.new('Adventurer', 15, 2) {
			hooks(:after_encounter) { |player, encounter| !player.has?(:second_adventure) && player.decide(:use_adventurer) && player.spend_hero_token && player.gain(:second_adventure) && player.queue_fight(encounter)}
		}

		Hero.new('Alchemist', 14, 2) {
			hooks(:end_of_turn) { |player, encounter| player.has?(:killed_this_round) && player.has?(:dodged_this_round) && player.wounds > 0 && player.decide(:use_alchemist) && player.spend_hero_token && player.heal(1) }
		}

		Hero.new('Armorer', 13, 2) {
			hooks(:instead_of_treasure) { |player| player.decide(:use_armorer) && player.spend_hero_token && player.gain_token(:defense, 3) }
		}

		Hero.new('Armsmaster', 14, 0) { # PROMO CARD
			@number_of_weapons = 2
		} 

		Hero.new('Artificer', 15, 2) {
			hooks(:instead_of_treasure) { |player| player.decide(:use_artificer) && player.spend_hero_token && player.gain_token(:dice, 1) }
		}

		Hero.new('Avenger', 16, 2) {
			hooks(:end_of_turn) { |player| player.opponents.count { |p| p.dead? }.times { player.next_turn(:fallen_comrade) }} # has to have died on previous turns
			hooks(:after_rolling) { |player, encounter, rolls|
				n = player.number_of(:fallen_comrade) # CHECK: is this once per turn?
				player.decide(:use_avenger, rolls, n) && player.spend_hero_token && player.gain_token(:temp_attack,3*n) && rolls
			}
		}

		Hero.new('Barbarian', 18, 0)

		Hero.new('Berserker', 14, 2) {
			hooks(:before_rolling) { |player, encounter| player.decide(:use_berserker) && player.spend_hero_token && player.gain_token(:temp_dice, player.wounds) && player.gain(:berserk) }
			hooks(:after_attack) { |player, encounter| player.has?(:berserk) && player.has?(:killed_this_round) && player.gain(:dodge_next) }
		}

		Hero.new('Jester', 14, 2)  { # FIXME: would be nice to do this without mutating the encounter itself
			hooks(:before_rolling) { |player, encounter| @swapped = player.decide(:use_jester) && player.spend_hero_token && encounter.swap_attack_and_defense }
			hooks(:after_encounter) { |player, encounter| encounter.swap_attack_and_defense if @swapped } # swap back after jester's turn
		}

		Hero.new('Knight', 16, 2) {
			hooks(:instead_of_damage) { |player, encounter| player.decide(:use_knight) && player.spend_hero_token && player.wound(1) } # CHECK: case of zero wounds?
		}

		Hero.new('Monk', 10, 4) { # FIXME: before_damage??? what hook is this supposed to be
			hooks(:before_rolling) { |player, encounter| 
				n = player.decide(:use_monk)
				player.spend_hero_token(n) && player.gain_token(:temp_dice, n) && player.gain_token(:temp_defense, 4*n) 
			}
		}

		# CHECK: does this include passives?
		Hero.new('Necromancer', 16, 2) { # FIXME: check interaction with zombie + prospector
			# CHECK: zombies using their power? zombies that have become alive again?
			hooks(:end_of_turn) { |player| player.opponents.each { |p| p.dead? && !player.delegates.include?(p.hero) && p.delegates << p.hero }} # has to have died on previous turns
		}

		Hero.new('Ninja', 17, 0) {
			hooks(:at_start) { |player| player.gain_weapon_token(player.weapon_tokens) }
		}

		Hero.new('Priest', 14, 2) { # FIXME: zero attack = don't attack?
			hooks(:before_rolling) { |player| player.wounds > 0 && player.decide(:use_priest) && player.spend_hero_token && player.heal(1) && player.gain(:zero_attack, :no_weapon_tokens)}
		}

		Hero.new('Prospector', 15, 0) {
			hooks(:after_encounter) { |player,encounter| !player.dead? && player.gain_treasure(1) }
		}

		Hero.new('Thief', 13, 2) {
			hooks(:before_rolling) { |player, encounter| player.decide(:use_thief_for_trap) && player.spend_hero_token && player.gain(:dodge_next_trap) }
			hooks(:after_attack) { |player, encounter| player.decide(:use_thief) && player.spend_hero_token && player.gain(:dodge_next) }
		}

		Hero.new('Trapper', 16, 2) {
			hooks(:before_rolling) { |player, encounter| !player.has?(:trapper_bounty) && player.decide(:use_trapper) && player.spend_hero_token && player.gain(:trapper_bounty) }
			hooks(:extra_treasure) { |player, encounter| player.has?(:trapper_bounty) && player.gain_treasure(2) } # FIXME: once per fight, lasts whole turn: multiples?
		}

		Hero.new('Warlord', 12, 2) {
			hooks(:attack_dice) { |player, encounter, dice| dice + 1 }
			hooks(:after_rolling) { |player, encounter, rolls| # FIXME: one by one? check mace etc too
				n = player.decide(:use_warlord, rolls)
				player.spend_hero_token(n) && (rolls + player.roll(n))
			}
		}

		Hero.new('Wizard', 15, 2) { # NB: should be able to skip demons
			hooks(:before_rolling) { |player, encounter| player.decide(:use_wizard) && player.spend_hero_token && player.gain(:skip_encounter) }
		}

		Hero.new('Zealot', 15, 2) { # zeroes defense but you can still raise it after, unlike zero_attack
			hooks(:before_rolling) { |player, encounter| player.decide(:use_zealot) && player.spend_hero_token && player.gain(:kill_next) && player.gain(:zero_defense)}
		}

		Hero.new('Zombie', 13, 2) {
			hooks(:start_of_turn) { |player, encounter| player.dead? && player.decide(:use_zombie) && player.spend_hero_token && player.gain(:cannot_die) }
		}
	end
end