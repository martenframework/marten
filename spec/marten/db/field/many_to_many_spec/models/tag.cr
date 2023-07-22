module Marten::DB::Field::ManyToManySpec
  class Tag < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :label, :string, max_size: 255
  end
end
