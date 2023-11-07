require "./spec_helper"

describe Marten::CLI::Generator::App::Templates do
  describe "::app_files" do
    it "returns the expected array of files" do
      context = Marten::CLI::Generator::App::Context.new(
        main_app_config: Marten.apps.default,
        label: "blog",
      )

      templates = Marten::CLI::Generator::App::Templates.app_files(context)

      templates.map(&.first).should eq(
        [
          "blog/app.cr",
          "blog/cli.cr",
          "blog/routes.cr",
          "blog/emails/.gitkeep",
          "blog/handlers/.gitkeep",
          "blog/migrations/.gitkeep",
          "blog/models/.gitkeep",
          "blog/schemas/.gitkeep",
          "blog/templates/.gitkeep",
        ]
      )
    end

    it "returns the expected array of files if the main app contains the app/ folder" do
      context = Marten::CLI::Generator::App::TemplatesSpec::ContextWithAppFolder.new(
        main_app_config: Marten.apps.default,
        label: "blog",
      )

      templates = Marten::CLI::Generator::App::Templates.app_files(context)

      templates.map(&.first).should eq(
        [
          "apps/blog/app.cr",
          "apps/blog/cli.cr",
          "apps/blog/routes.cr",
          "apps/blog/emails/.gitkeep",
          "apps/blog/handlers/.gitkeep",
          "apps/blog/migrations/.gitkeep",
          "apps/blog/models/.gitkeep",
          "apps/blog/schemas/.gitkeep",
          "apps/blog/templates/.gitkeep",
        ]
      )
    end
  end
end

module Marten::CLI::Generator::App::TemplatesSpec
  class ContextWithAppFolder < Marten::CLI::Generator::App::Context
    def located_in_apps_folder?
      true
    end
  end
end
