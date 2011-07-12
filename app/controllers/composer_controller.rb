class ComposerController < ApplicationController
  wsdl_service_name 'Composer'
  web_service_api ComposerApi
  web_service_scaffold :invocation if Rails.env == 'development'
  
  
  def compose_plugin_math(smartservicegraph)
    selection_alg = "plugin_math_services"
    compose(smartservicegraph, selection_alg)
  end
  
  def compose_exact_match(smartservicegraph)
    selection_alg = "exact_match_2"
        
    #smartservicegraph = EngineUtils.xml_to_ssdl_struct(EngineUtils.ssdl_struct_to_xml(smartservicegraph))
    result = compose(smartservicegraph, selection_alg)
    result.inputdata = nil
    
    return result
  end
  
  def compose(smartservicegraph, selection_alg)
   @ssdl = smartservicegraph
   @eksperyment = Hash.new
   @eksperyment['name'] = "";
   @eksperyment['matrix'] = "";
   @eksperyment['functionalities'] = Hash.new
   @eksperyment['functionalities']['functionality'] = Array.new
   smartservicegraph.nodes.each do |node|
     node_hash = Hash.new
     node_hash['name'] = node.name
     node_hash['nodetype'] = node.nodetype
     node_hash['class'] = node.nodeclass
     node_hash['output'] = Array.new
     node.outputs.each do |out|
       node_hash['output'] << out.metaname
     end
     node_hash['input'] = Array.new
     node.inputs.each do |inp|
       node_hash['input'] << inp.metaname
     end
     node_hash['child'] = Array.new
     smartservicegraph.nodes.each do |inner_node|
       if(node!=inner_node)
        inner_node.inputs.each do |inp|
          if(inp.source == node.name)
            node_hash['child'] << smartservicegraph.nodes.index(inner_node)
          end
        end
       end
     end
     node_hash['id'] = smartservicegraph.nodes.index(node)
     @eksperyment['functionalities']['functionality'] << node_hash
   end
   @eksperyment['parameters'] = Hash.new
   @eksperyment['parameters']['neighbour_plan_number'] = smartservicegraph.parameters.neighbour_plans.to_s
   @eksperyment['parameters']['max_candidates'] = smartservicegraph.parameters.max_candidates.to_s
   @eksperyment['parameters']['similarity_value'] = smartservicegraph.parameters.similarity.to_s
   @eksperyment['parameters']['service_selection_algorithm'] = selection_alg.to_s
   @eksperyment['parameters']['algorithm_iteration_number'] = smartservicegraph.parameters.iterations.to_s

   @eksperyment['nonfunctionalities'] = Hash.new
   @eksperyment['nonfunctionalities']['total'] = Hash.new
   @eksperyment['nonfunctionalities']['total']['cost'] = Hash.new
   @eksperyment['nonfunctionalities']['total']['cost']['weight'] = smartservicegraph.qos.cost.weight.to_s
   @eksperyment['nonfunctionalities']['total']['cost']['unit'] = smartservicegraph.qos.cost.unit.to_s
   @eksperyment['nonfunctionalities']['total']['cost']['value'] =  smartservicegraph.qos.cost.value.to_s
   @eksperyment['nonfunctionalities']['total']['cost']['relation'] = smartservicegraph.qos.cost.relation.to_s
   
   @eksperyment['nonfunctionalities']['total']['response_time'] = Hash.new
   @eksperyment['nonfunctionalities']['total']['response_time']['weight'] = smartservicegraph.qos.time.weight.to_s
   @eksperyment['nonfunctionalities']['total']['response_time']['unit'] = smartservicegraph.qos.time.unit.to_s
   @eksperyment['nonfunctionalities']['total']['response_time']['value']  =  smartservicegraph.qos.time.value.to_s
   @eksperyment['nonfunctionalities']['total']['response_time']['relation']  = smartservicegraph.qos.time.relation.to_s
   
   
   compose_from_hash(@eksperyment)
   
  end
  
  def compose_from_hash(eksperyment)
    @t = Timer.new
    @l = []
    #begin 
    #  @eksperyment = Hash.from_xml( xml )['request']
    #rescue
    #  return 'Blad odczytu konfiguracji kompozycji'
    #end
    
    #return 'Blad odczytu konfiguracji kompozycji' if @eksperyment == nil

