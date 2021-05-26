require "./spec_helper"

describe Marten::Template::Tag::CanExtractKwargs do
  describe "#extract_kwargs" do
    it "extracts kwargs separated by commas from a string as expected" do
      extractor = Marten::Template::Tag::CanExtractKwargs::Test.new

      kwargs_1 = extractor.extract_kwargs("test arg1: 'value with space', arg2: var")
      kwargs_1.size.should eq 2
      kwargs_1[0].should eq({"arg1", "'value with space'"})
      kwargs_1[1].should eq({"arg2", "var"})

      kwargs_2 = extractor.extract_kwargs("test arg1:'value with space',arg2:42")
      kwargs_2.size.should eq 2
      kwargs_2[0].should eq({"arg1", "'value with space'"})
      kwargs_2[1].should eq({"arg2", "42"})
    end

    it "extracts kwargs involving filters and liteal values as expected" do
      extractor = Marten::Template::Tag::CanExtractKwargs::Test.new

      kwargs_1 = extractor.extract_kwargs(%{test arg1: 'value with space', arg2: other_var | default: "this is a test"})
      kwargs_1.size.should eq 2
      kwargs_1[0].should eq({"arg1", "'value with space'"})
      kwargs_1[1].should eq({"arg2", %{other_var | default: "this is a test"}})

      kwargs_2 = extractor.extract_kwargs(
        %{test arg1: 'value with space', arg2: other_var | default: "this is a test", arg3: "other test"}
      )
      kwargs_2.size.should eq 3
      kwargs_2[0].should eq({"arg1", "'value with space'"})
      kwargs_2[1].should eq({"arg2", %{other_var | default: "this is a test"}})
      kwargs_2[2].should eq({"arg3", %{"other test"}})
    end

    it "returns an empty array of there are no kwargs" do
      extractor = Marten::Template::Tag::CanExtractKwargs::Test.new
      extractor.extract_kwargs("this is a value").should be_empty
    end
  end
end

class Marten::Template::Tag::CanExtractKwargs::Test
  include Marten::Template::Tag::CanExtractKwargs
end
