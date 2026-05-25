module Marten::CLI::Manage::Command::GenMigrationsSpec
  class Tags < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :label, :string, max_size: 255, unique: true
    field :active, :bool, default: true
  end
end
