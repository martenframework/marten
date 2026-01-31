require "./article_with_string_pk"
require "./recipe_with_string_pk"

module Marten::DB::Field::PolymorphicSpec
  class AltComment < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :text, :text
    field :target,
      :polymorphic,
      to: [ArticleWithStringPk, RecipeWithStringPk],
      blank: false,
      null: false,
      unique: true,
      index: true
  end
end
