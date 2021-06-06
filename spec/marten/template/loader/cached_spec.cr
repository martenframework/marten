require "./spec_helper"

describe Marten::Template::Loader::Cached do
  describe "#get_template" do
    it "returns a parsed template for a given template name" do
      loader = Marten::Template::Loader::Cached.new(
        [
          Marten::Template::Loader::FileSystem.new("#{__DIR__}/templates"),
          Marten::Template::Loader::FileSystem.new("#{__DIR__}/other_templates"),
        ] of Marten::Template::Loader::Base
      )

      template_1 = loader.get_template("hello_world.html")
      template_1.should be_a Marten::Template::Template
      template_1.render(Marten::Template::Context{"name" => "John Doe"}).should eq "Hello world, John Doe!\n"

      template_2 = loader.get_template("foo_bar.html")
      template_2.should be_a Marten::Template::Template
      template_2.render(Marten::Template::Context.new).should eq "Foo Bar\n"
    end

    it "returns the same compiled template when the same template name is requested multiple times" do
      loader = Marten::Template::Loader::Cached.new(
        [
          Marten::Template::Loader::FileSystem.new("#{__DIR__}/templates"),
          Marten::Template::Loader::FileSystem.new("#{__DIR__}/other_templates"),
        ] of Marten::Template::Loader::Base
      )

      template_1 = loader.get_template("hello_world.html")
      template_1.should be_a Marten::Template::Template
      template_1.render(Marten::Template::Context{"name" => "John Doe"}).should eq "Hello world, John Doe!\n"

      template_2 = loader.get_template("hello_world.html")
      template_2.should be_a Marten::Template::Template
      template_2.render(Marten::Template::Context{"name" => "John Doe"}).should eq "Hello world, John Doe!\n"

      template_1.object_id.should eq template_2.object_id
    end

    it "raises a TemplateNotFound if the template cannot be found" do
      loader = Marten::Template::Loader::Cached.new(
        [
          Marten::Template::Loader::FileSystem.new("#{__DIR__}/templates"),
          Marten::Template::Loader::FileSystem.new("#{__DIR__}/other_templates"),
        ] of Marten::Template::Loader::Base
      )

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
      loader = Marten::Template::Loader::Cached.new(
        [
          Marten::Template::Loader::FileSystem.new("#{__DIR__}/templates"),
          Marten::Template::Loader::FileSystem.new("#{__DIR__}/other_templates"),
        ] of Marten::Template::Loader::Base
      )

      expect_raises(NotImplementedError) do
        loader.get_template_source("unknown.html")
      end
    end
  end
end
