class Array
	def sum
		inject(0) { |s,c| s + c }
	end
end

module GauntletOfFools
	class Logger
		def self.log str
			@file ||= File.open('log.txt', ?w)
			@file.puts str

			#puts st
		end
	end

	class CardDefiner < BasicObject
		def initialize card
			@card = card
		end		

		def unfinished!
			@card.unfinished = true
		end

		def name
			@card.name
		end

		def method_missing m, v=nil, &b
			raise "block AND value provided" if v && b
			@card.instance_variable_set("@#{m}", b || v)
		end
	end

	class Deck
		HOOKS = %w(at_start before_encounter after_encounter bonus_damage)
		REPLACEMENT_HOOKS = %w(instead_of_treasure)

		attr_reader *HOOKS, *REPLACEMENT_HOOKS
		attr_accessor :unfinished

		def self.method_missing name, *args, &b
			raise "CHECK THIS" unless args.empty? && b
			new_card = self.new(name.to_s.capitalize.gsub(/_(\w)/){" #{$1.upcase}"})
			CardDefiner.new(new_card).instance_eval(&b)
			self.register(new_card) unless new_card.unfinished

			new_card
		end

		def self.register item
			@items ||= []
			@items << item
		end

		def self.all
			@items
		end

		def * num
			(num-1).times { self.class.register(self) }
		end
	end
end