module Marten::DB::Field::PolymorphicSpec
  class ArticleWithStringPk < Marten::Model
    field :id, :string, primary_key: true, max_size: 255
    field :title, :string, max_size: 255
  end
end
