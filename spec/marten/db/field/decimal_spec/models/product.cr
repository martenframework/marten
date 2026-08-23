module Marten::DB::Field::DecimalSpec
  class Product < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :price, :decimal, max_digits: 10, decimal_places: 2, blank: true, null: true
  end
end
