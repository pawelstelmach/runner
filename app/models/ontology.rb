# class Ontology
# 	
# 	attr_accessor :concepts
# 	
# 	def self.import_owls_tc
# 		path_to_dir = '/Users/tomimek/Desktop/SOA/owls-tc3/htdocs/ontology'
# 		Dir.entries(path_to_dir).each do |f|
# 			unless f.include? ['.', '..']
# 				data = Hash.from_xml( File.open(f).read )
# 				name = data['key']
# 				desc = data['key']
# 				Concept.create( { :name => name, :desc => desc } )
# 			end
# 		end
# 	end
# 
# 	def self.generate_meta_data
# 		Concept.all.each do |c|
# 			c.metadata = {}
# 		end
# 	end
# 	
# end
# 
# class Concept < ActiveRecord::Base
# 	
# 	attr_reader :name, :desc, :metadata # form DB
# 	attr_accessor :parent, :childs
# 	
# end