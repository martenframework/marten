module Marten::DB::Query::SQL::QuerySpec
  class PersonProfile < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :person, :one_to_one, to: Marten::DB::Query::SQL::QuerySpec::Person, related: :person_profile
    field :bio, :text, blank: true, null: true
  end
end
