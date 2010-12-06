class Qos
	
	#TYPES = %w(cost time availability succesful reputation frequency)
	TYPES = %w(cost response_time) #TYPES = %w(cost response_time)
	
	#nodes to kolejno podane nody (lista)
	def self.szeregowo(*nodes)
		{
			:cost => nodes.map{|n| n.wyrazenie[:cost]}.join(' + '),
			#:time => nodes.map{|n| n.wyrazenie[:time]}.join(' + '),
      :response_time => nodes.map{|n| n.wyrazenie[:response_time]}.join(' + '),
			:availability => nodes.map{|n| n.wyrazenie[:availability]}.join(' * '),
			:succesful => nodes.map{|n| n.wyrazenie[:succesful]}.join(' * '),
			:reputation => "#{1.0 / (1 + nodes.size)}*(" + nodes.map{|n| n.wyrazenie[:reputation]}.join(' + ') + ")",
			:frequency => "#{1.0 / (1 + nodes.size)}*(" + nodes.map{|n| n.wyrazenie[:frequency]}.join(' + ') + ")",
		}
	end

	#nodes to array nodow
	def self.rownolegle(nodes)
		{
			:cost => nodes.map{|n| n.wyrazenie[:cost]}.join(' + '),
			#:time => "[#{nodes.map{|n| n.wyrazenie[:time]}.join(', ')}].max",
      :response_time => "[#{nodes.map{|n| n.wyrazenie[:response_time]}.join(', ')}].max",
			:availability => nodes.map{|n| n.wyrazenie[:availability]}.join(' * '),
			:succesful => nodes.map{|n| n.wyrazenie[:succesful]}.join(' * '),
			:reputation => "#{1.0 / (1 + nodes.size)}*(" + nodes.map{|n| n.wyrazenie[:reputation]}.join(' + ') + ")",
			:frequency => "#{1.0 / (1 + nodes.size)}*(" + nodes.map{|n| n.wyrazenie[:frequency]}.join(' + ') + ")",
		}
	end
	
end