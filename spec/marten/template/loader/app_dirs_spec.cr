require "./spec_helper"

describe Marten::Template::Loader::AppDirs do
  describe "#get_template" do
    it "returns a parsed template for a given template name" do
      loader = Marten::Template::Loader::AppDirs.new

      template = loader.get_template("specs/template/loader/app_dirs/test.html")
      template.should be_a Marten::Template::Template
      template.render(Marten::Template::Context{"name" => "John Doe"}).should eq "Hello World, John Doe!\n"
    end

    it "raises a TemplateNotFound error if the template cannot be found" do
      loader = Marten::Template::Loader::AppDirs.new

      expect_raises(
        Marten::Template::Errors::TemplateNotFound,
        "Template unknown.html could not be found"
      ) do
        loader.get_template("unknown.html")
      end
    end
  end

  describe "#get_template_source" do
    it "is explicitly not implemented" do
      loader = Marten::Template::Loader::AppDirs.new

      expect_raises(NotImplementedError) do
        loader.get_template_source("unknown.html")
      end
    end
  end
end
