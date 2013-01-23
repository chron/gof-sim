module GauntletOfFools
	BRAGS = [:blindfold, :hangover, :one_leg, :one_arm, :no_breakfast, :juggling].freeze
	PERMANENT_EFFECTS = [:poison, :hangover].freeze

	class Option < Struct.new(:hero, :weapon, :current_owner, :brags, :parent_opt)
		def inspect
			"%s/%s+%p%s" % [hero.name, weapon.name, brags, current_owner ? " (#{current_owner})" : '']
		end

		def is_assigned?
			current_owner
		end

		def to_player new_name=nil
			Player.new(new_name || current_owner, hero, weapon, brags)
		end

		def copy
			Option.new(hero, weapon, current_owner, brags, self)
		end

		def with_any_new_brag
			(BRAGS - brags).map { |b| Option.new(hero, weapon, current_owner, brags + [b], self)}
		end
	end

	class Player
		attr_reader :name, :hero, :weapon, :brags
		attr_writer :bonus_attack
		attr_accessor :wounds, :treasure, :bonus_dice, :bonus_defense, :hero_tokens, :weapon_tokens
		attr_accessor :kill_next, :dodge_next, :temp_dice, :current_encounter

		DISTRIBUTION = Hash.new do |h,dice|
			if dice <= 0
				r = {}
			elsif dice == 1
				r = Hash[*(1..6).map { |v| [v, 1] }.flatten]
			else
				o = DISTRIBUTION[dice-1]
				r = Hash.new(0)
				o.each do |value,occur|
					(1..6).each { |v| r[value+v] += occur }
				end
			end
			h[dice] = r
		end

		CHANCE_TO_HIT = Hash.new do |h,(dice,attack,factor,defense)|
			d = DISTRIBUTION[dice].map { |k,v| [(k + attack) * factor, v] }
			hits = d.select { |k,v| k >= defense }
			h[[dice,attack,factor,defense]] = hits.empty? ? 0 : (hits.transpose.last.sum.to_f / d.transpose.last.sum)
		end

		def initialize name, hero, weapon, brags
			@name = name
			@brags = []
			@hero = hero
			@weapon = weapon

			@ai = BasicAI.new(self)

			@wounds, @treasure = 0, 0
			@temp_dice = 0
			@bonus_attack, @bonus_dice, @bonus_defense = 0, 0, 0
			@hero_tokens, @weapon_tokens = hero.tokens, weapon.tokens

			@kill_next, @dodge_next = false, false
			@current_effects, @next_turn_effects = [], []

			brags.each { |b| add_brag(b) }
		end

		def to_s
			s = "#{@name} (#{@hero.name}/#{@weapon.name})"
			if @brags.size > 0
				s += ' + ' + (@brags * ',')
			end

			s
		end

		def chance_to_hit defense
			CHANCE_TO_HIT[[attack_dice, bonus_attack, attack_factor, defense]]
		end

		def decide d
			@ai.decide d, @current_encounter
		end

		def next_turn effect
			Logger.log '%s will gain an effect next turn: %s' % [@name, effect]
			@next_turn_effects << effect
		end

		def begin_turn
			@temp_dice = 0
			@current_effects.delete_if { |e| !PERMANENT_EFFECTS.include?(e) }
			@next_turn_effects.each { |e| gain e }
			@next_turn_effects.clear
		end

		def effects
			@current_effects
		end

		def gain effect
			Logger.log '%s gains an effect: %s' % [@name, effect]
			@current_effects << effect
		end

		def has? effect
			@current_effects.include?(effect)
		end

		def clear_effect effect
			@current_effects.delete_if { |e| effect == e }
		end

		def kill
			#Logger.log '%s will auto-kill.' % @name
			@kill_next = true
		end

		def dodge
			#Logger.log '%s will dodge the next attack.' % @name
			@dodge_next = true
		end

		def gain_temp_dice n
			Logger.log '%s gains %i dice for the next roll.' % [@name, n]
			@temp_dice += n
		end

		def spend_weapon_token n=1 # currently all or nothing
			return false if n==0
			return false if has? :no_weapon_tokens

			if @weapon_tokens >= n
				@weapon_tokens -= n
				Logger.log '%s spends %s weapon token%s (%i remaining).' % [@name, n==1 ? 'a' : n, n==1 ? '' : 's', @weapon_tokens]
				true
			end
		end

		def spend_hero_token n=1
			return false if n==0

			if @hero_tokens >= n
				@hero_tokens -= n
				Logger.log '%s spends %s hero token%s (%i remaining).' % [@name, n==1 ? 'a' : n, n==1 ? '' : 's', @hero_tokens]
				true
			end
		end

		def gain_treasure amount
			Logger.log ("#{name} has #{amount > 0 ? 'gained' : 'lost'} #{amount.abs} coin#{amount == 1 ? '' : 's'}.")
			@treasure += amount
		end

		def wound amount
			Logger.log ("#{name} recieves #{amount} wound#{amount == 1 ? '' : 's'}.")
			@wounds += amount
		end

		def heal amount
			actual_heal = [amount, wounds].min
			Logger.log "%s is cured of %i wound%s." % [self.name, actual_heal, actual_heal == 1 ? '' : 's'] if actual_heal > 0
			@wounds -= actual_heal
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
			return 0 if has? :zero_attack
			@weapon.dice + @bonus_dice + @temp_dice
		end

		def bonus_attack
			return 0 if has? :zero_attack
			@bonus_attack + (weapon.call_hook(:bonus_damage, self) || 0)
		end

		def attack_factor
			return 0 if has? :zero_attack
			return 2 if has? :double_attack
			1
		end

		def roll number
			return [] if number <= 0
			Array.new(number) { rand(6)+1 }
		end
	end
end