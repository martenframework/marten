module Marten::DB::Model::TableSpec
  abstract class BaseArticle < Marten::Model
    with_timestamp_fields

    field :id, :big_int, primary_key: true, auto: true
    field :author, :many_to_one, to: Marten::DB::Model::TableSpec::Author, related: :articles, on_delete: :cascade
    field(
      :moderator,
      :one_to_one,
      to: Marten::DB::Model::TableSpec::Author,
      related: :moderated_article,
      on_delete: :cascade
    )
    field :title, :string, max_size: 255
    field :content, :text

    field :tags, :many_to_many, to: Marten::DB::Model::TableSpec::Tag, related: :articles

    db_index :base_author_title_index, field_names: [:author, :title]
    db_unique_constraint :base_author_title_constraint, field_names: [:author, :title]
  end
end
