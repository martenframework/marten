require "./spec_helper"

describe Marten::Routing::Path::Spec::Translated do
  describe "#resolve" do
    it "returns the expected match if the path matches the spec for the current locale" do
      spec = Marten::Routing::Path::Spec::Translated.new(
        Marten::Routing::TranslatedPath.new("routes.foo_bar_with_args"),
        nil,
      )

      match = spec.resolve("/foo/123/bar/abc")

      match.should be_a(Marten::Routing::Path::Match)
      match.try(&.end_index).should eq(16)
      match.try(&.parameters).should eq(
        {
          "param1" => 123,
          "param2" => "abc",
        }
      )
    end

    it "returns the expected match if the translated path matches the spec for a non-default locale" do
      spec = Marten::Routing::Path::Spec::Translated.new(
        Marten::Routing::TranslatedPath.new("routes.foo_bar"),
        nil,
      )

      match = I18n.with_locale("fr") { spec.resolve("/foo-french/bar-french") }

      match.should be_a(Marten::Routing::Path::Match)
      match.try(&.end_index).should eq(22)
      match.try(&.parameters).should eq(Marten::Routing::MatchParameters.new)
    end

    it "returns the expected match if the path matches the default locale path when no translation exists" do
      spec = Marten::Routing::Path::Spec::Translated.new(
        Marten::Routing::TranslatedPath.new("routes.foo_bar_with_args"),
        nil,
      )

      match = I18n.with_locale("fr") { spec.resolve("/foo/123/bar/abc") }

      match.should be_a(Marten::Routing::Path::Match)
      match.try(&.end_index).should eq(16)
      match.try(&.parameters).should eq(
        {
          "param1" => 123,
          "param2" => "abc",
        }
      )
    end

    it "returns the expected match if the path matches the spec for the current locale when a regex suffix is used" do
      spec = Marten::Routing::Path::Spec::Translated.new(
        Marten::Routing::TranslatedPath.new("routes.foo_bar_with_args"),
        "/suffix/test",
      )

      match = spec.resolve("/foo/123/bar/abc/suffix/test")

      match.should be_a(Marten::Routing::Path::Match)
      match.try(&.end_index).should eq(28)
      match.try(&.parameters).should eq(
        {
          "param1" => 123,
          "param2" => "abc",
        }
      )
    end

    it "returns nil if the the path does not match the spec for the current locale" do
      spec = Marten::Routing::Path::Spec::Translated.new(
        Marten::Routing::TranslatedPath.new("routes.foo_bar_with_args"),
        nil,
      )

      spec.resolve("/unknown/foo/123/bar/xyz").should be_nil
    end

    it "returns nil if the the path does not match the spec for a non-default locale" do
      spec = Marten::Routing::Path::Spec::Translated.new(
        Marten::Routing::TranslatedPath.new("routes.foo_bar"),
        nil,
      )

      I18n.with_locale("fr") { spec.resolve("/unknown/foo-french/bar-french") }.should be_nil
    end
  end

  describe "#reverser" do
    it "returns the expected reverser for a path without parameters" do
      spec = Marten::Routing::Path::Spec::Translated.new(
        Marten::Routing::TranslatedPath.new("routes.foo_bar"),
        nil,
      )

      reverser = spec.reverser("route:name")
      reverser.should be_a(Marten::Routing::Reverser)
      reverser.name.should eq("route:name")
      reverser.exposed_path_for_interpolations.should eq(
        {
          nil  => "/foo/bar",
          "en" => "/foo/bar",
          "fr" => "/foo-french/bar-french",
          "es" => "/foo/bar",
        } of String? => String
      )
      reverser.parameters.should eq(Marten::Routing::MatchParameters.new)
    end

    it "returns the expected reverser for a path with parameters" do
      spec = Marten::Routing::Path::Spec::Translated.new(
        Marten::Routing::TranslatedPath.new("routes.foo_bar_with_args"),
        nil,
      )

      reverser = spec.reverser("route:name")
      reverser.should be_a(Marten::Routing::Reverser)
      reverser.name.should eq("route:name")
      reverser.exposed_path_for_interpolations.should eq(
        {
          nil  => "/foo/%{param1}/bar/%{param2}",
          "en" => "/foo/%{param1}/bar/%{param2}",
          "fr" => "/foo/%{param1}/bar/%{param2}",
          "es" => "/foo/%{param1}/bar/%{param2}",
        } of String? => String
      )
      reverser.parameters.should eq(
        {
          "param1" => Marten::Routing::Parameter.registry["int"],
          "param2" => Marten::Routing::Parameter.registry["string"],
        }
      )
    end

    it "raises if no translation can be found for the default locale" do
      spec = Marten::Routing::Path::Spec::Translated.new(
        Marten::Routing::TranslatedPath.new("routes.foo_bar_unknown"),
        nil,
      )

      expect_raises(
        Marten::Routing::Errors::InvalidRulePath,
        "No default locale translation found for route associated with 'routes.foo_bar_unknown' translation key"
      ) do
        spec.reverser("route:name")
      end
    end
  end
end
