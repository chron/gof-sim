require '../lib/gof-sim'

# Number of encounters that can hit x armor
combats = GauntletOfFools::Encounter.all.select { |e| !e.non_combat? }
t = combats.size
8.upto(25) do |armor|
	n = combats.select { |e| e.attack >= armor }.size
	puts '%2i %s' % [armor, ?# * (n.to_f/t * 77)]
end


print '   '
1.upto(7) { |i| print ' %5i' % i }
puts
8.upto(25) do |defense|
	print '%3i' % defense
	1.upto(7) do |dice|
		print ' %5.3f' % GauntletOfFools::Player::CHANCE_TO_HIT[[dice,0,1,defense]]
	end
	puts
end