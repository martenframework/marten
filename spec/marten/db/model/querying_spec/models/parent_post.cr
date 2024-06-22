module Marten::DB::Model::QueryingSpec
  class ParentPost < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :title, :string, max_size: 255
    field :content, :text
    field :published, :bool, default: false
    field :published_at, :date_time, blank: true, null: true
    field :created_at, :date_time, auto_now_add: true

    scope :published { filter(published: true) }
    scope :recent { filter(published_at__gt: 1.year.ago) }
  end
end
