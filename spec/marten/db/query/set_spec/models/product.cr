module Marten::DB::Query::SetSpec
  class Product < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :name, :string, max_size: 255
    field :price, :int
    field :rating, :float, blank: true, null: true
  end
end
