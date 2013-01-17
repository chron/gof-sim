module GauntletOfFools
	BRAGS = [:blindfold, :hangover, :one_leg, :one_arm, :no_breakfast, :juggling].freeze
	
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

		def initialize name, hero, weapon, brags
			@name = name
			@wounds, @treasure = 0, 0
			@brags = []
			@hero = hero
			@weapon = weapon

			@hangover = false
			@bonus_attack, @bonus_dice, @bonus_defense = 0, 0, 0
			@hero_tokens, @weapon_tokens = hero.tokens, weapon.tokens

			@kill_next, @dodge_next = false, false
			@encounter_mods = []

			brags.each { |b| add_brag(b) } # FIXME: probably do this inline

			at_start
		end

		def kill
			@kill_next = true
		end

		def dodge
			@dodge_next = true
		end

		def spend_weapon_token
			@weapon_tokens -= 1 if @weapon_tokens > 0
		end

		def spend_hero_token
			@hero_tokens -= 1 if @hero_tokens > 0
		end

		def gain_treasure amount
			@treasure += amount
			Logger.log ("#{name} has #{amount > 0 ? 'gained' : 'lost'} #{amount} coin#{amount == 1 ? '' : 's'}.")
		end

		def wound amount
			Logger.log ("#{name} recieves #{amount} wound#{amount == 1 ? '' : 's'}.")
		end

		def heal amount
			actual_heal = [amount, wounds].min
			@wounds -= actual_heal

			Logger.log "%s is cured of %i wound%s" % [self.name, actual_heal, actual_heal == 1 ? '' : 's'] if actual_heal > 0
		end

		Deck::REPLACEMENT_HOOKS.each do |hook|
			define_method(hook) do |*args|
				[@hero,@weapon].each do |obj| 
					proc = obj.send(hook)
					if proc && r=proc[self, *args]
						return r
					end
				end

				return false
			end
		end

		Deck::HOOKS.each do |hook|
			define_method(hook) do |*args|
				[@hero,@weapon].map do |obj| 
					proc = obj.send(hook)
					proc[self, *args] if proc
				end.compact # can't tell where it's from?
			end
		end

		def add_brag brag
			raise "Unknown Brag" unless BRAGS.include?(brag)
			raise "Duplicate Brag" if @brags.include?(brag)

			case brag
				when :no_breakfast then @wounds += 1
				when :juggling then @bonus_attack -= 1; @weapon_tokens /= 2
				when :one_leg then @bonus_defense -= 2
				when :hangover then @bonus_dice -= 1; @bonus_defense -= 2; @hangover = true # check ??
			end

			@brags << brag
		end

		def dead?
			@wounds >= 4
		end

		def defense
			@hero.defense + @bonus_defense
		end

		def attack_dice
			@weapon.dice + @bonus_dice
		end

		def fight encounter
			if encounter.instead_of_combat
				encounter.instead_of_combat[self]
				@encounter_mods.clear # check this
				after_encounter
			elsif encounter.modifies_next_encounter
				@encounter_mods << encounter.modifies_next_encounter
			else
				if @encounter_mods.size > 0
					encounter = encounter.dup
					@encounter_mods.each { |m| m[encounter] }
					@encounter_mods.clear
				end

				before_encounter(encounter)

				if @kill_next
					Logger.log "%s kills %s." % [@name, encounter.name]
					killed = true
					@kill_next = false
				else 
					dice_result = roll(attack_dice)
					modified_dice_result = dice_result.reject { |d| @brags.include?(:one_arm) && d <= 2 }

					total_bonus = @bonus_attack + bonus_damage.sum

					total_attack = @weapon.damage_calc ? @weapon.damage_calc[modified_dice_result, total_bonus] : modified_dice_result.inject(0) {|s,c| s + c } + total_bonus

					Logger.log "%s attacks %s => %id6+%i = %p = %i" % [@name, encounter.name, attack_dice, total_bonus, dice_result, total_attack]
					killed = total_attack >= encounter.defense
				end

				if @dodge_next
					Logger.log "%s dodges." % [@name]
					encounter_hits = false
					@dodge_next = false
				else
					Logger.log "%s attacks for %i. %s defense is %i." % [encounter.name, encounter.attack, @name, defense]
					encounter_hits = encounter.attack >= defense
				end

				if killed
					Logger.log "%s has slain %s!" % [@name, encounter.name]

					if instead_of_treasure(encounter)
						Logger.log "%s uses a power instead of gaining treasure." % [@name] # FIXME
					else
						loot = encounter.treasure
						loot -= 1 if @brags.include?(:blindfold) && !encounter_hits
						loot = 0 if loot < 0

						gain_treasure loot
					end

					if @hangover
						@bonus_dice += 1
						@bonus_defense += 2
						@hangover = false

						Logger.log "%s has recovered from his hangover!" % [@name]
					end
				else
					Logger.log "%s does not defeat %s." % [@name, encounter.name]
				end

				if encounter_hits
					wound encounter.damage
				end

				after_encounter
			end
		end

		def roll number
			Array.new(number) { rand(6)+1 }
		end
	end
end