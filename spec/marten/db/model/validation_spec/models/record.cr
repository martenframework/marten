module Marten::DB::Model::ValidationSpec
  class Record < Marten::Model
    property? before_validation_errors_presence = false

    field :id, :big_int, primary_key: true, auto: true
    field :name, :string, blank: false, null: false, max_size: 64, unique: true
    field :is_active, :bool, null: false

    before_validation :set_before_validation_errors_presence
    validate :validate_crystal_is_active

    def set_before_validation_errors_presence
      self.before_validation_errors_presence = !errors.empty?
    end

    private def validate_crystal_is_active
      errors.add("The record must be active") if name == "must_be_active" && !is_active
    end
  end
end
