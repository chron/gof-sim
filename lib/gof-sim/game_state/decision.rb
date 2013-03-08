module GauntletOfFools	
	class Decision < GameObject
		attr_reader :owner

		def initialize name, owner=nil
			super(name)

			@owner = owner
			@validator = nil
		end

		def validator for_player
			hooks?(:validate) ? call_hook(:validate, for_player).first : @validator
		end

		def possible_choices for_player
			if validator(for_player).nil?
				[true, false]
			elsif validator(for_player).respond_to?(:to_a)
				validator(for_player).to_a
			else
				raise "don't know how to validate"
			end
		end

		def limit_values_to v=nil, &b
			if v && !b
				@validator = v
			elsif b && !v
				hooks(:validate, &b)
			else
				raise 'specify either block or value, but not both'
			end
		end

		def validate for_player, value
			validator(for_player).nil? || validator(for_player).include?(value)
		end

		def relevant_to player
			!hooks?(:prereqs) || call_hook(:prereqs, player).all?
		end

		def make player, choice
			choice ? apply_to(player, choice) : decline_to(player)
			call_hook(:after, player)
			# Return a boolean indicating if the decision can be made again
			repeatable? && choice
		end

		def apply_to player, v=nil
			raise 'Invalid' if !validate(player, v)
			call_hook(:apply, player, v) if relevant_to(player)
		end

		def only_if &b
			hooks(:prereqs, &b)
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

		def has_weapon_token
			hooks(:prereqs) { |player| !player.has?(:no_weapon_tokens) && player.weapon_tokens(@owner) >= 1 }
		end

		def has_hero_token
			hooks(:prereqs) { |player| !player.has?(:no_hero_tokens) && player.tokens(:hero_token) >= 1 }
		end

		def spend_weapon_token_to &b
			has_weapon_token
			hooks(:apply) { |player| player.spend_weapon_token(@owner) }
			hooks(:apply, &b)
		end

		def spend_n_weapon_tokens_to &b
			has_weapon_token
			hooks(:validate) { |player| 0..player.weapon_tokens(@owner) }
			hooks(:apply) { |player, value| player.spend_weapon_token(value, @owner) }
			hooks(:apply, &b)
		end

		def spend_hero_token_to &b
			has_hero_token
			hooks(:apply) { |player| player.spend_token(:hero_token) }
			hooks(:apply, &b)
		end

		def spend_n_hero_tokens_to &b
			has_hero_token
			hooks(:validate) { |player| 0..player.tokens(:hero_token) }
			hooks(:apply) { |player, value| player.spend_token(:hero_token, value) }
			hooks(:apply, &b)
		end

		# FIXME: consider more helper objects like this to clean up definitions
		#def get number_of, token_type
		#	lambda { |player| player.gain_token(token_type, number_of) }
		#end
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