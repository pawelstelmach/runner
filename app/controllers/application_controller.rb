# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base

	helper :all # include all helpers, all the time

  def run
    raise 'No url given.' unless params[:url] # nie podano adresu pliku xml z @eksperymentem

    @t = Timer.new
    @l = []

    begin
      @eksperyment = Hash.from_xml( Net::HTTP.get_response(URI.parse(params[:url]) ).response.body )['request']
    rescue
      raise 'Blad odczytu konfiguracji kompozycji'
    end
    
    raise 'Blad odczytu konfiguracji kompozycji' if @eksperyment == nil

    check_edges(@eksperyment)
    # wykryj zmieniajace sie elementy, lekka zadyma, bo moga tu byc zagniezdzenia
    changes = {}
    @eksperyment.each do |k,v|
      changes[k] = v if v.include? '..'
      v.each { |kk,vv| changes[k+'_'+kk] = vv if vv.include? '..'  
      } if v.class == Hash #dla zagniezdzonych
    end
    
    #if changes.count == 0 zmienione przez L
    if changes.size == 0
      #nic nie jest zmienne, wiec robimy zwykla jedna iteracje
      iteracja
    #elsif changes.count > 1 zmienione przez L
    elsif changes.size > 1
      #zmienia sie wiecej niz 1 parametr na raz !
      raise 'Za dużo parametrów jest ustawionych jako zakresy'
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
    end
    @p.wagi = tmp
    
    tmp = {}
    @eksperyment["nonfunctionalities"]["total"].each do |k, v|
      tmp[k] = v["value"].to_f
    end
    @p.ograniczenia = tmp
    
    Proces.max_kandydatow = @eksperyment["parameters"]["max_candidates"].to_i #3#@eksperyment["max_kandydatow"].to_i
    Proces.algorytm_doboru_uslug = @eksperyment["parameters"]["serivce_selection_algorithm"] #"plugin"#@eksperyment["algorytm_doboru_uslug"]
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
      @l << [ 'csv_data', "#{change_value}, #{@p.jakosc(a)}" ] unless what_changes.nil?
      @l << [ 'plan', pokaz_plan(a, @eksperyment) ]
    end

    # puts "(B) Planow spelniajacych wymagania: #{poprawnych_b}."
    # puts "(H) Planow spelniajacych wymagania: #{poprawnych_h}, dla #{@iteracji_alg_h} iteracji."
    # puts "Ilosc unikalnych planow: #{plany.uniq.count}"
    # @t.pokaz
  end

  def pokaz_plan(plan, request)
    
    #request = request.sort_by{ |p, u| p.proces_id }
    matrix_size = request["functionalities"]["functionality"].size+1
    @matrix = Array.new(matrix_size)
    
    
    for r in 0..matrix_size do
      @matrix[r] = Array.new(matrix_size)
    end
    
    for r in 0..matrix_size do 
      for i in 0..matrix_size do
          @matrix[r][i] = 0
      end     
    end
    
    request["functionalities"]["functionality"].each do |i|
      temp_arr = i["child"].to_a
      if temp_arr.empty?
        @matrix[(i["id"] ? i["id"].to_i : 0)][matrix_size] = 1
      end
      temp_arr.each do |c|
        if(c.to_i==2)
          @matrix[0][i["id"].to_i] = 1
        end
        @matrix[(i["id"] ? i["id"].to_i : 0)][(c ? c.to_i : matrix_size)] = 1
      end
    end
    
    @final_plan = plan
    @final_request = request
    @start = @final_request["functionalities"]["functionality"].select do |item|item["class"]=="#start" end
    @start = @start.first
    @end = @final_request["functionalities"]["functionality"].select do |item|item["class"]=="#end" end
    @end = @end.first
    render 'pokaz_plan.xml.erb'
  end

  def check_edges(eksperyment)

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
end