module Marten::DB::Query::SQL::RowIteratorSpec
  class Person < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :name, :string, max_size: 255
    field :email, :string, max_size: 255
  end
end
