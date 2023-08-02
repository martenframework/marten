require "./student"

module Marten::DB::Query::SQL::RowIteratorSpec
  class AltStudent < Student
    field :alt_grade, :string, max_size: 15
  end
end
