class Tag < Marten::DB::Model
  field :id, :auto, primary_key: true
  field :name, :string, blank: false, null: false, max_size: 64, unique: true
  field :is_active, :bool, null: false

  def self.default_queryset
    super.filter(is_active: true)
  end
end
