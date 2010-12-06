# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
end

class String
	def red; colorize(self, "\e[1m\e[31m"); end
	def green; colorize(self, "\e[1m\e[32m"); end
	def dark_green; colorize(self, "\e[32m"); end
	def yellow; colorize(self, "\e[1m\e[33m"); end
	def blue; colorize(self, "\e[1m\e[34m"); end
	def dark_blue; colorize(self, "\e[34m"); end
	def pur; colorize(self, "\e[1m\e[35m"); end
	def colorize(text, color_code)  "#{color_code}#{text}\e[0m" end
end

class Array

	#  sum of an array of numbers
	def suma
		return self.inject(0){|acc,i|acc +i}
	end

	#  average of an array of numbers
	def average
		return self.suma/self.length.to_f
	end

	#  variance of an array of numbers
	def sample_variance
		avg=self.average
		sum=self.inject(0){|acc,i|acc +(i-avg)**2}
		return(1/self.length.to_f*sum)
	end

	#  standard deviation of an array of numbers
	def standard_deviation
		return Math.sqrt(self.sample_variance)
	end

end

class Fixnum
	
	def times_average
		@czasy = []
		self.times do |i|
			start_time = Time.now
			yield
			@czasy << (Time.now - start_time)
		end
		@czasy
	end
	
end