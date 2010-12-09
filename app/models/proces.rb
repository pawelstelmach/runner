class Proces
	
	attr_reader :proces_id, :input, :output, :service_class
	attr_accessor :childs, :parents, :wyrazenie
	cattr_accessor :max_kandydatow, :algorytm_doboru_uslug, :podobienstwo
	
	def initialize( data )
		@@max_kandydatow = 10
		@@algorytm_doboru_uslug ||= 'search'
		input = (data["input"].is_a? Array) ? data["input"].map{ |s| s.strip }.sort.join(',') : data["input"].map{ |s| s.strip }
		output = (data["output"].is_a? Array) ? data["output"].map{ |s| s.strip }.sort.join(',') : data["output"].map{ |s| s.strip }
		@proces_id, @input, @output, @service_class = data["id"], input, output, data["class"]
		@childs, @parents, @wyrazenie = [], [], {}
		Qos::TYPES.each{ |typ| @wyrazenie[typ.to_sym] = "p(#{@proces_id})" }
	end

	def kandydaci
   print "#{@class}\n\n"
		@kandydaci ||= Service.find(:all, :from => @@algorytm_doboru_uslug.to_sym, 
			:params => {
				:input => @input.split(',').sort.join(','),
				:output => @output.split(',').sort.join(','),
				:podobienstwo => @@podobienstwo,
				:limit => @@max_kandydatow,
				:order => :id,
        :service_class => @service_class
			}
		)
    
    #:order => 'RANDOM()'
	end

end