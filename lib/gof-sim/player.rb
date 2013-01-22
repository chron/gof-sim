module GauntletOfFools
	BRAGS = [:blindfold, :hangover, :one_leg, :one_arm, :no_breakfast, :juggling].freeze
	PERMANENT_EFFECTS = [:poison, :hangover].freeze

	class Option < Struct.new(:hero, :weapon, :current_owner, :brags)
		def inspect
			"%s/%s+%p%s" % [hero.name, weapon.name, brags, current_owner ? " (#{current_owner})" : '']
		end

		def is_assigned?
			current_owner
		end

		def to_player
			Player.new(current_owner, hero, weapon, brags)
		end
	end

	class Player
		attr_reader :name, :hero, :weapon, :brags
		attr_accessor :wounds, :treasure, :bonus_attack, :bonus_dice, :bonus_defense, :hero_tokens, :weapon_tokens
		attr_accessor :kill_next, :dodge_next, :temp_dice

		def initialize name, hero, weapon, brags
			@name = name
			@wounds, @treasure = 0, 0
			@brags = []
			@hero = hero
			@weapon = weapon

			@temp_dice = 0

			@bonus_attack, @bonus_dice, @bonus_defense = 0, 0, 0
			@hero_tokens, @weapon_tokens = hero.tokens, weapon.tokens

			@kill_next, @dodge_next = false, false
			@encounter_mods = []

			@current_effects, @next_turn_effects = [], []

			brags.each { |b| add_brag(b) } # FIXME: probably do this inline
		end

		def next_turn flag
			Logger.log '%s gains an effect: %s' % [@name, flag]
			@next_turn_effects << flag
		end

		def begin_turn
			@temp_dice = 0
			@current_effects.delete_if { |e| !PERMANENT_EFFECTS.include?(e) }
			@current_effects.concat(@next_turn_effects)
			@next_turn_effects.clear
		end

		def effects
			@current_effects
		end

		def gain effect
			@current_effects << effect
		end

		def has? effect
			@current_effects.include?(effect)
		end

		def clear_effect effect
			@current_effects.delete_if { |e| effect == e }
		end

		def end_turn

		end

		def kill
			Logger.log '%s will auto-kill.' % @name
			@kill_next = true
		end

		def dodge
			Logger.log '%s will dodge the next attack.' % @name
			@dodge_next = true
		end

		def gain_temp_dice n
			Logger.log '%s gains %i dice for the next roll.' % [@name, n]
			@temp_dice += n
		end

		def spend_weapon_token
			if @weapon_tokens > 0
				@weapon_tokens -= 1
				Logger.log '%s spends a weapon token (%i remaining).' % [@name, @weapon_tokens]
				true
			end
		end

		def spend_hero_token
			if @hero_tokens > 0
				@hero_tokens -= 1
				Logger.log '%s spends a hero token (%i remaining).' % [@name, @hero_tokens]
				true
			end
		end

		def gain_treasure amount
			@treasure += amount
			Logger.log ("#{name} has #{amount > 0 ? 'gained' : 'lost'} #{amount.abs} coin#{amount == 1 ? '' : 's'}.")
		end

		def wound amount
			@wounds += amount
			Logger.log ("#{name} recieves #{amount} wound#{amount == 1 ? '' : 's'}.")
		end

		def heal amount
			actual_heal = [amount, wounds].min
			@wounds -= actual_heal

			Logger.log "%s is cured of %i wound%s" % [self.name, actual_heal, actual_heal == 1 ? '' : 's'] if actual_heal > 0
		end

		def add_brag brag
			raise "Unknown Brag" unless BRAGS.include?(brag)
			raise "Duplicate Brag" if @brags.include?(brag)

			case brag
				when :no_breakfast then @wounds += 1
				when :juggling then @bonus_attack -= 1; @weapon_tokens /= 2
				when :one_leg then @bonus_defense -= 2
				when :hangover then @bonus_dice -= 1; @bonus_defense -= 2; @current_effects << :hangover
			end

			@brags << brag
		end

		def dead?
			@wounds >= 4 && !has?(:cannot_die)
		end

		def defense
			@hero.defense + @bonus_defense
		end

		def attack_dice
			@weapon.dice + @bonus_dice + @temp_dice
		end

		def roll number
			return [] if number <= 0
			Array.new(number) { rand(6)+1 }
		end

		def minimum_damage
			attack_dice + bonus_damage # doesn't include damage hooks
		end

		def maximum_damage
			6 * attack_dice + bonus_damage
		end

		def average_damage
			3.5 * attack_dice + bonus_damage
		end
	end
end