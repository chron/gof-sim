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

class String
	PLURALS = Hash.new { |h,k| h[k] = k+'s' }.merge('defense' => 'defense', 'die' => 'dice', 'dice' => 'dice', 'attack' => 'attack')

	def pluralize
		self.gsub(/^(.* )(.+)$/) { $1 + PLURALS[$2] }
	end
end