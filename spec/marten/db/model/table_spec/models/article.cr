require "./base_article"

module Marten::DB::Model::TableSpec
  class Article < BaseArticle
    field :additional_content, :text

    db_index :other_author_title_index, field_names: [:author, :title]
    db_unique_constraint :other_author_title_constraint, field_names: [:author, :title]
  end
end
