require "./person"

module Marten::DB::Model::PersistenceSpec
  class Student < Person
    field :grade, :string, max_size: 15
  end
end
