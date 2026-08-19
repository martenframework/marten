require "./product"
require "./service"

module Marten::DB::Deletion::RunnerSpec
  class DoNothingReview < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :text, :text
    field :target,
      :polymorphic,
      to: [Marten::DB::Deletion::RunnerSpec::Product, Marten::DB::Deletion::RunnerSpec::Service],
      related: :do_nothing_reviews
  end
end
