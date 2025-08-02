require "./spec_helper"

describe Marten do
  describe "#assets" do
    it "returns the assets engine" do
      Marten.assets.should be_a Marten::Asset::Engine
    end
  end

  describe "#cache" do
    it "returns the configured cache store" do
      Marten.cache.should eq Marten.settings.cache_store
    end
  end

  describe "#root" do
    it "returns the root path of the Marten project" do
      Marten.root.expand.should eq Path.new(__DIR__).join("..").expand
    end
  end

  describe "#routes" do
    it "returns the main routes map with the root flag set to true" do
      Marten.routes.should be_a Marten::Routing::Map
      Marten.routes.exposed_root?.should be_true
    end
  end

  describe "#setup" do
    context "with root path" do
      around_each do |t|
        FileUtils.rm("/tmp/marten_spec") if File.exists?("/tmp/marten_spec")

        with_overridden_setting("root_path", "/tmp/marten_spec", nilable: true) do
          t.run
        end

        FileUtils.rm("/tmp/marten_spec") if File.exists?("/tmp/marten_spec")
      end

      it "properly loads Marten built-in locales" do
        I18n.t("marten.db.field.base.errors.blank").should eq "This field cannot be blank."
      end
    end
  end

  describe "#setup_assets" do
    after_each do
      Marten.setup_assets
    end

    it "ensures custom asset dirs have priority over app dirs" do
      with_overridden_setting("assets.dirs", ["foo/bar"]) do
        with_overridden_setting("assets.app_dirs", true) do
          Marten.setup_assets
          Marten.assets.finders[0].should be_a Marten::Asset::Finder::FileSystem
          Marten.assets.finders[1].should be_a Marten::Asset::Finder::AppDirs
        end
      end
    end
  end

  describe "#setup_i18n" do
    it "properly configure I18n fallbacks" do
      with_overridden_setting("i18n.fallbacks", ["en", "fr"]) do
        Marten.setup_i18n
        I18n.config.fallbacks.not_nil!.default.should eq ["en", "fr"]
      end
    end
  end

  describe "#setup_templates" do
    after_each do
      Marten.setup_templates
    end

    it "uses no loaders when `templates.loaders` setting is empty array" do
      with_overridden_setting("templates.loaders", [] of Marten::Template::Loader::Base, nilable: true) do
        Marten.setup_templates
        Marten.templates.loaders.size.should eq 0
      end
    end

    it "uses the configured loaders" do
      file_system_loader = Marten::Template::Loader::FileSystem.new("/root/templates")
      with_overridden_setting(
        "templates.loaders",
        [file_system_loader] of Marten::Template::Loader::Base,
        nilable: true
      ) do
        Marten.setup_templates
        Marten.templates.loaders.size.should eq 1
        Marten.templates.loaders[0].should eq file_system_loader
      end
    end

    it "uses default loaders when the `templates.loaders` setting is set to nil" do
      with_overridden_setting("templates.loaders", nil, nilable: true) do
        Marten.setup_templates
        Marten.templates.loaders.size.should eq 2
      end
    end
  end

  describe "#start" do
    it "shows the build information when invoked with the -v flag" do
      result = MartenSpec.run_start_command(["-v"])

      result.should contain "Marten #{Marten::VERSION} [#{Marten.env.id}]"
    end
  end
end

module MartenSpec
  def self.run_start_command(options = [] of String)
    full_code = <<-CR
        require "./src/marten"

        ARGV.concat(#{options.inspect})
        Marten.start
      CR

    stdout = IO::Memory.new
    stderr = IO::Memory.new

    Process.run("crystal", ["eval", full_code], output: stdout, error: stderr)

    stdout.rewind.to_s
  end
end
