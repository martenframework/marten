module Marten::DB::Field::ManyToManySpec
  class TreeNode < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :label, :string, max_size: 255
    field :children, :many_to_many, to: self, related: :parents
  end
end
