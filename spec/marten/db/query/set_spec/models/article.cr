require "./person"

module Marten::DB::Query::SetSpec
  class Article < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :title, :string, max_size: 255
    field :author, :many_to_one, to: Marten::DB::Query::SetSpec::Person, related: :articles
    field :subtitle, :string, max_size: 150, blank: true, null: true
  end
end
