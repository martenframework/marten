require "./spec_helper"

describe Marten::CLI::Generator::App::Context do
  with_main_app_location "#{__DIR__}/context_spec/project"

  around_each do |t|
    Marten::CLI::Generator::App::ContextSpec.remove_project_dir
    Marten::CLI::Generator::App::ContextSpec.setup_project_dir

    t.run

    Marten::CLI::Generator::App::ContextSpec.remove_project_dir
  end

  describe "#app_class_name" do
    it "returns the expected value" do
      context_1 = Marten::CLI::Generator::App::Context.new(
        main_app_config: Marten.apps.main,
        label: "blog",
      )
      context_2 = Marten::CLI::Generator::App::Context.new(
        main_app_config: Marten.apps.main,
        label: "test_app",
      )

      context_1.app_class_name.should eq "Blog::App"
      context_2.app_class_name.should eq "TestApp::App"
    end
  end

  describe "#located_in_apps_folder?" do
    it "returns true if the apps folder exists" do
      FileUtils.mkdir_p("#{__DIR__}/context_spec/project/apps")

      context = Marten::CLI::Generator::App::Context.new(
        main_app_config: Marten.apps.main,
        label: "blog",
      )

      context.located_in_apps_folder?.should be_true
    end

    it "returns false if the apps folder does not exist" do
      context = Marten::CLI::Generator::App::Context.new(
        main_app_config: Marten.apps.main,
        label: "blog",
      )

      context.located_in_apps_folder?.should be_false
    end
  end

  describe "#module_name" do
    it "returns the expected value" do
      context_1 = Marten::CLI::Generator::App::Context.new(
        main_app_config: Marten.apps.main,
        label: "blog",
      )
      context_2 = Marten::CLI::Generator::App::Context.new(
        main_app_config: Marten.apps.main,
        label: "test_app",
      )

      context_1.module_name.should eq "Blog"
      context_2.module_name.should eq "TestApp"
    end
  end
end

module Marten::CLI::Generator::App::ContextSpec
  def self.remove_project_dir
    FileUtils.rm_rf("#{__DIR__}/context_spec/project/")
  end

  def self.setup_project_dir
    FileUtils.mkdir_p("#{__DIR__}/context_spec/project/")
  end
end
