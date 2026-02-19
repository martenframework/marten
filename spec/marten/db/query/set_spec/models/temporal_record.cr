module Marten::DB::Query::SetSpec
  class TemporalRecord < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :label, :string, max_size: 100
    field :event_date, :date
    field :event_at, :date_time
  end
end
