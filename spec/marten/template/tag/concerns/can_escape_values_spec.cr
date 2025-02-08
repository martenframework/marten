require "./spec_helper"

describe Marten::Template::Tag::CanEscapeValues do
  describe "#escape_value" do
    it "escapes the value as expected when the context requires escaping" do
      context = Marten::Template::Context.new

      context.with_escape(true) do
        Marten::Template::Tag::CanEscapeValues::Test.new.escape_value("<b>test</b>", context).should eq(
          "&lt;b&gt;test&lt;/b&gt;"
        )
      end
    end

    it "does not escape the value as expected when the context does not require escaping" do
      context = Marten::Template::Context.new

      context.with_escape(false) do
        Marten::Template::Tag::CanEscapeValues::Test.new.escape_value("<b>test</b>", context).should eq "<b>test</b>"
      end
    end
  end
end

class Marten::Template::Tag::CanEscapeValues::Test
  include Marten::Template::Tag::CanEscapeValues
end
