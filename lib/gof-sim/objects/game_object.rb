module GauntletOfFools
	class GameObject
		attr_accessor :name

		def initialize name, &b
			@name = name
			@hooks = Hash.new { |h,k| h[k] = [] }

			instance_eval(&b) if b

			self.class.register(self)
		end

		def clone
			new_obj = super
			new_obj.instance_eval { @hooks = Hash.new { |h,k| h[k] = [] } }
			self.all_hooks.each { |hook,ary| new_obj.all_hooks[hook] = ary.dup }

			new_obj
		end

		def absorb other
			other.all_hooks.each { |hook,ary| @hooks[hook].concat(ary) }
		end

		def all_hooks
			@hooks #.each { |h,a| a.each { |v| yield h,v }}
		end

		def to_s
			@name
		end

		def <=> other
			@name <=> other.name
		end

		def hooks hook_name, &b
			@hooks[hook_name] << b
		end

		def decision_at hook, name=nil, &b
			decision = Decision.new(name || 'Use ' + @name, self, &b)
			hooks(hook) { decision }
		end

		def call_hook hook_name, *args
			!@hooks[hook_name].empty? && @hooks[hook_name].map { |h| h[*args] }
		end

		def hooks? hook_name
			!@hooks[hook_name].empty?
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