require "./spec_helper"

describe Marten::Routing::Path::Spec::Static do
  describe "#parameters" do
    it "returns the path specification parameters" do
      spec = Marten::Routing::Path::Spec::Static.new(
        /^\/test\/(?<param1>\d+)\/xyz\/(?<param2>\d+)$/,
        "/test/%{param1}/xyz/%{param2}",
        {
          "param1" => Marten::Routing::Parameter.registry["int"],
          "param2" => Marten::Routing::Parameter.registry["int"],
        }
      )

      spec.parameters.should eq(
        {
          "param1" => Marten::Routing::Parameter.registry["int"],
          "param2" => Marten::Routing::Parameter.registry["int"],
        }
      )
    end
  end

  describe "#path_for_interpolation" do
    it "returns the path for interpolation" do
      spec = Marten::Routing::Path::Spec::Static.new(
        /^\/test\/(?<param1>\d+)\/xyz\/(?<param2>\d+)$/,
        "/test/%{param1}/xyz/%{param2}",
        {
          "param1" => Marten::Routing::Parameter.registry["int"],
          "param2" => Marten::Routing::Parameter.registry["int"],
        }
      )

      spec.path_for_interpolation.should eq("/test/%{param1}/xyz/%{param2}")
    end
  end

  describe "#regex" do
    it "returns the path specification regex" do
      spec = Marten::Routing::Path::Spec::Static.new(
        /^\/test\/(?<param1>\d+)\/xyz\/(?<param2>\d+)$/,
        "/test/%{param1}/xyz/%{param2}",
        {
          "param1" => Marten::Routing::Parameter.registry["int"],
          "param2" => Marten::Routing::Parameter.registry["int"],
        }
      )

      spec.regex.should eq(/^\/test\/(?<param1>\d+)\/xyz\/(?<param2>\d+)$/)
    end
  end

  describe "#resolve" do
    it "returns the expected match if the path matches a specification without parameters" do
      spec = Marten::Routing::Path::Spec::Static.new(
        /^\/foo\/bar$/,
        "/foo/bar",
        {} of String => Marten::Routing::Parameter::Base
      )

      match = spec.resolve("/foo/bar")

      match.should be_a(Marten::Routing::Path::Match)
      match.try(&.end_index).should eq(8)
      match.try(&.parameters).should eq(Marten::Routing::MatchParameters.new)
    end

    it "returns the expected match if the path matches a specification with parameters" do
      spec = Marten::Routing::Path::Spec::Static.new(
        /^\/test\/(?<param1>\d+)\/xyz\/(?<param2>\d+)$/,
        "/test/%{param1}/xyz/%{param2}",
        {
          "param1" => Marten::Routing::Parameter.registry["int"],
          "param2" => Marten::Routing::Parameter.registry["int"],
        }
      )

      match = spec.resolve("/test/123/xyz/456")

      match.should be_a(Marten::Routing::Path::Match)
      match.try(&.end_index).should eq(17)
      match.try(&.parameters).should eq(
        {
          "param1" => 123,
          "param2" => 456,
        }
      )
    end

    it "returns nil if the path does not match a specification without parameters" do
      spec = Marten::Routing::Path::Spec::Static.new(
        /^\/foo\/bar$/,
        "/foo/bar",
        {} of String => Marten::Routing::Parameter::Base
      )

      spec.resolve("/bad").should be_nil
    end

    it "returns nil if the path does not match a specification with parameters because the path does not match" do
      spec = Marten::Routing::Path::Spec::Static.new(
        /^\/test\/(?<param1>\d+)\/xyz\/(?<param2>\d+)$/,
        "/test/%{param1}/xyz/%{param2}",
        {
          "param1" => Marten::Routing::Parameter.registry["int"],
          "param2" => Marten::Routing::Parameter.registry["int"],
        }
      )

      spec.resolve("/bad/123/xyz/456").should be_nil
    end

    it "returns nil if the path does not match a specification with parameters because the parameters do not match" do
      spec = Marten::Routing::Path::Spec::Static.new(
        /^\/test\/(?<param1>\d+)\/xyz\/(?<param2>\d+)$/,
        "/test/%{param1}/xyz/%{param2}",
        {
          "param1" => Marten::Routing::Parameter.registry["int"],
          "param2" => Marten::Routing::Parameter.registry["int"],
        }
      )

      spec.resolve("/test/notanumber/xyz/4567").should be_nil
    end
  end

  describe "#reverser" do
    it "returns the expected reverser" do
      spec = Marten::Routing::Path::Spec::Static.new(
        /^\/test\/(?<param1>\d+)\/xyz\/(?<param2>\d+)$/,
        "/test/%{param1}/xyz/%{param2}",
        {
          "param1" => Marten::Routing::Parameter.registry["int"],
          "param2" => Marten::Routing::Parameter.registry["int"],
        }
      )

      reverser = spec.reverser("route:name")
      reverser.should be_a(Marten::Routing::Reverser)
      reverser.name.should eq("route:name")
      reverser.path_for_interpolation.should eq("/test/%{param1}/xyz/%{param2}")
      reverser.exposed_path_for_interpolations.should eq(
        {
          nil => "/test/%{param1}/xyz/%{param2}",
        } of String? => String
      )
      reverser.parameters.should eq(
        {
          "param1" => Marten::Routing::Parameter.registry["int"],
          "param2" => Marten::Routing::Parameter.registry["int"],
        }
      )
    end
  end
end
