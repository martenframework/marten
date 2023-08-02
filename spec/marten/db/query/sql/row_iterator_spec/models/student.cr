require "./person"

module Marten::DB::Query::SQL::RowIteratorSpec
  class Student < Person
    field :grade, :string, max_size: 15
  end
end
