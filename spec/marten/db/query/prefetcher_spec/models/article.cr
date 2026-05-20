module Marten::DB::Query::PrefetcherSpec
  class Article < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :title, :string, max_size: 255
    field :text, :text
  end
end
