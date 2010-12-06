class ProcesZlozony
		
	attr_accessor :procesy, :aktualny_plan
	attr_writer :wagi, :ograniczenia
		
	def initialize(procesy)
		@procesy = {}
		@tabu = ListaTabu.new
		@wagi = {}
		@ograniczenia = {}
    procesy = procesy["functionalities"]["functionality"]    
    
		# create nodes
		procesy.each do |p|
			@procesy[p["id"]] = Proces.new( p )
		end
		
		# create connections
		procesy.each do |p|
			p["child"].each do |cid|
				@procesy[p["id"]].childs << @procesy[cid]
				@procesy[cid].parents << @procesy[p["id"]]
			end if p["child"]
		end
	end
	
	def pobierz_wagi
		#puts "Wagi parametrow QOS:"
		@wagi["cost"] = 1
		@wagi["availability"] = 1
		@wagi["succesful"] = 1
		@ograniczenia["cost"] = 30
		@ograniczenia["availability"] = 0.03
		@ograniczenia["succesful"] = 0.01
=begin
		Qos::TYPES.each do |typ|
			#print "#{typ}: "
			#@wagi[typ] = gets.to_f
			@wagi[typ] = rand 10
			puts "#{typ}: #{@wagi[typ]}"
		end
		puts "Ograniczenia parametrow QOS:"
		Qos::TYPES.each do |typ|
			#print "#{typ}: "
			#@ograniczenia[typ] = gets.to_f
			@ograniczenia[typ] = rand 10
			puts "#{typ}: #{@ograniczenia[typ]}"
		end
