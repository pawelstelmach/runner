class Bruteforce

	def initialize(proces_zlozony)
		plan = {}
		@dobrych_planow = 0
		ilosci_uslug = proces_zlozony.procesy.map{ |pid, pr| pr.kandydaci.count }
		ilosc_kombinacji = ilosci_uslug.inject(1){ |sum, i| sum*i }
		if ilosc_kombinacji < 10_000 * 60 * 5 # 5 min
			puts "(B) Ilosc kombinacji: #{ilosc_kombinacji}. Zajmie to ok #{ilosc_kombinacji/10_000}s"
			ilosc_kombinacji.times do |i|
				tmp = i
				proces_zlozony.procesy.each_with_index do |obj, idx|
					k = tmp % ilosci_uslug[idx]
					tmp /= ilosci_uslug[idx]
					plan[obj[1]] = obj[1].kandydaci[k]
				end
				# print "." if i%1000 == 0
				# debugger
				# proces_zlozony.aktualny_plan = plan
				# print "#{proces_zlozony.agreguj(:availability)}, " if proces_zlozony.agreguj(:availability) > 0.4
				# print "#{proces_zlozony.jakosc plan}, " if proces_zlozony.jakosc(plan)== 0
				@dobrych_planow += 1 if proces_zlozony.jakosc(plan)== 0
			end
		else
			puts "Przerwano - Spodziewany czas wykonania przekracza 5 minut."
		end
	end
	
	def dobrych_planow
		@dobrych_planow
	end
	
end