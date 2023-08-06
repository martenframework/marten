module Marten::DB::Query::SetSpec
  class Person < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :name, :string, max_size: 255
    field :email, :string, max_size: 255
    field :address, :many_to_one, to: Marten::DB::Query::SetSpec::Address
  end
end
