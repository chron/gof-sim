module GauntletOfFools
	class Hero < Deck
		attr_reader :name, :wounds, :treasure, :defense, :tokens

		def initialize name
			@name = name
			@defense = 13
			@tokens = 2
		end

		def to_s
			name
		end

		barbarian {
			defense 18
		}

		monk {
			defense 10
		}
	end
end