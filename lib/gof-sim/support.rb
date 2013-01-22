class Array
	def sum
		inject(0) { |s,c| s + c }
	end

	def mean
		sum.to_f / size
	end
	
	def stdev
    	m = mean
    	Math.sqrt(map { |v| (v - m)**2 }.mean)
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

		def name
			@card.name
		end

		def method_missing m, v=nil, &b
			raise "block AND value provided" if v && b
			@card[m] = b || v || true
		end
	end

	class Deck
		attr_reader :unfinished, :instant

		def initialize
			@data = {}
		end

		def [] element
			@data[element]
		end

		def []= element, value
			@data[element] = value
		end

		def unfinished?
			self[:unfinished!]
		end

		def method_missing name, *args
			@data[name] || super
		end

		def self.method_missing name, *args, &b
			raise "CHECK THIS" unless args.empty? && b
			new_card = self.new(name.to_s.capitalize.gsub(/_(\w)/){" #{$1.upcase}"})
			CardDefiner.new(new_card).instance_eval(&b)
			self.register(new_card) unless new_card.unfinished?

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