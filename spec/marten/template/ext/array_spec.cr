require "./spec_helper"

describe Array do
  describe "#resolve_template_attribute" do
    it "returns the expected result when requesting the 'any?' attribute" do
      ([1, 2, 3] of Int32).resolve_template_attribute("any?").should be_true
      ([] of Int32).resolve_template_attribute("any?").should be_false
    end

    it "returns the expected result when requesting the 'compact' attribute" do
      ([1, nil, 3] of Int32 | Nil).resolve_template_attribute("compact").should eq [1, 3]
    end

    it "returns the expected result when requesting the 'empty?' attribute" do
      ([1, 2, 3] of Int32).resolve_template_attribute("empty?").should be_false
      ([] of Int32).resolve_template_attribute("empty?").should be_true
    end

    it "returns the expected result when requesting the 'first' attribute" do
      ([1, 2, 3] of Int32).resolve_template_attribute("first").should eq 1
    end

    it "returns the expected result when requesting the 'last' attribute" do
      ([1, 2, 3] of Int32).resolve_template_attribute("last").should eq 3
    end

    it "returns the expected result when requesting the 'none?' attribute" do
      ([1, 2, 3] of Int32).resolve_template_attribute("none?").should be_false
      ([] of Int32).resolve_template_attribute("none?").should be_true
    end

    it "returns the expected result when requesting the 'one?' attribute" do
      ([1, 2, 3] of Int32).resolve_template_attribute("one?").should be_false
      ([1] of Int32).resolve_template_attribute("one?").should be_true
      ([] of Int32).resolve_template_attribute("one?").should be_false
    end

    it "returns the expected result when requesting the 'present?' attribute" do
      ([1, 2, 3] of Int32).resolve_template_attribute("present?").should be_true
      ([] of Int32).resolve_template_attribute("present?").should be_false
    end

    it "returns the expected result when requesting the 'reverse' attribute" do
      ([1, 2, 3] of Int32).resolve_template_attribute("reverse").should eq [3, 2, 1]
    end

    it "returns the expected result when requesting the 'size' attribute" do
      ([1, 2, 3] of Int32).resolve_template_attribute("size").should eq 3
      ([] of Int32).resolve_template_attribute("size").should eq 0
    end
  end
end
