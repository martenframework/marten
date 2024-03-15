module Marten::DB::Query::PrefetcherSpec
  class Publisher < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :name, :string, max_size: 255
    field :country, :many_to_one, to: Marten::DB::Query::PrefetcherSpec::Country, related: :publishers,
      blank: true, null: true
    field :book_genres, :many_to_many, to: Marten::DB::Query::PrefetcherSpec::BookGenre, related: :publishers
  end
end
