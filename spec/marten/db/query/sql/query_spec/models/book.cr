require "./person"

module Marten::DB::Query::SQL::QuerySpec
  class Book < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :title, :string, max_size: 255
    field :authors, :many_to_many, to: Marten::DB::Query::SQL::QuerySpec::Person, related: :books
  end
end
