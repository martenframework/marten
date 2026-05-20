module Marten::DB::Field::PolymorphicSpec
  class Recipe < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :title, :string, max_size: 255
  end
end
