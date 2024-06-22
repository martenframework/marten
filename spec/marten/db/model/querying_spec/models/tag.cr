module Marten::DB::Model::QueryingSpec
  class Tag < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :name, :string, max_size: 255
    field :is_active, :bool, default: true

    scope :active { filter(is_active: true) }
  end
end
