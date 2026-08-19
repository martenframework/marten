require "./cascade_review"

module Marten::DB::Deletion::RunnerSpec
  class ReviewAttachment < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :name, :string, max_size: 255
    field :review, :many_to_one, to: Marten::DB::Deletion::RunnerSpec::CascadeReview, on_delete: :cascade
  end
end
