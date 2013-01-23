module GauntletOfFools
	class Hero < GameObject
		attr_reader :defense, :tokens
		def initialize name, defense, tokens
			super(name)

			@defense, @tokens = defense, tokens
		end

		#Hero.new('adventurer', 0, 0)

		Hero.new('Alchemist', 14, 2) {
			hooks(:after_encounter) { |player, encounter| player.has?(:killed_this_round) && player.has?(:dodged_this_round) && player.wounds > 0 && player.spend_hero_token && player.heal(1) }
		}

		#Hero.new('Armorer', 10, 2) {
		#	hooks(:instead_of_treasure) { |player| player.spend_hero_token && player.bonus_defense += 3 }
		#}

		#Hero.new('Artificer', 14, 2) { # check defense
		#	hooks(:instead_of_treasure) { |player| player.spend_hero_token && player.bonus_dice += 1 }
		#}

		#Hero.new('avenger', 0, 0)

		Hero.new('Barbarian', 18, 0)

		#Hero.new('berserker', 0, 0)

		#Hero.new('jester', 0, 0) 

		Hero.new('Knight', 16, 2) {
			hooks(:instead_of_damage) { |player,encounter| player.decide(:use_knight) && player.spend_hero_token && player.wound(1) } # case of zero wounds?
		}

		# Hero.new('monk', 14, 4)

		# Hero.new('necromancer', 0, 0)

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
			# Spend a token before rolling, once per fight, Treasures have an extra 2 Gold for you this turn.
		}


		#Hero.new('warlord', 10, 0) { # FIXME: tokens
		#	at_start { |player| player.bonus_dice += 1 } # + active
		#
		#	unfinished!
		#}

		# Hero.new('wizard', 15, 2) {
		#	#  Spend a token before rolling, skip an Encounter completely, ignoring its text.
		#}

		#Hero.new('zealot', 15, 2) {
		#	#Spend a token before rolling. Kill a Monster, and your Defense is 0 this turn.
		#}

		#Hero.new('zombie', 13, 2) {
		#	# Class Ability: Spend a token if another player is alive to play a turn even though you are dead.
		#}

		# Hero.new('armsmaster', 0, 0)
	end
end