#    check_edges(@eksperyment)
    # wykryj zmieniajace sie elementy, lekka zadyma, bo moga tu byc zagniezdzenia
    changes = {}
    @eksperyment.each do |k,v|
      changes[k] = v if v.include? '..'
      puts "!!!  #{k} -> #{v}\n !!!"
      v.each { |kk,vv| changes[k+'_'+kk] = vv if vv.include? '..'  
      puts "!!!  #{kk} -> #{vv}\n !!!"
      } if v.class == Hash #dla zagniezdzonych
    end
    
    #if changes.count == 0 zmienione przez L
    if changes.size == 0
      #nic nie jest zmienne, wiec robimy zwykla jedna iteracje
      iteracja
    #elsif changes.count > 1 zmienione przez L
    elsif changes.size > 1
      #zmienia sie wiecej niz 1 parametr na raz !
      return 'Za dużo parametrów jest ustawionych jako zakresy'
    else
      #zmienia sie jeden parametr, ale i tak damy each, bo ladnie nam to rozbije na key i value
      changes.each do |what_changes, range|
        @l << [ 'csv_header', "#{what_changes}, jakosc" ]
        eval(range).to_a.each { |option| iteracja(what_changes, option) }
      end
    end
  end
  
private

  def pokaz_plan_z_jakoscia(p, plan)
    puts "- "*20
    puts "Jakosc planu: #{p.jakosc(plan)}"
    plan.each do |p,u|
      puts "P#{p.proces_id} -> U#{u.id}"
    end
  end

  def iteracja(what_changes=nil, change_value=nil)
    # ustaw liczniki
    poprawnych_h, poprawnych_b, plany = 0, 0, []
    
    #zakomentowane do testów
    #functionalities = Hash.from_xml(@eksperyment)["request"]["functionalities"]
    functionalities = @eksperyment
    @p = ProcesZlozony.new( functionalities )
    @p.wylicz_qos

    # ustaw dane startowe
    tmp = {}
    @eksperyment["nonfunctionalities"]["total"].each do |k, v|
      tmp[k] = v["weight"].to_f
      #puts "!!!  #{k} -> #{v["weight"].to_f}\n !!!"
    end
    @p.wagi = tmp
    
    tmp = {}
    @eksperyment["nonfunctionalities"]["total"].each do |k, v|
      tmp[k] = v["value"].to_f
      #puts "!!!  #{k} -> #{v["value"].to_f}\n !!!"
    end
    @p.ograniczenia = tmp
    
    Proces.max_kandydatow = @eksperyment["parameters"]["max_candidates"].to_i #3#@eksperyment["max_kandydatow"].to_i
    Proces.algorytm_doboru_uslug = @eksperyment['parameters']['service_selection_algorithm'] #"plugin"#@eksperyment["algorytm_doboru_uslug"]
    Proces.podobienstwo = @eksperyment["parameters"]["similarity_value"].to_f #3.0#@eksperyment["podobienstwo"].to_f
    @iteracji_alg_h = @eksperyment["parameters"]["algorithm_iteration_number"].to_i #3#@eksperyment["iteracji_alg_h"].to_i
    @iteracji_planow_sasiednich = @eksperyment["parameters"]["neighbour_plan_number"].to_i #3#@eksperyment["iteracji_planow_sasiednich"].to_i

    case what_changes
      when 'max_kandydatow' then Proces.max_kandydatow = change_value
      when 'iteracji_alg_h' then @iteracji_alg_h = change_value
      when 'iteracji_planow_sasiednich' then @iteracji_planow_sasiednich = change_value
      when /^ograniczenia_(\w+)/ then @eksperyment["ograniczenia"][$1] = change_value  #?
      when /^wagi_(\w+)/ then @eksperyment["wagi"][$1] = change_value #?
    end

    # puts "Iteracja | #{Proces.max_kandydatow} | #{@iteracji_alg_h} | #{@iteracji_planow_sasiednich}"
      #done till this point
    @t.go("Heuryst") do
      a = nil
      plany_sasiednie = nil
      @iteracji_alg_h.times do
        plans_hash = @p.plan_wykonania @iteracji_planow_sasiednich
        a = plans_hash[:plan]
        plany_sasiednie = plans_hash[:plany_sasiednie]
        #a = @p.plan_wykonania @iteracji_planow_sasiednich
        poprawnych_h += 1 if @p.jakosc(a) == 0
      end
      #print "!!! Plan: #{a.nil?}!!!\n"
      #print "!!! Plany sasiednie: #{plany_sasiednie}!!!\n#{plany_sasiednie.type} #{plany_sasiednie.size}" unless plany_sasiednie.nil?
      #@l << [ 'csv_data', "#{change_value}, #{@p.jakosc(a)}" ] unless what_changes.nil?
      #pokaz_plan(a, @eksperyment)
      #@l << [ 'plan', pokaz_plan(a, @eksperyment) ]
      @l = pokaz_plan(a, @ssdl)
    
  end

    return @l
    # puts "(B) Planow spelniajacych wymagania: #{poprawnych_b}."
    # puts "(H) Planow spelniajacych wymagania: #{poprawnych_h}, dla #{@iteracji_alg_h} iteracji."
    # puts "Ilosc unikalnych planow: #{plany.uniq.count}"
    # @t.pokaz
  end

  def pokaz_plan(plan, request)

