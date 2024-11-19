require "./spec_helper"

describe Marten::Template::Tag::Localize do
  describe "::new" do
    it "raises if the localize tag does not contain at least one argument" do
      parser = Marten::Template::Parser.new("")

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Malformed localize tag: at least one argument must be provided"
      ) do
        Marten::Template::Tag::Localize.new(parser, "localize")
      end
    end
  end

  describe "#render" do
    fixed_date_time = Time.utc(2024, 11, 19, 12, 45)
    fixed_date_time_default_format = "Tue, 19 Nov 2024 12:45:00 +0000" # "%a, %d %b %Y %H:%M:%S %z"
    fixed_date_time_long_format = "November 19, 2024 12:45"            # "%B %d, %Y %H:%M"
    fixed_date_time_short_format = "19 Nov 12:45"                      # "%d %b %H:%M"
    fixed_date_default_format = "2024-11-19"                           # "%Y-%m-%d"
    fixed_date_long_format = "November 19, 2024"                       # "%B %d, %Y"
    fixed_date_short_format = "Nov 19"                                 # "%b %d"

    it "is able to localize a simple numeric value" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::Localize.new(parser, %{localize 100000})
      tag.render(Marten::Template::Context.new).should eq "100,000" # Default number format
    end

    it "is able to localize a time value" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::Localize.new(parser, %{localize date})
      tag.render(Marten::Template::Context{"date" => fixed_date_time}).should eq fixed_date_time_default_format
    end

    it "is able to localize a date value" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::Localize.new(parser, %{localize date})
      tag.render(Marten::Template::Context{"date" => fixed_date_time.date}).should eq fixed_date_default_format
    end

    it "is able to localize a time with a custom format" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::Localize.new(parser, %{localize date format: "short"})
      tag.render(Marten::Template::Context{"date" => fixed_date_time}).should eq fixed_date_time_short_format
    end

    it "is able to localize a date with a custom format" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::Localize.new(parser, %{localize date format: "short"})
      tag.render(Marten::Template::Context{"date" => fixed_date_time.date}).should eq fixed_date_short_format
    end

    it "is able to localize a time with a long format" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::Localize.new(parser, %{localize date format: "long"})
      tag.render(Marten::Template::Context{"date" => fixed_date_time}).should eq fixed_date_time_long_format
    end

    it "is able to localize a date with a long format" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::Localize.new(parser, %{localize date format: "long"})
      tag.render(Marten::Template::Context{"date" => fixed_date_time.date}).should eq fixed_date_long_format
    end

    it "is able to resolve values from the context for localization" do
      parser = Marten::Template::Parser.new("")
      context = Marten::Template::Context{"value" => 123456}

      tag = Marten::Template::Tag::Localize.new(parser, %{localize value})
      tag.render(context).should eq "123,456"
    end

    it "is able to resolve the format from the context" do
      parser = Marten::Template::Parser.new("")
      context = Marten::Template::Context{"format" => "custom"}

      tag = Marten::Template::Tag::Localize.new(parser, %{localize 100000 format: format})
      tag.render(context).should eq "10-00-00,00"
    end

    it "is able to assign the localized value to a specific variable" do
      parser = Marten::Template::Parser.new("")
      context = Marten::Template::Context{"date" => fixed_date_time}
      tag = Marten::Template::Tag::Localize.new(parser, %{localize date as localized_date})

      tag.render(context).should eq ""
      context["localized_date"].to_s.should eq fixed_date_time_default_format
    end

    it "raises if a invalid date tuple is provided" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::Localize.new(parser, %{localize unsupported_date})

      expect_raises(
        Marten::Template::Errors::UnsupportedValue,
        "Localization requires an Array with exactly 3 elements, but received 4 elements." +
        " Ensure the Array follows the format [year, month, day]."
      ) do
        tag.render(Marten::Template::Context{"unsupported_date" => {2024, 11, 19, 12}})
      end
    end

    it "raises if a invalid date tuple is provided" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::Localize.new(parser, %{localize unsupported_date})

      expect_raises(
        Marten::Template::Errors::UnsupportedType,
        "Expected an Array with only Int32 elements, but found elements of types: String, Bool, Float64."
      ) do
        tag.render(Marten::Template::Context{"unsupported_date" => {"2024", true, 1.0}})
      end
    end

    it "raises if a non-supported type is provided" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::Localize.new(parser, %{localize unsupported_value})

      expect_raises(
        Marten::Template::Errors::UnsupportedType,
        "The `localize` tag only supports localization of Time or numeric values, but got Nil"
      ) do
        tag.render(Marten::Template::Context{"unsupported_value" => nil})
      end
    end
  end
end
