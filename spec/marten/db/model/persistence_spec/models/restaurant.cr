module Marten::DB::Model::PersistenceSpec
  class Restaurant < Place
    field :serves_hot_dogs, :bool, default: false
    field :serves_pizza, :bool, default: false
  end
end
