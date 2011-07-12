class SmartServiceQosParameter < ActionWebService::Struct
  member :weight, :float
  member :unit, :string
  member :value, :float
  member :relation, :string
end