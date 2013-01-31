source_files = Dir['../lib/**/*.rb']

comments = source_files.map do |f| 
	File.read(f).scan(/#\s*(.+)/)
end

puts comments