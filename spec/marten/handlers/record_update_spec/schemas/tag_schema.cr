module Marten::Handlers::RecordUpdateSpec
  class TagSchema < Marten::Schema
    field :name, :string, required: true, min_size: 2
    field :description, :string, required: false
    field :unused, :string, required: false
  end
end
