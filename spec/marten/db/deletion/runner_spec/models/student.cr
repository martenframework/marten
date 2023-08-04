require "./person"

module Marten::DB::Deletion::RunnerSpec
  class Student < Person
    field :grade, :string, max_size: 15
  end
end
