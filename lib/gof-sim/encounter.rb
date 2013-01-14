module GauntletOfFools
	class Encounter < Deck
		attr_reader :name, :attack, :defense, :damage, :treasure
		attr_reader :instead_of_combat

		def initialize name
			@damage = 1
			@name = name
		end

		def to_s
			name
		end

		def display_name
			name + (attack ? " (#{attack}/#{defense})" : '')
		end

		rat {
			attack 10
			defense 10
			treasure 2
		}

		cat {
			attack 10
			defense 10
			treasure 2
		}

		turtle {
			attack 10
			defense 15
			treasure 2
		}

		deathbeast {
			attack 30
			defense 15
			treasure 5
		}

		healing_shrine {
			instead_of_combat { |p| p.heal 1 }
		}
	end
end