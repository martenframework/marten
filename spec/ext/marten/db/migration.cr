abstract class Marten::DB::Migration
  def self.reset_app_config
    @@app_config = nil
  end
end
