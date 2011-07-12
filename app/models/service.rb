class Service < ActionWebService::Struct
  member :id, :integer
  member :name, :string   
  member :description, :string
  member :input, :string
  member :output, :string
  member :created_at, :datetime
  member :updated_at, :datetime
  member :cost, :integer 
  member :response_time, :integer
  member :availability, :double
  member :succesful, :double
  member :reputation, :double
  member :frequency, :double
  member :service_class, :string
end