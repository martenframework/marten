module Marten::DB::Field::SlugSpec
  class ArticleWithCustomSlugGenerator < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :title, :string, max_size: 255
    field :slug, :slug, slugify: :title, slugify_cb: ->(value : ::String) { custom_slug_generator(value) }
  end
end

def custom_slug_generator(value : String) : String
  # Custom slug generation logic here
  value.upcase.gsub(" ", "_")
end
