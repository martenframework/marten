module Marten::DB::Query::PrefetcherSpec
  class Author < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :name, :string, max_size: 255
    field :publisher, :many_to_one, to: Marten::DB::Query::PrefetcherSpec::Publisher, related: :authors,
      blank: true, null: true
    field :country, :many_to_one, to: Marten::DB::Query::PrefetcherSpec::Country, related: :authors,
      blank: true, null: true
    field :bio, :one_to_one, to: Marten::DB::Query::PrefetcherSpec::Bio, related: :author,
      blank: true, null: true
    field :signature, :one_to_one, to: Marten::DB::Query::PrefetcherSpec::Signature, related: :author,
      blank: true, null: true
    field :book_genres, :many_to_many, to: Marten::DB::Query::PrefetcherSpec::BookGenre, related: :authors
    field :awards, :many_to_many, to: Marten::DB::Query::PrefetcherSpec::Award, related: :authors
  end
end
