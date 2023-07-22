module Marten::DB::Field::ManyToManySpec
  class Article < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :title, :string, max_size: 255
    field :tags, :many_to_many, to: Marten::DB::Field::ManyToManySpec::Tag, related: :articles
  end
end
