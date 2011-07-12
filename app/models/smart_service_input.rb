class SmartServiceInput < ActionWebService::Struct 
  member :metaname, :string
  member :name, :string
  member :type, :string
  #member :dataVariable, [Object]
  member :source, :string
end