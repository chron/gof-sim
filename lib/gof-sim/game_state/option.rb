module GauntletOfFools
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
end