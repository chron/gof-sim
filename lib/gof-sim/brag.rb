module GauntletOfFools
	class Brag < GameObject

	end

	Brag.new('With a Hangover') {
		hooks(:at_start) { |player| player.bonus_dice -= 1; player.bonus_defense -= 2; player.gain :hangover }
	}

	Brag.new('Without Breakfast') {
		hooks(:at_start) { |player| player.wound(1) }
	}

	Brag.new('With One Arm Tied') { # FIXME: at what point are these removed, eg can they be rerolled?
		hooks(:after_rolling) { |player, encounter, rolls| rolls.reject { |r| r <= 2 }}
	}

	Brag.new('Hopping On One Leg') {
		hooks(:at_start) { |player| player.bonus_defense -= 2 }
	}

	Brag.new('While Juggling') {
		hooks(:at_start) { |player| player.bonus_attack -= 1; player.weapon_tokens /= 2 }
	}

	Brag.new('Blindfolded') {
		hooks(:at_start) { |player| player.gain :blindfolded}
	}
end
