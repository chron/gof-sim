module GauntletOfFools
	class Brag < GameObject

	end

	Brag.new('With a Hangover') {
		hooks(:at_start) { |player| player.gain_token(:hangover) }
		hooks(:defense) { |player, encounter, defense| (player.tokens(:hangover) > 0 && !player.has?(:ignore_brags)) ? defense - 2 : defense }
		hooks(:attack_dice) { |player, encounter, dice| (player.tokens(:hangover) > 0 && !player.has?(:ignore_brags)) ? dice - 1 : dice }

		hooks(:extra_treasure) { |player, encounter| 
			if player.tokens(:hangover) > 0 && !player.has?(:ignore_brags)
				player.gain_token(:hangover, -1)
				# Logger.log "%s has recovered from his hangover!" % player.name
			end
		}
	}

	Brag.new('Without Breakfast') {
		hooks(:at_start) { |player| player.wound(1) }
	}

	Brag.new('With One Arm Tied') { # FIXME: at what point are these removed, eg can they be rerolled?
		hooks(:after_rolling) { |player, encounter| !player.has?(:ignore_brags) && player.current_rolls.delete_if { |r| r <= 2 }}
	}

	Brag.new('Hopping On One Leg') {
		hooks(:defense) { |player, encounter, defense| !player.has?(:ignore_brags) && defense - 2 }
	}

	Brag.new('While Juggling') {
		hooks(:at_start) { |player| player.gain_weapon_token(-player.weapon_tokens / 2) } # FIXME: applies to ALL weapons
		hooks(:bonus_attack) { |player, encounter, attack| !player.has?(:ignore_brags) && attack - 1 }
	}

	Brag.new('Blindfolded') {
		hooks(:at_start) { |player| player.gain_token(:blindfolded) } # FIXME: fix interactions with extra_treasure hooks
	}
end
