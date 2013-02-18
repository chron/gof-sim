module GauntletOfFools
	class Decision < GameObject
		attr_reader :owner

		def initialize name, owner=nil
			super(name)

			@owner = owner
			@validator = nil
		end

		def limit_values_to v=nil, &b
			raise 'supplier block and value for valdiator' if v && b
			@validator = v || b
		end

		def relevant_to player
			!hooks?(:prereqs) || call_hook(:prereqs, player)
		end

		def make player, choice
			choice ? apply_to(player, choice) : decline_to(player)
			call_hook(:after, player)
			# Return a boolean indicating if the decision can be made again
			repeatable? && choice
		end

		def apply_to player, v=nil
			raise 'Invalid' if !validate(v)
			call_hook(:apply, player, v) if relevant_to(player)
		end

		def validate value
			@validator.nil? || (@validator.respond_to?(:call) ? @validator.call(value) : @validator.include?(value))
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
	end

	Decision.new('Visit Encounter') {
		hooks(:prereqs) { |player| player.has?(:optional_encounter) }
		hooks(:decline) { |player| player.gain(:skip_encounter) }
		hooks(:after) { |player| player.clear_effect(:optional_encounter) }
	}

	Decision.new('Use One-use Die') {
		repeatable!
		hooks(:prereqs) { |player| player.tokens(:one_use_die) >= 1 }
		hooks(:apply) { |player| player.spend_token(:one_use_die) && player.gain_token(:temp_dice) }
	}
end