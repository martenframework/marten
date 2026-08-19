require "./product"
require "./service"

module Marten::DB::Deletion::RunnerSpec
  class ProtectReview < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :text, :text
    field :target,
      :polymorphic,
      to: [Marten::DB::Deletion::RunnerSpec::Product, Marten::DB::Deletion::RunnerSpec::Service],
      related: :protect_reviews,
      on_delete: :protect
  end
end
