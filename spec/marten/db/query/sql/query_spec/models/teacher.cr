require "./person"

module Marten::DB::Query::SQL::QuerySpec
  class Teacher < Person
    field :subject, :string, max_size: 15
  end
end
