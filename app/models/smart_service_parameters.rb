class SmartServiceParameters < ActionWebService::Struct
  member :neighbour_plans, :integer
  member :max_candidates, :integer
  member :similarity, :float
  member :selection, :string
  member :iterations, :integer
end