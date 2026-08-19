require "./product"
require "./service"

module Marten::DB::Deletion::RunnerSpec
  class SetNullReview < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :text, :text
    field :target,
      :polymorphic,
      to: [Marten::DB::Deletion::RunnerSpec::Product, Marten::DB::Deletion::RunnerSpec::Service],
      related: :set_null_reviews,
      null: true,
      blank: true,
      on_delete: :set_null
  end
end
