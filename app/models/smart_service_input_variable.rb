class SmartServiceInputVariable < ActionWebService::Struct
  member :name, :string
  member :value, Object
  member :type, :string
end