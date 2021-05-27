require "./spec_helper"

describe Marten::Template::Tag::CanExtractAssignments do
  describe "#extract_assignments" do
    it "extracts assignments separated by commas from a string as expected" do
      extractor = Marten::Template::Tag::CanExtractAssignments::Test.new

      assignments_1 = extractor.extract_assignments("test val1 = 'value with space', val2 = var")
      assignments_1.size.should eq 2
      assignments_1[0].should eq({"val1", "'value with space'"})
      assignments_1[1].should eq({"val2", "var"})

      assignments_2 = extractor.extract_assignments("test val1='value with space',val2=42")
      assignments_2.size.should eq 2
      assignments_2[0].should eq({"val1", "'value with space'"})
      assignments_2[1].should eq({"val2", "42"})
    end

    it "extracts assignments involving filters and liteal values as expected" do
      extractor = Marten::Template::Tag::CanExtractAssignments::Test.new

      assignments_1 = extractor.extract_assignments(
        %{test val1 = 'value with space', val2 = other_var | default: "this is a test"}
      )
      assignments_1.size.should eq 2
      assignments_1[0].should eq({"val1", "'value with space'"})
      assignments_1[1].should eq({"val2", %{other_var | default: "this is a test"}})

      assignments_2 = extractor.extract_assignments(
        %{test val1 = 'value with space', val2 = other_var | default: "this is a test", val3 = "other test"}
      )
      assignments_2.size.should eq 3
      assignments_2[0].should eq({"val1", "'value with space'"})
      assignments_2[1].should eq({"val2", %{other_var | default: "this is a test"}})
      assignments_2[2].should eq({"val3", %{"other test"}})
    end

    it "returns an empty array of there are no assignments" do
      extractor = Marten::Template::Tag::CanExtractAssignments::Test.new
      extractor.extract_assignments("this is a value").should be_empty
    end
  end
end

class Marten::Template::Tag::CanExtractAssignments::Test
  include Marten::Template::Tag::CanExtractAssignments
end
