require "./product"
require "./service"

module Marten::DB::Deletion::RunnerSpec
  class CascadeReview < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :text, :text
    field :target,
      :polymorphic,
      to: [Marten::DB::Deletion::RunnerSpec::Product, Marten::DB::Deletion::RunnerSpec::Service],
      related: :cascade_reviews,
      on_delete: :cascade
  end
end
