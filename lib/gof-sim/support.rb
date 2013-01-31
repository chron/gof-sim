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

	def median
		s = sort
		size % 2 == 0 ? (s[size/2] + s[size/2-1]) / 2.0 : s[size/2]
	end
end

module GauntletOfFools
	class Logger
		@logging = true

		def self.logging= v
			@logging = v
		end

		def self.log str
			return unless @logging

			@file ||= File.open('log.txt', ?w)
			@file.puts str

			true
		end
	end

	class GameObject
		attr_accessor :name
		attr_reader :instant

		def initialize name, &b
			@name = name
			@hooks = {} # FIXME: multiple hooks on the same GameObject/hook_name?

			instance_eval(&b) if b

			self.class.register(self)
		end

		def to_s
			@name
		end

		def <=> other
			@name <=> other.name
		end

		def hooks hook_name, &b
			@hooks[hook_name] = b
		end

		def call_hook hook_name, *args
			h = @hooks[hook_name] 
			h[*args] if h
		end

		def hooks? hook_name
			@hooks.include?(hook_name)
		end

		def self.register item
			@items ||= []
			@items << item
		end

		def self.all
			@items
		end

		def self.[] name
			@items.find { |i| i.name == name }
		end
	end
end