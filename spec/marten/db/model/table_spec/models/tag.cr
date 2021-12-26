module Marten::DB::Model::TableSpec
  class Tag < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :name, :string, blank: false, null: false, max_size: 64, unique: true
  end
end
