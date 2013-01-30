module GauntletOfFools
	PERMANENT_EFFECTS = [:poison, :hangover, :blindfolded].freeze # TODO: refactor this away, use #gain_permanent_effect or something similar

	class Option < Struct.new(:hero, :weapons, :current_owner, :brags, :parent_opt)
		def inspect
			"%s/%s+%p%s" % [hero.name, weapons.map(&:name)*',', brags, current_owner ? " (#{current_owner})" : '']
		end

		def is_assigned?
			current_owner
		end

		def to_player new_name=nil
			Player.new(new_name || current_owner, hero, weapons, brags)
		end

		def copy
			Option.new(hero, weapons, current_owner, brags, self)
		end

		def with_any_new_brag
			(GauntletOfFools::Brag.all - brags).map { |b| Option.new(hero, weapons, current_owner, brags + [b], self)}
		end
	end

	class Player
		attr_reader :name, :hero, :weapons, :brags, :age, :fight_queue, :hero_tokens, :weapon_tokens
		attr_accessor :wounds, :treasure
		attr_accessor :current_encounter, :delegates, :opponents

		DISTRIBUTION = Hash.new do |h,dice|
			h[dice] = if dice <= 0
				{0 => 1}
			else
				r = Hash.new(0)
				DISTRIBUTION[dice-1].each do |value,occur|
					(1..6).each { |v| r[value+v] += occur }
				end
				r
			end
		end

		CHANCE_TO_HIT = Hash.new do |h,(dice,attack,factor,dfactor,defense)|
			d = DISTRIBUTION[dice].map { |k,v| [(k * dfactor + attack) * factor, v] }
			hits = d.select { |k,v| k >= defense }
			h[[dice,attack,factor,dfactor,defense]] = hits.empty? ? 0 : (hits.transpose.last.sum.to_f / d.transpose.last.sum)
		end

		def initialize name, hero, weapons, brags=[]
			@name = name
			@brags = brags
			@hero = hero
			@weapons = [*weapons]

			@delegates = []
			@opponents = []

			@ai = BasicAI.new(self)

			@wounds, @treasure, @age = 0, 0, 0
			@current_encounter = []
			@fight_queue = []

			@current_effects, @next_turn_effects = [], []
			@tokens = Hash.new { |h,k| h[k] = [0, 0]}
			@temp_tokens = Hash.new(0)

			@hero_tokens = hero.tokens
			@weapon_tokens = @weapons.map(&:tokens)
		end

		def self.from_names name, hero, weapons, brags=[]
			args = name, Hero[hero], [*weapons].map { |w| Weapon[w] }, [*brags].map { |b| Brag[b] }
			raise args.inspect if args.flatten.any? { |a| a.nil? } 

			new(*args)
		end

		def run_hook hook, *data
			r = [@current_encounter, @hero, @delegates, @weapons, @brags].flatten.inject(data) do |d,obj| 
				iv = obj && obj.call_hook(hook, self, current_encounter, *d)
				iv ? [iv] : d
			end
			r.size == 1 ? r.first : r
		end

		def to_s
			s = "#{@name} (#{@hero.name}/#{@weapons*','})"
			if @brags.size > 0
				s += ' + ' + (@brags * ',')
			end

			s
		end

		def queue_fight encounter=nil
			@fight_queue << encounter
		end

		def chance_to_hit defense, bonus_dice=0 # for simulation purposes
			return 1.0 if has? :kill_next
			# FIXME: one arm tied?
			CHANCE_TO_HIT[[attack_dice+bonus_dice, bonus_attack, attack_factor, dice_factor, defense]]
		end

		def decide d, *args
			@ai.decide d, @current_encounter, *args
		end

		def next_turn effect
			Logger.log '%s will gain an effect next turn: %s' % [@name, effect]
			@next_turn_effects << effect
		end

		def begin_turn
			@temp_tokens.each_key { |k| @temp_tokens[k] = 0 }
			@age += 1
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

		def discard_all_penalty_tokens # TODO: check interactions with getting a -1 penalty when you already have a +1 bonus
			Logger.log '%s discards all penalty tokens.' % [@name]
			@tokens.each_key { |k| @tokens[k][1] = 0 }
		end

		def gain_hero_token n=1
			n = -@hero_tokens if (n + @hero_tokens) < 0
 
 			if n != 0
				@hero_tokens += n
				Logger.log '%s %s %s hero token%s (%s remaining).' % [@name, n > 0 ? 'gains' : 'loses', n.abs==1 ? 'a' : n.abs, n.abs==1 ? '' : 's', @hero_tokens]
			end

			true
		end

		def gain_weapon_token n=1, weapon=nil
			i = if @weapons.size > 1
				weapon ? @weapons.index { |w| w.name == weapon } : 0 # FIXME DECIDE
			else
				0
			end

			n = -@weapon_tokens[i] if (n + @weapon_tokens[i]) < 0

			if n != 0
				@weapon_tokens[i] += n 
				Logger.log '%s %s %s weapon token%s %s(%s remaining).' % [
					@name, n > 0 ? 'gains' : 'loses', n.abs==1 ? 'a' : n.abs, n.abs==1 ? '' : 's', @weapons.size > 1 ? "(for #{@weapons[i]}) " : '', @weapon_tokens*?/
				]
			end

			true
		end

		# currently all or nothing
		def spend_weapon_token n=1, weapon=nil 
			return false if n <= 0
			return false if has? :no_weapon_tokens

			i = if @weapons.size > 1
				weapon ? @weapons.index { |w| w.name == weapon } : 0 # FIXME DECIDE
			else
				0
			end

			if @weapon_tokens[i] >= n
				@weapon_tokens[i] -= n
				Logger.log '%s spends %s weapon token%s %s(%s remaining).' % [
					@name, n==1 ? 'a' : n, n==1 ? '' : 's', @weapons.size > 1 ? "(from #{@weapons[i]}) " : '', @weapon_tokens*?/
				]
				true
			end
		end

		# FIXME: returns sum of all weapons if you have multiples, make sure this works
		def weapon_tokens weapon=nil
			weapon ? @weapon_tokens[@weapons.index { |w| w.name == weapon }] : @weapon_tokens.sum
		end

		def spend_hero_token n=1
			return false if n <= 0

			if @hero_tokens >= n
				@hero_tokens -= n
				Logger.log '%s spends %s hero token%s (%i remaining).' % [@name, n==1 ? 'a' : n, n==1 ? '' : 's', @hero_tokens]
				true
			end
		end

		def gain_treasure amount
			Logger.log '%s %s %i coin%s.' % [@name, amount > 0 ? 'gains' : 'loses', amount.abs, amount == 1 ? '' : 's']
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

		def dead?
			@wounds >= 4 && !has?(:cannot_die)
		end

		def gain_bonus token_type, amount=1
			Logger.log '%s %s %i %s permanently.' % [@name, amount > 0 ? 'gains' : 'loses', amount.abs, token_type] if amount != 0
			@tokens[token_type][amount < 0 ? 1 : 0] += amount
		end

		def gain_temp token_type, amount # FIXME: TURN VERSUS ROUND
			Logger.log '%s %s %i %s for the rest of the turn.' % [@name, amount > 0 ? 'gains' : 'loses', amount.abs, token_type] if amount != 0
			@temp_tokens[token_type] += amount
		end

		def bonus token_type
			@tokens[token_type].sum
		end

		def temp token_type # FIXME: per turn vs per roll
			@temp_tokens[token_type]
		end

		def defense
			return 0 if has? :zero_defense
			subtotal = @hero.defense + bonus(:defense) + temp(:defense)
			run_hook(:defense, subtotal)
		end

		def attack_dice
			return 0 if has? :zero_attack
			# FIXME: might want to use lower value, eg for cockroach
			subtotal = @weapons.map(&:dice).max + bonus(:dice) + temp(:dice)
			run_hook(:attack_dice, subtotal)
		end

		def bonus_attack
			return 0 if has? :zero_attack
			subtotal = @weapons.inject(bonus(:attack)) { |s,w| s + (w.call_hook(:bonus_attack, self) || 0) }
			run_hook(:bonus_attack, subtotal)
		end

		def attack_factor
			return 0 if has? :zero_attack
			return 2 if has? :double_attack
			1
		end

		def dice_factor
			@weapons.any? { |w| w.name == 'Cleaver' } ? 4 : 1  # FIXME: hmm
		end

		def roll number
			return [] if number <= 0
			r = Array.new(number) { rand(6)+1 }
			Logger.log '%s rolls %i dice, resulting in => %p => %i' % [@name, number, r, r.sum]
			r
		end

		def calculate_attack dice
			(dice.sum * dice_factor + bonus_attack) * attack_factor
		end
	end
end