module Marten::DB::Query::PrefetcherSpec
  class Pseudonym < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :author, :one_to_one, to: Marten::DB::Query::PrefetcherSpec::Author, related: :pseudonym
    field :name, :string, max_size: 255
  end
end
