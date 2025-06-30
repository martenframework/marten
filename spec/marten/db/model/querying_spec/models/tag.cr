module Marten::DB::Model::QueryingSpec
  class Tag < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :name, :string, max_size: 255
    field :is_active, :bool, default: true
    field :defined_at, :date_time, auto_now_add: true

    scope :active { filter(is_active: true) }
    scope :recent { filter(defined_at__gt: 1.year.ago) }
  end
end
