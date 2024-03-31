module Marten::DB::Query::PrefetcherSpec
  class Conference < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :name, :string, max_size: 255
    field :author, :many_to_one, to: Marten::DB::Query::PrefetcherSpec::Author, related: :conferences,
      blank: true, null: true
    field :publisher, :many_to_one, to: Marten::DB::Query::PrefetcherSpec::Publisher, related: :conferences,
      blank: true, null: true
  end
end
