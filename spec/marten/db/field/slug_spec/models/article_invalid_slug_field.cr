module Marten::DB::Field::SlugSpec
  class ArticleInvalidSlugField < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :title, :string, max_size: 255
    field :slug, :slug, slugify: :invalid, max_size: 100
  end
end
