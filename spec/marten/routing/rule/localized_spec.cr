require "./spec_helper"

describe Marten::Routing::Rule::Localized do
  describe "#name" do
    it "raises NotImplementedError" do
      rule = Marten::Routing::Rule::Localized.new

      expect_raises(NotImplementedError, "Localized rules don't provide names") do
        rule.name
      end
    end
  end

  describe "#resolve" do
    it "returns the expected match if the path starts with the current locale prefix and if the rule matches" do
      rule = Marten::Routing::Rule::LocalizedSpec::TestLocalizedRule.new
      rule.rules << Marten::Routing::Rule::Path.new(
        "/home/xyz/<sid:slug>/count/<number:int>/display",
        Marten::Handlers::Base,
        name: "home_xyz"
      )

      I18n.with_locale("en") do
        rule.resolve("/en/home/xyz/my-slug/count/42/display").should be_a Marten::Routing::Match
      end

      I18n.with_locale("fr") do
        rule.resolve("/fr/home/xyz/my-slug/count/42/display").should be_a Marten::Routing::Match
      end
    end

    it "returns the expected match when the default locale is not prefixed" do
      rule = Marten::Routing::Rule::LocalizedSpec::TestLocalizedRule.new(prefix_default_locale: false)

      rule.rules << Marten::Routing::Rule::Path.new(
        "/home/xyz/<sid:slug>/count/<number:int>/display",
        Marten::Handlers::Base,
        name: "home_xyz"
      )

      I18n.with_locale("en") do
        rule.resolve("/home/xyz/my-slug/count/42/display").should be_a Marten::Routing::Match
      end

      I18n.with_locale("fr") do
        rule.resolve("/fr/home/xyz/my-slug/count/42/display").should be_a Marten::Routing::Match
      end
    end

    it "returns nil if the path does not start with the current locale prefix" do
      rule = Marten::Routing::Rule::LocalizedSpec::TestLocalizedRule.new
      rule.rules << Marten::Routing::Rule::Path.new(
        "/home/xyz/<sid:slug>/count/<number:int>/display",
        Marten::Handlers::Base,
        name: "home_xyz"
      )

      I18n.with_locale("fr") do
        rule.resolve("/home/xyz/my-slug/count/42/display").should be_nil
        rule.resolve("/en/home/xyz/my-slug/count/42/display").should be_nil
      end
    end

    it "returns nil if the rule does not match" do
      rule = Marten::Routing::Rule::LocalizedSpec::TestLocalizedRule.new
      rule.rules << Marten::Routing::Rule::Path.new(
        "/home/xyz/<sid:slug>/count/<number:int>/display",
        Marten::Handlers::Base,
        name: "home_xyz"
      )

      I18n.with_locale("en") do
        rule.resolve("/en/home/xyz/my-slug/count/not-a-number/display").should be_nil
      end

      I18n.with_locale("fr") do
        rule.resolve("/fr/home/xyz/my-slug/count/not-a-number/display").should be_nil
      end
    end
  end

  describe "#reversers" do
    it "returns the expected reversers when the default locale is prefixed" do
      rule = Marten::Routing::Rule::LocalizedSpec::TestLocalizedRule.new(prefix_default_locale: true)

      rule.rules << Marten::Routing::Rule::Path.new(
        "/home/xyz/<sid:slug>/count/<number:int>/display",
        Marten::Handlers::Base,
        name: "home_xyz"
      )
      rule.rules << Marten::Routing::Rule::Path.new(
        "/other/path/<sid:slug>/count/<number:int>/display",
        Marten::Handlers::Base,
        name: "other_path"
      )

      reversers = rule.exposed_reversers

      reversers.size.should eq 2

      reversers[0].prefix_locales?.should be_true
      reversers[0].prefix_default_locale?.should be_true
      reversers[0].name.should eq "home_xyz"
      reversers[0].path_for_interpolation.should eq "/home/xyz/%{sid}/count/%{number}/display"
      reversers[0].parameters.size.should eq 2
      reversers[0].parameters["sid"].should be_a Marten::Routing::Parameter::Slug
      reversers[0].parameters["number"].should be_a Marten::Routing::Parameter::Integer

      reversers[1].prefix_locales?.should be_true
      reversers[1].prefix_default_locale?.should be_true
      reversers[1].name.should eq "other_path"
      reversers[1].path_for_interpolation.should eq "/other/path/%{sid}/count/%{number}/display"
      reversers[1].parameters.size.should eq 2
      reversers[1].parameters["sid"].should be_a Marten::Routing::Parameter::Slug
      reversers[1].parameters["number"].should be_a Marten::Routing::Parameter::Integer
    end

    it "returns the expected reversers when the default locale is not prefixed" do
      rule = Marten::Routing::Rule::LocalizedSpec::TestLocalizedRule.new(prefix_default_locale: false)

      rule.rules << Marten::Routing::Rule::Path.new(
        "/home/xyz/<sid:slug>/count/<number:int>/display",
        Marten::Handlers::Base,
        name: "home_xyz"
      )
      rule.rules << Marten::Routing::Rule::Path.new(
        "/other/path/<sid:slug>/count/<number:int>/display",
        Marten::Handlers::Base,
        name: "other_path"
      )

      reversers = rule.exposed_reversers

      reversers.size.should eq 2

      reversers[0].prefix_locales?.should be_true
      reversers[0].prefix_default_locale?.should be_false
      reversers[0].name.should eq "home_xyz"
      reversers[0].path_for_interpolation.should eq "/home/xyz/%{sid}/count/%{number}/display"
      reversers[0].parameters.size.should eq 2
      reversers[0].parameters["sid"].should be_a Marten::Routing::Parameter::Slug
      reversers[0].parameters["number"].should be_a Marten::Routing::Parameter::Integer

      reversers[1].prefix_locales?.should be_true
      reversers[1].prefix_default_locale?.should be_false
      reversers[1].name.should eq "other_path"
      reversers[1].path_for_interpolation.should eq "/other/path/%{sid}/count/%{number}/display"
      reversers[1].parameters.size.should eq 2
      reversers[1].parameters["sid"].should be_a Marten::Routing::Parameter::Slug
      reversers[1].parameters["number"].should be_a Marten::Routing::Parameter::Integer
    end
  end
end

module Marten::Routing::Rule::LocalizedSpec
  class TestLocalizedRule < Marten::Routing::Rule::Localized
    def exposed_reversers
      reversers
    end
  end
end
