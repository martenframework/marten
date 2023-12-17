module Marten::DB::Query::SetSpec
  class StudentProfile < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :student, :one_to_one, to: Marten::DB::Query::SetSpec::Student, related: :student_profile
    field :bio, :text, blank: true, null: true
  end
end
