module GauntletOfFools
	class Hero < Deck
		attr_reader :name, :wounds, :treasure, :defense, :tokens

		def initialize name
			@name = name
			@defense = 13
			@tokens = 0
		end

		def to_s
			name
		end

		barbarian {
			defense 18
		}

		monk {
			defense 14
			tokens 4
			before_combat { |player,encounter| spend_1_token && player.dodge }

			unfinished!
		}

		warlord {
			defense 10
			at_start { |player| player.bonus_dice += 1 } # + active

			unfinished!
		}

		armorer {
			defense 10
			instead_of_treasure { |player,treasure| player.spend_hero_token && player.bonus_defense += 3 }
		}

		zealot {
			tokens 2
			defense 15
			#Spend a token before rolling. Kill a Monster, and your Defense is 0 this turn.

			unfinished!
		}

		prospector {
			defense 15
			after_encounter { |player,encounter| player.treasure += 1 if !player.dead?}
		}

		priest {
			defense 14
			tokens 2
			# At the start of an Encounter, heal 1 wound. You don't attack and can't use Weapon Ability Tokens this turn.

			unfinished!
		}

		wizard {
			defense 15
			tokens 2
			#  Spend a token before rolling, skip an Encounter completely, ignoring its text.

			unfinished!
		}

		trapper {
			defense 16
			tokens 2
			instead_of_treasure { |player, encounter| spend_hero_token && player.gain_treasure(encounter.treasure+2) } # FIXME: token spend before rolling?
			# Spend a token before rolling, once per fight, Treasures have an extra 2 Gold for you this turn.
		}

		ninja {
			defense 17
			at_start { |player| player.weapon_tokens *= 2 }
		}

		knight {
			defense 16
			tokens 2
			# hero token: prevent all but 1 wound damage from a monster

			unfinished!
		}

		# artificer, armsmaster(promo), thief, jester

		# Zombie?
		# Defense 13
		# Starting Class Ability Tokens: 2
		# Class Ability: Spend a token if another player is alive to play a turn even though you are dead.
	end
end