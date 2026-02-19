module Marten::DB::Field::PolymorphicSpec
  class Comment < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :text, :text
    field :target,
      :polymorphic,
      to: [Marten::DB::Field::PolymorphicSpec::Article, Marten::DB::Field::PolymorphicSpec::Recipe],
      related: :comments
  end
end
