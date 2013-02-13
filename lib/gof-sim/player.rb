module GauntletOfFools
	TOKEN_LOGIC = {
		:poison => GameObject.new('Poison') {
			hooks(:end_of_turn) { |player|
				# FIXME: possible to have multiple poisons, eg via adventurer/extra_bitey?
				if player.tokens(:poison) > 0 && !player.has?(:recently_poisoned)
					player.log 'Poison courses through %s\'s veins.' % [player.name]
					player.wound(1)
				end
			}
		}
	}

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
		attr_reader :name, :hero, :weapons, :brags, :age, :fight_queue, :delegates, :decisions
		attr_accessor :opponents, :game, :current_state, :next_state, :current_roll

		PENALTY_TOKENS = %w(reduced_defense reduced_attack reduced_dice poison)
		TEMP_TOKENS = %w(temp_defense temp_dice)

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
			@decisions = []

			@ai = BasicAI.new(self)

			@age = 0
			@fight_queue = []

			@current_state, @next_state = nil, nil
			@current_effects, @next_turn_effects = [], []
			@tokens = Hash.new(0)

			@tokens[:hero_token] = hero.tokens
			@weapon_tokens = @weapons.map(&:tokens)
		end

		def clone
			obj = super
			depth = @name[/\(D:(\d+)\)$/, 1] || 0

			obj.instance_eval do
				@name = "Future #{@name} (D:#{depth.to_i+1})"
				@fight_queue = @fight_queue.dup
				@current_effects = @current_effects.dup
				@next_turn_effects = @next_turn_effects.dup
				@tokens = @tokens.dup
				@decisions = @decisions.dup
				@delegates = @delegates.dup
				@weapon_tokens = @weapon_tokens.dup
				@game = nil
				@ai = BasicAI.new(self) # FIXME: current_encounter won't be set?
			end

			obj
		end

		def log message
			@game.log(message) if @game
		end

		def self.from_names name, hero, weapons, brags=[]
			args = name, Hero[hero], [*weapons].map { |w| Weapon[w] }, [*brags].map { |b| Brag[b] }
			raise args.inspect if args.flatten.any? { |a| a.nil? } 

			new(*args)
		end

		def self.random
			h = Hero.all.sample
			w = Weapon.all.sample(h.number_of_weapons)
			name = h.name[0...3] + w.map { |e| e.name[0...3] }.join

			new(name, h, w, [])
		end

		# TODO: add a new GameObject to cache all static hooks using #absorb (hero+weapons+brags at least)
		def run_hook hook, *data
			# FIXME: encounter before weapons etc makes Gladiator AI difficult
			# FIXME: one-use die before weapons with insta kill powers or encounter skips?
			r = [@delegates, @hero, @fight_queue.first, @weapons, @brags].flatten.inject(data) do |d,obj| 
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

		# queueing nil will result in a brand new encounter draw.
		# CHECK: should this new encounter (sometimes?) be without modifiers?
		def queue_fight encounter=nil
			@fight_queue << encounter
		end

		def current_encounter
			@fight_queue[0]
		end

		def must_decide decision
			@decisions << decision if decision.relevant_to(self)
		end

		def make_decision decision, choice
			raise 'NO' if !@decisions.include?(decision)

			@decisions.delete(decision) if !decision.repeatable? || !choice
			decision.apply_to(self) if choice

			# Clear out other decisions that no longer apply, eg because you don't have the necessary tokens.
			@decisions.delete_if { |d| !d.relevant_to(self) }
		end

		def chance_to_hit defense, bonus_dice=0 # for simulation purposes
			return 1.0 if has? :kill_next
			# FIXME: currently ignores one arm tied
			CHANCE_TO_HIT[[attack_dice+bonus_dice, bonus_attack, attack_factor, dice_factor, defense]]
		end

		def decide d, *args
			@ai.decide d, @fight_queue.first, *args
		end

		def next_turn effect
			#log '%s will gain an effect next turn: %s' % [@name, effect]
			@next_turn_effects << effect
		end

		def begin_turn
			@age += 1
			@current_effects.clear
			@current_effects.concat(@next_turn_effects)
			@next_turn_effects.clear
			TEMP_TOKENS.each { |t| @tokens.delete(t.intern) }
		end

		def number_of effect
			@current_effects.count(effect)
		end

		def gain *effects
			#effects.each { |e| log '%s gains an effect: %s' % [@name, e] }
			@current_effects.concat(effects)
		end

		def has? effect
			@current_effects.include?(effect)
		end

		def clear_effect effect
			@current_effects.delete_if { |e| effect == e }
		end

		def discard_all_penalty_tokens # TODO: check interactions with getting a -1 penalty when you already have a +1 bonus
			log '%s discards all penalty tokens.' % [@name]
			PENALTY_TOKENS.each { |k| @tokens.delete(k.intern) }
		end

		def gain_weapon_token n=1, weapon=nil
			i = if @weapons.size > 1
				if weapon
					@weapons.index { |w| w.name == weapon }
				else
					if n < 0 # If we're reducing tokens, check which weapons have tokens available
						weapons_with_tokens = @weapon_tokens.map.with_index { |v,i| i if v > 0 }.compact
						if weapons_with_tokens.empty?
							0 # TODO: check this is ok
						elsif weapons_with_tokens.size == 1
							weapons_with_tokens.first
						else
							@weapons.index(decide(:which_weapon_token_to_discard, weapons_with_tokens.map { |i| @weapons[i] }))
						end
					else
						@weapons.index(decide(:which_weapon_to_gain_token_for))
					end
				end
			else
				0
			end

			n = -@weapon_tokens[i] if (n + @weapon_tokens[i]) < 0

			if n != 0
				@weapon_tokens[i] += n
				log_gain_message('weapon token', n, "#{@weapons.size > 1 ? " (for #{@weapons[i]})" : ''} (#{@weapon_tokens[i]} remaining).")
			end

			true
		end

		def spend_weapon_token n=1, weapon
			raise 'NO WEAPON' if weapon.nil?

			return false if n <= 0
			return false if has? :no_weapon_tokens

			i = if @weapons.size > 1
				@weapons.index { |w| w.name == weapon }
			else
				0
			end

			if @weapon_tokens[i] >= n
				@weapon_tokens[i] -= n
				log_gain_message('weapon token', n, "#{@weapons.size > 1 ? " (for #{@weapons[i]})" : ''} (#{@weapon_tokens[i]} remaining).", 'spends', '')
				true
			end
		end

		def weapon_tokens weapon=nil
			weapon ? @weapon_tokens[@weapons.index { |w| w.name == weapon }] : @weapon_tokens.sum
		end

		def spend_hero_token n=1
			spend_token(:hero_token, n)
		end

		def gain_token token_type, amount=1, pos_verb='gains', neg_verb='loses' # FIXME: DRY this
			# FIXME: so ugly
			if l=TOKEN_LOGIC[token_type]
				if amount + @tokens[token_type] > 0
					@delegates << l if !@delegates.include?(l)
				else
					@delegates.delete(l)
				end
			end

			amount = -@tokens[token_type] if (amount + @tokens[token_type]) < 0
			log_gain_message(token_type.to_s.tr('_', ' '), amount, '.', pos_verb, neg_verb)
			@tokens[token_type] += amount
		end

		def spend_token token_type, n=1
			return false if n <= 0
			return false if token_type == :hero_token && has?(:no_hero_tokens)

			if @tokens[token_type] >= n
				@tokens[token_type] -= n
				log_gain_message(token_type.to_s.tr('_',' '), n, " (#{@tokens[token_type]} remaining).", 'spends', '')
				true
			end
		end

		def gain_treasure amount
			gain_token(:treasure, amount)
		end

		def wounds
			tokens(:wound)
		end

		def treasure
			tokens(:treasure)
		end

		def wound amount=1
			gain_token(:wound, amount, 'receives', 'is cured of')
		end

		def heal amount=1
			wound(-amount)
		end

		def dead?
			tokens(:wound) >= 4 && !has?(:cannot_die)
		end

		def log_gain_message object, amount, suffix='.', pos_verb='gains', neg_verb='loses'
			if amount != 0
				log '%s %s %i %s%s' % [name, amount > 0 ? pos_verb : neg_verb, amount.abs, amount.abs == 1 ? object : object.to_s.pluralize, suffix]
			end
		end

		def tokens token_type
			@tokens[token_type]
		end

		def defense
			return 0 if has?(:zero_defense)
			subtotal = @hero.defense + tokens(:defense) + tokens(:temp_defense) - tokens(:reduced_defense)
			run_hook(:defense, subtotal)
		end

		def attack_dice
			return 0 if has?(:zero_attack)
			w = @weapons.size == 1 ? @weapons.first : decide(:which_weapon_dice, @weapons)
			subtotal = w.dice + tokens(:dice) + tokens(:temp_dice) - tokens(:reduced_dice)
			run_hook(:attack_dice, subtotal)
		end

		def bonus_attack
			return 0 if has?(:zero_attack)
			subtotal = tokens(:attack) + tokens(:temp_attack) - tokens(:reduced_attack)
			run_hook(:bonus_attack, subtotal)
		end

		def attack_factor
			return 0 if has?(:zero_attack)
			return 2 ** number_of(:double_attack)
		end

		def dice_factor
			# FIXME: hypothetical future interactions between multiple dice factors?
			@weapons.map(&:dice_factor).max
		end

		def roll number
			return [] if number <= 0
			r = Array.new(number) { rand(6)+1 }
			log '%s rolls %i dice, resulting in => %p => %i' % [@name, number, r, r.sum]
			r
		end

		def calculate_attack dice=@current_roll
			(dice.sum * dice_factor + bonus_attack) * attack_factor
		end

		def take_damage_from encounter
			if hero.call_hook(:instead_of_damage, self, encounter)
				log "%s uses a power instead of taking damage." % [@name]
			else
				damage_multiplier = 2 ** number_of(:take_double_damage)
				wound(encounter.damage * damage_multiplier) if encounter.damage > 0

				#raise [encounter, @tokens, @current_effects, self, damage_multiplier].to_s if damage_multiplier > 8

				damage_multiplier.times { run_hook(:extra_damage) }
			end
		end

		def receive_treasure_from encounter
			# FIXME: messages appear after their effects, difficult to fix
			
			loot = encounter.treasure
			loot -= 1 if has?(:blindfolded) && !has?(:ignore_brags) && has?(:dodged_this_round)

			gain_treasure(loot) if loot > 0
			run_hook(:extra_treasure)
		end
	end
end