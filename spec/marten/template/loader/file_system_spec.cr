require "./spec_helper"

describe Marten::Template::Loader::FileSystem do
  around_each do |t|
    original_debug = Marten.settings.debug

    t.run

    Marten.settings.debug = original_debug
  end

  describe "#path" do
    it "returns the associated path" do
      loader = Marten::Template::Loader::FileSystem.new("#{__DIR__}/templates")
      loader.path.should eq "#{__DIR__}/templates"
    end
  end

  describe "#get_template_source" do
    it "returns the source for a given template name" do
      loader = Marten::Template::Loader::FileSystem.new("#{__DIR__}/templates")
      loader.get_template_source("hello_world.html").should eq File.read("#{__DIR__}/templates/hello_world.html")
    end

    it "returns the source for a given template name in a subfolder" do
      loader = Marten::Template::Loader::FileSystem.new("#{__DIR__}/templates")
      loader.get_template_source("subfolder/hello_world.html").should eq(
        File.read("#{__DIR__}/templates/subfolder/hello_world.html")
      )
    end

    it "raises a TemplateNotFound error if the given template name does not exist" do
      loader = Marten::Template::Loader::FileSystem.new("#{__DIR__}/templates")
      expect_raises(
        Marten::Template::Errors::TemplateNotFound,
        "Template unknown.html could not be found"
      ) do
        loader.get_template_source("unknown.html")
      end
    end

    it "raises a TemplateNotFound error if the given template name cannot be read" do
      loader = Marten::Template::Loader::FileSystem.new("#{__DIR__}/templates")
      expect_raises(
        Marten::Template::Errors::TemplateNotFound,
        "Template subfolder could not be found"
      ) do
        loader.get_template_source("subfolder")
      end
    end
  end

  describe "#get_template" do
    it "returns a parsed template for a given template name" do
      loader = Marten::Template::Loader::FileSystem.new("#{__DIR__}/templates")
      template = loader.get_template("hello_world.html")

      template.should be_a Marten::Template::Template
      template.render(Marten::Template::Context{"name" => "John Doe"}).should eq "Hello world, John Doe!\n"
    end

    it "raises as expected and associated the filepath of the template to invalid syntax errors in debug mode" do
      Marten.settings.debug = true

      loader = Marten::Template::Loader::FileSystem.new("#{__DIR__}/templates")

      error = expect_raises(Marten::Template::Errors::InvalidSyntax) do
        loader.get_template("invalid_syntax.html")
      end

      error.filepath.should eq "#{__DIR__}/templates/invalid_syntax.html"
    end

    it "raises as expected and does not associated the filepath to invalid syntax errors when not in debug mode" do
      loader = Marten::Template::Loader::FileSystem.new("#{__DIR__}/templates")

      error = expect_raises(Marten::Template::Errors::InvalidSyntax) do
        loader.get_template("invalid_syntax.html")
      end

      error.filepath.should be_nil
    end
  end
end
