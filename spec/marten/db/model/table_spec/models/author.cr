module Marten::DB::Model::TableSpec
  class Author < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :name, :string, max_size: 255
  end
end
