module Marten::DB::Query::SetSpec
  class Order < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :amount, :int
    field :price, :float
  end
end
