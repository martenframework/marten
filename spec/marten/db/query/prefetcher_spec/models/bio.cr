module Marten::DB::Query::PrefetcherSpec
  class Bio < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :content, :text
  end
end
