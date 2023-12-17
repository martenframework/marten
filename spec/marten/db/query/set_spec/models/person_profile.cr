module Marten::DB::Query::SetSpec
  class PersonProfile < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :person, :one_to_one, to: Marten::DB::Query::SetSpec::Person, related: :person_profile
    field :bio, :text, blank: true, null: true
  end
end
