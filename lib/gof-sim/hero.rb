module GauntletOfFools
	class Hero < Deck
		attr_reader :name

		def initialize name
			super()

			@name = name
			self[:defense] = 13
			self[:tokens] = 0
		end

		def to_s
			name
		end

		adventurer {
			unfinished!
		}

		alchemist {
			defense 14
			tokens 2
			after_encounter { |player, encounter| player.has?(:killed_this_round) && player.has?(:dodged_this_round) && player.wounds > 0 && player.spend_hero_token && player.heal(1) }
		}

		armorer {
			defense 10
			tokens 2
			instead_of_treasure { |player| player.spend_hero_token && player.bonus_defense += 3 }
		}

		artificer {
			defense 14 # check this
			tokens 2
			instead_of_treasure { |player| player.spend_hero_token && player.bonus_dice += 1 }
		}

		avenger {
			unfinished!
		}

		barbarian {
			defense 18
		}

		berserker {
			unfinished!
		}

		jester {
			unfinished!
		}

		knight {
			defense 16
			tokens 2
			# hero token: prevent all but 1 wound damage from a monster

			unfinished!
		}

		monk {
			defense 14
			tokens 4

			unfinished!
		}

		necromancer {
			unfinished!
		}

		ninja {
			defense 17
			at_start { |player| player.weapon_tokens *= 2 }
		}

		priest {
			defense 14
			tokens 2
			# At the start of an Encounter, heal 1 wound. You don't attack and can't use Weapon Ability Tokens this turn.

			unfinished!
		}

		prospector {
			defense 15
			after_encounter { |player,encounter| player.gain_treasure(1) if !player.dead?}
		}

		thief {
			before_combat { |player,encounter| player.spend_1_token && player.dodge }

			unfinished!
		}

		trapper {
			defense 16
			tokens 2
			extra_treasure { |player, encounter| player.spend_hero_token && player.gain_treasure(2) } # FIXME: token spend before rolling?
			# Spend a token before rolling, once per fight, Treasures have an extra 2 Gold for you this turn.
		}


		warlord {
			defense 10
			at_start { |player| player.bonus_dice += 1 } # + active

			unfinished!
		}

		wizard {
			defense 15
			tokens 2
			#  Spend a token before rolling, skip an Encounter completely, ignoring its text.

			unfinished!
		}

		zealot {
			defense 15
			tokens 2
			#Spend a token before rolling. Kill a Monster, and your Defense is 0 this turn.

			unfinished!
		}

		zombie {
			defense 13
			tokens 2
			# Class Ability: Spend a token if another player is alive to play a turn even though you are dead.

			unfinished!
		}

		armsmaster {
			# two weapons
			unfinished!
		}
	end
end