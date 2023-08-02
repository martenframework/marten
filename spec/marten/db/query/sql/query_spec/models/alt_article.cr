require "./alt_student"

module Marten::DB::Query::SQL::QuerySpec
  class AltArticle < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :title, :string, max_size: 255
    field :author, :many_to_one, to: Marten::DB::Query::SQL::QuerySpec::AltStudent, related: :alt_articles
  end
end
