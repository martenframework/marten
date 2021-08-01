class Tag < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :name, :string, blank: false, null: false, max_size: 64, unique: true
  field :is_active, :bool, null: false

  validate :validate_crystal_is_active

  def self.default_queryset
    super.filter(is_active: true)
  end

  private def validate_crystal_is_active
    errors.add("The tag must be active") if name == "must_be_active" && !is_active
  end
end
