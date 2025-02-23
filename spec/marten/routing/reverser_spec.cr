require "./spec_helper"

describe Marten::Routing::Reverser do
  describe "#combine" do
    it "returns the expected reverser when the current reverser has no name" do
      reverser = Marten::Routing::Reverser.new(
        "",
        {
          nil  => "/test/%{param1}/xyz/%{param2}",
          "en" => "/this-is-a-test/%{param1}/xyz/%{param2}",
          "fr" => "/ceci-est-un-test/%{param1}/xyz/%{param2}",
        } of String? => String,
        {
          "param1" => Marten::Routing::Parameter.registry["slug"],
          "param2" => Marten::Routing::Parameter.registry["int"],
        }
      )

      combined = reverser.combine(
        Marten::Routing::Reverser.new(
          "other:name",
          {
            nil  => "/other/%{param3}",
            "en" => "/other/%{param3}",
            "fr" => "/other/%{param3}",
          } of String? => String,
          {
            "param3" => Marten::Routing::Parameter.registry["slug"],
          }
        )
      )

      combined.name.should eq "other:name"
      combined.exposed_path_for_interpolations.should eq(
        {
          nil  => "/test/%{param1}/xyz/%{param2}/other/%{param3}",
          "en" => "/this-is-a-test/%{param1}/xyz/%{param2}/other/%{param3}",
          "fr" => "/ceci-est-un-test/%{param1}/xyz/%{param2}/other/%{param3}",
        } of String? => String
      )
      combined.parameters.should eq(
        {
          "param1" => Marten::Routing::Parameter.registry["slug"],
          "param2" => Marten::Routing::Parameter.registry["int"],
          "param3" => Marten::Routing::Parameter.registry["slug"],
        }
      )
    end

    it "returns the expected reverser when the current reverser has a name" do
      reverser = Marten::Routing::Reverser.new(
        "path:name",
        {
          nil  => "/test/%{param1}/xyz/%{param2}",
          "en" => "/this-is-a-test/%{param1}/xyz/%{param2}",
          "fr" => "/ceci-est-un-test/%{param1}/xyz/%{param2}",
        } of String? => String,
        {
          "param1" => Marten::Routing::Parameter.registry["slug"],
          "param2" => Marten::Routing::Parameter.registry["int"],
        }
      )

      combined = reverser.combine(
        Marten::Routing::Reverser.new(
          "other:name",
          {
            nil  => "/other/%{param3}",
            "en" => "/other/%{param3}",
            "fr" => "/other/%{param3}",
          } of String? => String,
          {
            "param3" => Marten::Routing::Parameter.registry["slug"],
          }
        )
      )

      combined.name.should eq "path:name:other:name"
      combined.exposed_path_for_interpolations.should eq(
        {
          nil  => "/test/%{param1}/xyz/%{param2}/other/%{param3}",
          "en" => "/this-is-a-test/%{param1}/xyz/%{param2}/other/%{param3}",
          "fr" => "/ceci-est-un-test/%{param1}/xyz/%{param2}/other/%{param3}",
        } of String? => String
      )
      combined.parameters.should eq(
        {
          "param1" => Marten::Routing::Parameter.registry["slug"],
          "param2" => Marten::Routing::Parameter.registry["int"],
          "param3" => Marten::Routing::Parameter.registry["slug"],
        }
      )
    end
  end

  describe "#name" do
    it "returns the reverser path name" do
      reverser = Marten::Routing::Reverser.new(
        "path:name",
        "/test/%{param1}/xyz/%{param2}",
        {
          "param1" => Marten::Routing::Parameter.registry["slug"],
          "param2" => Marten::Routing::Parameter.registry["int"],
        }
      )
      reverser.name.should eq "path:name"
    end
  end

  describe "#path_for_interpolation" do
    it "returns the expected path for interpolation when a single path is used" do
      reverser = Marten::Routing::Reverser.new(
        "path:name",
        "/test/%{param1}/xyz/%{param2}",
        {
          "param1" => Marten::Routing::Parameter.registry["slug"],
          "param2" => Marten::Routing::Parameter.registry["int"],
        }
      )
      reverser.path_for_interpolation.should eq "/test/%{param1}/xyz/%{param2}"
    end

    it "returns the expected path for interpolation per-locale paths are used based on the current locale" do
      reverser = Marten::Routing::Reverser.new(
        "path:name",
        {
          "en" => "/this-is-a-test/%{param1}/xyz/%{param2}",
          "fr" => "/ceci-est-un-test/%{param1}/xyz/%{param2}",
        } of String? => String,
        {
          "param1" => Marten::Routing::Parameter.registry["slug"],
          "param2" => Marten::Routing::Parameter.registry["int"],
        }
      )

      I18n.with_locale("en") do
        reverser.path_for_interpolation.should eq "/this-is-a-test/%{param1}/xyz/%{param2}"
      end

      I18n.with_locale("fr") do
        reverser.path_for_interpolation.should eq "/ceci-est-un-test/%{param1}/xyz/%{param2}"
      end
    end

    it "fallbacks to the default path if the current locale does not have a specific path for interpolation" do
      reverser = Marten::Routing::Reverser.new(
        "path:name",
        {
          nil  => "/test/%{param1}/xyz/%{param2}",
          "en" => "/this-is-a-test/%{param1}/xyz/%{param2}",
          "fr" => "/ceci-est-un-test/%{param1}/xyz/%{param2}",
        } of String? => String,
        {
          "param1" => Marten::Routing::Parameter.registry["slug"],
          "param2" => Marten::Routing::Parameter.registry["int"],
        }
      )

      I18n.with_locale("es") do
        reverser.path_for_interpolation.should eq "/test/%{param1}/xyz/%{param2}"
      end
    end
  end

  describe "#parameters" do
    it "returns the reverser parameter handlers" do
      reverser = Marten::Routing::Reverser.new(
        "path:name",
        "/test/%{param1}/xyz/%{param2}",
        {
          "param1" => Marten::Routing::Parameter.registry["slug"],
          "param2" => Marten::Routing::Parameter.registry["int"],
        }
      )
      reverser.parameters.should eq(
        {
          "param1" => Marten::Routing::Parameter.registry["slug"],
          "param2" => Marten::Routing::Parameter.registry["int"],
        }
      )
    end
  end

  describe "#reverse" do
    it "returns the interpolated path for matching parameters" do
      reverser = Marten::Routing::Reverser.new(
        "path:name",
        "/test/%{param1}/xyz/%{param2}",
        {
          "param1" => Marten::Routing::Parameter.registry["slug"],
          "param2" => Marten::Routing::Parameter.registry["int"],
        }
      )
      reverser.reverse({param1: "hello-world", param2: 42}.to_h).should eq "/test/hello-world/xyz/42"
    end

    it "returns nil and explains the mismatch if one parameter is not expected by the reverser" do
      reverser = Marten::Routing::Reverser.new(
        "path:name",
        "/test/%{param1}/xyz/%{param2}",
        {
          "param1" => Marten::Routing::Parameter.registry["slug"],
          "param2" => Marten::Routing::Parameter.registry["int"],
        }
      )
      params = {unknown_param: "hello-world"}.to_h
      reverser.reverse(params).should be_nil

      mismatch = reverser.reverse_mismatch(params)
      mismatch.extra_params.should eq ["unknown_param"]
      mismatch.missing_params.should eq ["param1", "param2"]
      mismatch.invalid_params.should be_empty
    end

    it "returns nil and explains the mismatch if one parameter has the wrong type" do
      reverser = Marten::Routing::Reverser.new(
        "path:name",
        "/test/%{param1}/xyz/%{param2}",
        {
          "param1" => Marten::Routing::Parameter.registry["slug"],
          "param2" => Marten::Routing::Parameter.registry["int"],
        }
      )
      params = {param1: "hello-world", param2: "foobar"}.to_h
      reverser.reverse(params).should be_nil

      mismatch = reverser.reverse_mismatch(params)
      mismatch.extra_params.should be_empty
      mismatch.missing_params.should be_empty
      mismatch.invalid_params.should eq [
        {"param2", "foobar"},
      ]
    end

    it "returns nil and explains the mismatch if not all expected parameters are present" do
      reverser = Marten::Routing::Reverser.new(
        "path:name",
        "/test/%{param1}/xyz/%{param2}",
        {
          "param1" => Marten::Routing::Parameter.registry["slug"],
          "param2" => Marten::Routing::Parameter.registry["int"],
        }
      )
      params = {param1: "hello-world"}.to_h
      reverser.reverse(params).should be_nil

      mismatch = reverser.reverse_mismatch(params)
      mismatch.missing_params.should eq ["param2"]
      mismatch.extra_params.should be_empty
      mismatch.invalid_params.should be_empty
    end

    it "returns the interpolated path for matching parameters when prefixed and localized paths are used" do
      reverser = Marten::Routing::Reverser.new(
        "path:name",
        {
          "en" => "/this-is-a-test/%{param1}/xyz/%{param2}",
          "fr" => "/ceci-est-un-test/%{param1}/xyz/%{param2}",
        } of String? => String,
        {
          "param1" => Marten::Routing::Parameter.registry["slug"],
          "param2" => Marten::Routing::Parameter.registry["int"],
        }
      )

      reverser.prefix_locales = true
      reverser.prefix_default_locale = true

      I18n.with_locale("en") do
        reverser.reverse({param1: "hello-world", param2: 42}.to_h).should eq "/en/this-is-a-test/hello-world/xyz/42"
      end

      I18n.with_locale("fr") do
        reverser.reverse({param1: "hello-world", param2: 42}.to_h).should eq "/fr/ceci-est-un-test/hello-world/xyz/42"
      end
    end

    it "does not prefix the path if the locale is the default locale and the prefix_default_locale option is false" do
      reverser = Marten::Routing::Reverser.new(
        "path:name",
        {
          "en" => "/this-is-a-test/%{param1}/xyz/%{param2}",
          "fr" => "/ceci-est-un-test/%{param1}/xyz/%{param2}",
        } of String? => String,
        {
          "param1" => Marten::Routing::Parameter.registry["slug"],
          "param2" => Marten::Routing::Parameter.registry["int"],
        }
      )

      reverser.prefix_locales = true
      reverser.prefix_default_locale = false

      I18n.with_locale("en") do
        reverser.reverse({param1: "hello-world", param2: 42}.to_h).should eq "/this-is-a-test/hello-world/xyz/42"
      end

      I18n.with_locale("fr") do
        reverser.reverse({param1: "hello-world", param2: 42}.to_h).should eq "/fr/ceci-est-un-test/hello-world/xyz/42"
      end
    end
  end
end
