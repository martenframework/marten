require "./spec_helper"

describe Marten::CLI::Templates::App::Context do
  with_main_app_location "#{__DIR__}/context_spec/project"

  around_each do |t|
    Marten::CLI::Templates::App::ContextSpec.remove_project_dir
    Marten::CLI::Templates::App::ContextSpec.setup_project_dir

    t.run

    Marten::CLI::Templates::App::ContextSpec.remove_project_dir
  end

  describe "#app_class_name" do
    it "returns the expected value" do
      context_1 = Marten::CLI::Templates::App::Context.new(label: "blog")
      context_2 = Marten::CLI::Templates::App::Context.new(label: "test_app")

      context_1.app_class_name.should eq "Blog::App"
      context_2.app_class_name.should eq "TestApp::App"
    end
  end

  describe "#module_name" do
    it "returns the expected value" do
      context_1 = Marten::CLI::Templates::App::Context.new(label: "blog")
      context_2 = Marten::CLI::Templates::App::Context.new(label: "test_app")

      context_1.module_name.should eq "Blog"
      context_2.module_name.should eq "TestApp"
    end
  end
end

module Marten::CLI::Templates::App::ContextSpec
  def self.remove_project_dir
    FileUtils.rm_rf("#{__DIR__}/context_spec/project/")
  end

  def self.setup_project_dir
    FileUtils.mkdir_p("#{__DIR__}/context_spec/project/")
  end
end
