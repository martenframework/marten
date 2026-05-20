require "./student"

module Marten::DB::Deletion::RunnerSpec
  class AltStudent < Student
    field :alt_grade, :string, max_size: 15
    field :alt_address, :many_to_one, to: Marten::DB::Deletion::RunnerSpec::AltAddress, null: true, blank: true,
      on_delete: :cascade
  end
end
