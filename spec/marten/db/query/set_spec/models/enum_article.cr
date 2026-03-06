module Marten::DB::Query::SetSpec
  class EnumArticle < Marten::Model
    enum Category
      NEWS
      BLOG
    end

    field :id, :big_int, primary_key: true, auto: true
    field :title, :string, max_size: 255
    field :category, :enum, values: Category
  end
end
