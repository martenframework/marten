module Marten::DB::Model::QueryingSpec
  class Author < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :name, :string, max_size: 255
    field :is_admin, :bool, default: false

    scope :admins { filter(is_admin: true) }
  end
end
