module Marten::DB::Model::TableSpec
  abstract class AbstractModelWithoutPrimaryKey < Marten::Model
    field :title, :string, max_size: 255
  end
end
