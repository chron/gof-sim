module GauntletOfFools
	class CardDefiner < BasicObject
		def initialize card
			@card = card
		end

		def method_missing m, v=nil, &b
			raise "block AND value provided" if v && b
			@card.instance_variable_set("@#{m}", b || v)
		end
	end

	class Deck
		def self.method_missing name, *args, &b
			raise "CHECK THIS" unless args.empty? && b
			new_card = self.new(name.to_s.capitalize.gsub(/_(\w)/){" #{$1.upcase}"})
			CardDefiner.new(new_card).instance_eval(&b)
			self.register(new_card)

			new_card
		end

		def self.register item
			@items ||= []
			@items << item
		end

		def self.all
			@items
		end
	end
end