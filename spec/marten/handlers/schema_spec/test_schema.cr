module Marten::Handlers::SchemaSpec
  class TestSchema < Marten::Schema
    field :foo, :string
    field :bar, :string
  end

  class EmptySchema < Marten::Schema
  end
end
