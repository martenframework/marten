require "./student"

module Marten::DB::Model::TableSpec
  class AltStudent < Student
    field :alt_grade, :string, max_size: 15
  end
end
