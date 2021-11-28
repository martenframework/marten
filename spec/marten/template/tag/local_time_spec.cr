require "./spec_helper"

describe Marten::Template::Tag::LocalTime do
  describe "::new" do
    it "raises if the local_time tag does not contain one argument" do
      parser = Marten::Template::Parser.new("{% local_time %}")

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Malformed local_time tag: one argument must be provided"
      ) do
        Marten::Template::Tag::LocalTime.new(parser, "local_time")
      end
    end

    it "raises if the local_time tag contains more than one argument" do
      parser = Marten::Template::Parser.new("{% local_time '%Y' other args %}")

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Malformed local_time tag: only one argument must be provided"
      ) do
        Marten::Template::Tag::LocalTime.new(parser, "local_time '%Y' other args")
      end
    end
  end

  describe "#render" do
    it "is able to returns the right local time output for a pattern defined as a literal value" do
      time = Time.local

      Timecop.freeze(time) do
        parser = Marten::Template::Parser.new("")

        tag_1 = Marten::Template::Tag::LocalTime.new(parser, %{local_time "%Y"})
        tag_1.render(Marten::Template::Context.new).should eq time.in(Marten.settings.time_zone).to_s("%Y")

        tag_2 = Marten::Template::Tag::LocalTime.new(parser, %{local_time "%F"})
        tag_2.render(Marten::Template::Context.new).should eq time.in(Marten.settings.time_zone).to_s("%F")
      end
    end

    it "is able to resolves patterns from the context" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::LocalTime.new(parser, "local_time pattern")

      time = Time.local
      Timecop.freeze(time) do
        tag.render(Marten::Template::Context{"pattern" => "%Y"}).should eq time.in(Marten.settings.time_zone).to_s("%Y")
        tag.render(Marten::Template::Context{"pattern" => "%Y-%m-%d %H:%M:%S %:z"}).should eq(
          time.in(Marten.settings.time_zone).to_s("%Y-%m-%d %H:%M:%S %:z")
        )
      end
    end

    it "is able to asign the local time to a specific variable" do
      parser = Marten::Template::Parser.new("")

      tag = Marten::Template::Tag::LocalTime.new(parser, %{local_time "%Y" as current_year})
      context = Marten::Template::Context.new

      time = Time.local
      Timecop.freeze(time) do
        tag.render(context).should eq ""
        context["current_year"].should eq time.in(Marten.settings.time_zone).to_s("%Y")
      end
    end
  end
end
