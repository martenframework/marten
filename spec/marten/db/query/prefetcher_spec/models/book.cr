module Marten::DB::Query::PrefetcherSpec
  class Book < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :title, :string, max_size: 255
    field :authors, :many_to_many, to: Marten::DB::Query::PrefetcherSpec::Author, related: :books
    field :scoped_authors, :many_to_many, to: Marten::DB::Query::PrefetcherSpec::ScopedAuthor
  end
end
