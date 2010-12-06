class Timer
	
	def initialize
		@czasy = []
	end
	
	def go(label="")
		start_time = Time.now
		yield
		@czasy << [label, (Time.now - start_time)]
	end
	
	def pokaz
		print "TIMER" 
		puts " -"*20
		@czasy.each { |label, czas| puts "#{label}: #{czas}s" }
		#puts "RAZEM: #{@czasy.inject(0){|sum,el| sum+el[1] }}s" if @czasy.count >1
	end
	
end