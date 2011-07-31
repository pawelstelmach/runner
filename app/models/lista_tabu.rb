class ListaTabu

	attr_reader :tabu

	def initialize
		@tabu = []
	end
	
	def add(element)
		# puts "Dodaje do tabu #{element}".blue
		@tabu << element
		@tabu.shift if @tabu.length > 8
	end
	
	def include?(element)
		@tabu.include? element
	end
	
end