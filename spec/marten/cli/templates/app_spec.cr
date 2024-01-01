require "./spec_helper"

describe Marten::CLI::Templates::App do
  describe "#app_files" do
    it "returns the expected files for the given app context" do
      app_context = Marten::CLI::Templates::App::Context.new("my_auth")
      files = Marten::CLI::Templates::App.app_files(app_context)

      files.map(&.first).should eq(
        [
          "app.cr",
          "cli.cr",
          "routes.cr",
          "emails/.gitkeep",
          "handlers/.gitkeep",
          "migrations/.gitkeep",
          "models/.gitkeep",
          "schemas/.gitkeep",
          "templates/.gitkeep",
        ]
      )
    end
  end
end
