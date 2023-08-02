require "./student"

module Marten::DB::Model::PersistenceSpec
  class AltStudent < Student
    field :alt_grade, :string, max_size: 15
  end
end