=end
	end
	
	def plan_wykonania(iter_max = 10)
   print "plan_wykonania!!"
		plan = plan_poczatkowy
    print plan
		@najplan = plan.clone
		if jakosc(plan) == 0
			# puts "Plan poczatkowy odrazu mial jakosc=0 :)".green 
			return  { :plan => plan, :plany_sasiednie => nil }
		else
			# puts "Plan poczatkowy #{jakosc(plan)}".yellow
	  end
    
    plany_sasiednie = Array.new   
		iter_max.times do |iter|
			plans = plan_sasiedni( plan.clone )
      
      plany_sasiednie << plans
      #chyba tytaj trzeba coś dodać
      
			#puts "Jakosc planu sasiedniego: #{jakosc(plans)}".blue
			@najplan = plans if jakosc(plans) < jakosc(@najplan)
			return plans if jakosc(plans) == 0
			if Math.exp( ( jakosc(plan)-jakosc(plans) )*iter ) > rand
				plan = plans
			else
				# dodaj_do_listy_tabu(plans)
			end
	end
   # print "\n\n!!! Plan #{plan} !!\n\n"
   # print "\n\n!!! Naj_plan #{@najplan} !!\n\n"
		#(jakosc(plan) < jakosc(@najplan)) ? plan : @najplan
    { :plan => ((jakosc(plan) < jakosc(@najplan)) ? plan : @najplan), :plany_sasiednie => plany_sasiednie }
	end
	
	def jakosc(plan, wektor=false)
		@aktualny_plan = plan #zachowujemy informacje dla f-cji p()
		v = Qos::TYPES.map do |typ|
			if %w(cost response_time).include? typ
				@wagi[typ] * [0, (agreguj(typ) - @ograniczenia[typ])/@ograniczenia[typ].to_f ].max
			else
				@wagi[typ] * [0, (@ograniczenia[typ] - agreguj(typ))/@ograniczenia[typ].to_f ].max
			end
		end
		if wektor
			temp = {}
			Qos::TYPES.each_with_index { |typ,i| temp[typ] = v[i] }
			return temp
		else
			return v.suma
		end
	end
	
	def agreguj(typ)
    #print "\n!!! Agreguje \n!!!"
		@aktualny_qos = typ.to_sym #zachowujemy informacje dla f-cji p()
    eval(@qos[typ.to_sym])
	end
	
	# Zwraca warotsc QOS uslugi przypisanej procesowi o podanym id w aktualnie testowanym planie wykonania
	def p(id)
    #print "\n!!! Wyliczam \n!!!" 
    #print @procesy[id.to_s].nil?
    #print @procesy[id.to_s].nil?
    #print @aktualny_plan #tu jest problem!!
    #print @aktualny_plan[ @procesy[id.to_s] ].nil?
		@aktualny_plan[ @procesy[id.to_s] ].send(@aktualny_qos)
	end
	
	#Określa jak dana usługa jest dopasowana do wymagań użytkownika
	def dopasowanie(usluga, proces)
		Qos::TYPES.inject(0) do |sum, typ|
			qosy_kandydatow = proces.kandydaci.map{|kandydat| kandydat.send(typ)}
			sum + if qosy_kandydatow.standard_deviation != 0
				@wagi[typ] * 
				( %w(cost time).include?(typ)?(-1):(1) ) *
				( (usluga.send(typ) - qosy_kandydatow.average) / qosy_kandydatow.standard_deviation )
			else
				@wagi[typ] * usluga.send(typ)
			end
		end
	end
	
	def plan_poczatkowy
		plan = {}
		@procesy.each_value do |proces|
			plan[proces] = proces.kandydaci.inject do |memo, usluga|
				dopasowanie(usluga, proces) > dopasowanie(memo, proces) ? usluga : memo
			end
		end
		plan
	end
	
	def plan_sasiedni(plan)
		# które kryteria są niespełnione ?
		# znajdz te 2 uslugi ktore najbardziej "psuja" wynik jakosci dopasowania kazdego z niespelnionych ograniczen
		jakosc(plan, true).reject{ |typ, q| q == 0 }.sort { |a,b| @wagi[a[0]] <=> @wagi[b[0]] }.reverse.each do |typ, wartosc|
			plan.sort{ |a,b| a[1].send(typ) <=> b[1].send(typ) }.reverse[0,2].each do |proces, usluga|
				
				kandydaci = proces.kandydaci.sort{ |a,b| a.send(typ) <=> b.send(typ) }.reject { |k| @tabu.include? [proces,k] }
				
				if kandydaci.empty?
					# Logger.log ['brak kandydatow', "proces => #{proces.proces_id}"]
					# render :text => "Brak uslug dla procesu #{@proces_id}".red and return false unless @kandydaci
				else
					kandydat = (%w(cost time).include? typ) ? kandydaci.first : kandydaci.last
					@tabu.dodaj [proces, kandydat]
					plan[proces] = kandydat
				end
			end
	end
		plan
	end

	def wylicz_qos
    graf = @procesy.clone
		while true
			break if not agreguj_szeregowo graf and not agreguj_rownolegle graf
  	end
		@qos = graf.values.first.wyrazenie
=begin
		puts "Wzory QOS".green
		Qos::TYPES.each { |type| puts "#{type.yellow}: #{@qos[type.to_sym]}" } # = #{F(@qos[type.to_sym])}
=end
	end

	def agreguj_szeregowo(graf)
		graf.each_value do |proces|
			if proces.childs.size == 1 and proces.childs.first.parents.size == 1
				a, b = proces, proces.childs.first
				a.wyrazenie = Qos.szeregowo a, b
				a.childs = b.childs
				b.childs.each { |bc| bc.parents.map! { |bcp| bcp == b ? a : bcp } }
				graf.delete b.proces_id
				return true
			end
		end
		return false
	end

	# UWAGA! - funkcja dziala tylko poprawnie kiedy nie ma w grafie zadnych polaczen szeregowych
	def agreguj_rownolegle(graf)
		graf.each_value do |proces|
			if proces.childs.size > 1
				c = proces.childs # c to array a nie wskaznik, wiec write'ow pod niego nie ma co robic
				c.first.wyrazenie = Qos.rownolegle c
				c.first.childs.first.parents = [c.first]
				c[1,c.length].each { |n| graf.delete n.proces_id }
				proces.childs = [proces.childs.first]
				return true
			end
		end
		return false
	end
	
end