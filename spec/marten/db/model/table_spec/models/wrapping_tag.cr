module Marten::DB::Model::TableSpec
  class WrappingTag < Marten::Model
    field :tag, :one_to_one, to: Marten::DB::Model::TableSpec::Tag, primary_key: true
    field :details, :text
  end
end
