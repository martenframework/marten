class SimpleSchema < Marten::Schema
  field :first_name, :string, required: true
  field :last_name, :string, required: true
end
