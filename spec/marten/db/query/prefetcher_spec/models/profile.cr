module Marten::DB::Query::PrefetcherSpec
  class Profile < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :author, :one_to_one, to: Marten::DB::Query::PrefetcherSpec::Author, related: :profile
    field :name, :string, max_size: 255
  end
end
