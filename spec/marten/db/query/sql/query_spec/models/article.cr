require "./person"

module Marten::DB::Query::SQL::QuerySpec
  class Article < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :title, :string, max_size: 255
    field :author, :many_to_one, to: Marten::DB::Query::SQL::QuerySpec::Person, related: :articles

    def __query_spec_author
      @author
    end
  end
end
