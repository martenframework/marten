module Marten::DB::Query::SQL::QuerySpec
  class StudentProfile < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :student, :one_to_one, to: Marten::DB::Query::SQL::QuerySpec::Student, related: :student_profile
    field :bio, :text, blank: true, null: true

    def __query_spec_student
      @student
    end
  end
end
