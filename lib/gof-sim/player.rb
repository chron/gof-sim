module GauntletOfFools
	BRAGS = [:blindfold, :hangover, :one_leg, :one_arm, :no_breakfast, :juggling].freeze

	class Player
		attr_reader :name, :hero, :weapon, :brags
		attr_accessor :wounds, :treasure
		def initialize name, hero, weapon, brags
			@name = name
			@wounds, @treasure = 0, 0
			@brags = []
			@hero = hero
			@weapon = weapon

			@bonus_attack, @bonus_dice, @bonus_defense = 0, 0, 0

			brags.each { |b| add_brag(b) } # FIXME: probably do this inline
			@weapon.at_start[self] if @weapon.at_start
		end

		def add_brag brag
			raise "Unknown Brag" unless BRAGS.include?(brag)
			raise "Duplicate Brag" if @brags.include?(brag)

			case brag
				when :no_breakfast then @wounds += 1
				when :juggling then @bonus_attack -= 1 # half weapon tokens
				when :one_leg then @bonus_defense -= 2
			end

			@brags << brag
		end

		def heal amount
			actual_heal = [amount, wounds].min
			@wounds -= actual_heal


			puts "%s is cured of %i wound%s" % [self.name, actual_heal, actual_heal == 1 ? '' : 's'] if actual_heal > 0
		end

		def dead?
			@wounds >= 4
		end

		def fight encounter
			if encounter.instead_of_combat
				encounter.instead_of_combat[self]
			else
				total_dice = @weapon.dice + @bonus_dice
				dice_result = roll(total_dice)
				modified_dice_result = dice_result.reject { |d| @brags.include?(:one_arm) && d <= 2 }

				total_bonus = @bonus_attack + (@weapon.bonus_damage ? @weapon.bonus_damage[self, encounter] : 0)

				total_attack = @weapon.damage_calc ? @weapon.damage_calc[modified_dice_result, total_bonus] : modified_dice_result.inject {|s,c| s + c } + total_bonus

				puts "%s attacks %s => %id6+%i = %p = %i" % [@name, encounter.name, total_dice, total_bonus, dice_result, total_attack]

				total_defense = hero.defense + @bonus_defense
				encounter_hits = encounter.attack >= total_defense
				
				if total_attack >= encounter.defense
					puts "%s has slain %s, gaining $%i" % [@name, encounter.name, encounter.treasure]

					loot = encounter.treasure
					loot -= 1 if @brags.include?(:blindfold) && !encounter_hits
					loot = 0 if loot < 0

					@treasure += loot
				end

				if encounter_hits
					puts "%s takes %i wound%s" % [@name, encounter.damage, encounter.damage == 1 ? '' : 's']
					@wounds += encounter.damage
				end
			end
		end

		def roll number
			Array.new(number) { rand(6)+1 }
		end
	end
end