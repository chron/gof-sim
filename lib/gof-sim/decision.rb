module GauntletOfFools
	class Decision < GameObject
		def relevant_to player
			!hooks?(:prereqs) || call_hook(:prereqs, player)
		end

		def apply_to player
			call_hook(:apply, player) if relevant_to(player)
		end

		def decline_to player
			call_hook(:decline, player)
		end

		def repeatable!
			@repeatable = true
		end

		def repeatable?
			@repeatable
		end

		def requires_weapon_token
			hooks(:prereqs) { |player| player.weapon_tokens(@owner) >= 1 }
		end

		def requires_hero_token
			hooks(:prereqs) { |player| player.tokens(:hero_token) >= 1 }
		end

		def from owner
			@owner = owner.name
			self
		end
	end

	Decision.new('Use Axe') {
		requires_weapon_token
		hooks(:apply) { |player| player.spend_weapon_token(@owner) && player.gain(:double_attack) && player.next_turn(:zero_attack) }
	}

	Decision.new('Use Armorer') {
		requires_hero_token
		hooks(:apply) { |player| player.spend_hero_token && player.gain_token(:defense, 3) && player.gain(:no_treasure) }
	}

	Decision.new('Use One-use Die') {
		repeatable!
		hooks(:prereqs) { |player| player.tokens(:one_use_die) >= 1 }
		hooks(:apply) { |player| player.spend_token(:one_use_die) && player.gain_token(:temp_dice) }
	}

	Decision.new('Use Flaming Sword') {
		hooks(:prereqs) { |player| player.weapon_tokens('Flaming Sword') >= 1 }
		hooks(:apply) { |player| player.spend_weapon_token('Flaming Sword') && player.wound && player.gain(:kill_next, :dodge_next) }
	}
end