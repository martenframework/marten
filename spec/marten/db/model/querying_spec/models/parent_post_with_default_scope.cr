module Marten::DB::Model::QueryingSpec
  class ParentPostWithDefaultScope < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :title, :string, max_size: 255
    field :content, :text
    field :published, :bool, default: false
    field :created_at, :date_time, auto_now_add: true

    default_scope { filter(published: true) }
  end
end
