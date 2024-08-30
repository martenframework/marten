module Marten::DB::Query::PrefetcherSpec
  class ScopedAuthor < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :name, :string, max_size: 255

    default_scope { filter(name__isnull: true) }
  end
end
