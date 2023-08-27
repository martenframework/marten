class Marten::Apps::MainConfig
  @@overridden_location : String?

  class_setter overridden_location

  def self._marten_app_location
    default_location = {{ run("../../../../src/marten/apps/main_config/fetch_src_path.cr") }}
    @@overridden_location || default_location
  end
end
