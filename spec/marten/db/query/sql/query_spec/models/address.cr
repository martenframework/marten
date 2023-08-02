module Marten::DB::Query::SQL::QuerySpec
  class Address < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :street, :string, max_size: 100
  end
end
