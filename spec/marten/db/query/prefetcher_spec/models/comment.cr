module Marten::DB::Query::PrefetcherSpec
  class Comment < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :text, :text
    field :target,
      :polymorphic,
      to: [Marten::DB::Query::PrefetcherSpec::Article, Marten::DB::Query::PrefetcherSpec::Recipe],
      related: :comments
  end
end
