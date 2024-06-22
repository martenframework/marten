module Marten::DB::Model::QueryingSpec
  class Post < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :author, :many_to_one, to: Marten::DB::Model::QueryingSpec::Author, blank: true, null: true, related: :posts
    field :title, :string, max_size: 255
    field :content, :text
    field :published, :bool, default: false
    field :published_at, :date_time, blank: true, null: true
    field :tags, :many_to_many, to: Marten::DB::Model::QueryingSpec::Tag
    field :created_at, :date_time, auto_now_add: true

    scope :published { filter(published: true) }
    scope :recent { filter(published_at__gt: 1.year.ago) }
    scope :prefixed { |prefix| filter(title__istartswith: prefix) }
  end
end
