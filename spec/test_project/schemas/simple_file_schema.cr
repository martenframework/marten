class SimpleFileSchema < Marten::Schema
  field :label, :string, required: true
  field :file, :file, required: true
end