#    request = request.sort_by{ |p, u| p.proces_id }
#    matrix_size = request["functionalities"]["functionality"].size+1
#    @matrix = Array.new(matrix_size)
#       
#    for r in 0..matrix_size do
#      @matrix[r] = Array.new(matrix_size)
#    end
#    
#    for r in 0..matrix_size do 
#      for i in 0..matrix_size do
#          @matrix[r][i] = 0
#      end     
#    end
#    
#    request["functionalities"]["functionality"].each do |i|
#      temp_arr = i["child"].to_a
#      if temp_arr.empty?
#       @matrix[(i["id"] ? i["id"].to_i : 0)][matrix_size] = 1
#      end
#      temp_arr.each do |c|
#        if(c.to_i==2)
#          @matrix[0][i["id"].to_i] = 1
#        end
#        @matrix[(i["id"] ? i["id"].to_i : 0)][(c ? c.to_i : matrix_size)] = 1
#      end
#    end
    @final_plan = plan
    @final_request = request
#    @start = @final_request["functionalities"]["functionality"].select do |item|item["class"]=="#start" end
#    @start = @start.first
#    @end = @final_request["functionalities"]["functionality"].select do |item|item["class"]=="#end" end
#    @end = @end.first
      
    return generate_composition_result(request, plan)
    #render 'pokaz_plan.xml.erb'
  end

  def check_edges_depracted(eksperyment)

    xml = functionalities_to_xml(eksperyment)
    data = {:sla => xml}
    uri = URI.parse("http://#{APP_CONFIG['edges_url']}/run")
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 1.hour
    http.read_timeout = 1.hour
    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data( data )
    result = http.request(request)
    result = result.body.strip
    @eksperyment["functionalities"] = Hash.from_xml(result)["functionalities"]
  end
  
  def check_edges(eksperyment) #new
      require 'soap/wsdlDriver'
      wsdl = "http://#{APP_CONFIG['edges_url']}/wsdl"
      edges = SOAP::WSDLDriverFactory.new(wsdl).create_rpc_driver
      data = functionalities_to_xml(eksperyment)
      begin
        result = edges.check(data)
      rescue
        result = nil
      end
      return @eksperyment["functionalities"] = Hash.from_xml(result)["functionalities"]
  end
  
  def functionalities_to_xml(eksperyment)
    functionalities = eksperyment["functionalities"]["functionality"]
    buffer = ""
    xml_build = Builder::XmlMarkup.new(:target => buffer, :ident=>2)
    xml_build.instruct! 
    xml_build.functionalities { 
    functionalities.each do |f| 
      xml_build.functionality {
        xml_build.id(f["id"])
        xml_build.name(f["name"]) 
        xml_build.class(f["class"]) 
        unless f["child"].nil?
          f["child"].to_a
          f["child"].each do |c|
            xml_build.child(c)
          end
        end
        unless f["input"].nil?
          f["input"].to_a
          f["input"].each do |i|
            xml_build.input(i)
          end
        end
        unless f["output"].nil?
          f["output"].to_a
          f["output"].each do |o|
            xml_build.output(o)
          end
        end
      }
    end};
    return buffer
  end
  
  def generate_composition_result(request, plan)
    plan.each do |p, u|
      functionality_id = p.proces_id.to_i
      request.nodes[functionality_id].address = u.name
      request.nodes[functionality_id].method = u.description
      request.nodes[functionality_id].nodetype = "Service"
    end
   
    return request
    
  end
end