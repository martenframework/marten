require "./spec_helper"

describe Hash do
  describe "#resolve_template_attribute" do
    it "returns the expected result when requesting the 'any?' attribute" do
      ({"a" => 1, "b" => 2, "c" => 3} of String => Int32).resolve_template_attribute("any?").should be_true
      ({} of String => Int32).resolve_template_attribute("any?").should be_false
    end

    it "returns the expected result when requesting the 'compact' attribute" do
      ({"a" => 1, "b" => nil, "c" => 3} of String => Int32 | Nil).resolve_template_attribute("compact").should(
        eq({"a" => 1, "c" => 3})
      )
    end

    it "returns the expected result when requesting the 'empty?' attribute" do
      ({"a" => 1, "b" => 2, "c" => 3} of String => Int32).resolve_template_attribute("empty?").should be_false
      ({} of String => Int32).resolve_template_attribute("empty?").should be_true
    end

    it "returns the expected result when requesting the 'keys' attribute" do
      ({"a" => 1, "b" => 2, "c" => 3} of String => Int32).resolve_template_attribute("keys").should eq ["a", "b", "c"]
    end

    it "returns the expected result when requesting the 'none?' attribute" do
      ({"a" => 1, "b" => 2, "c" => 3} of String => Int32).resolve_template_attribute("none?").should be_false
      ({} of String => Int32).resolve_template_attribute("none?").should be_true
    end

    it "returns the expected result when requesting the 'one?' attribute" do
      ({"a" => 1, "b" => 2, "c" => 3} of String => Int32).resolve_template_attribute("one?").should be_false
      ({"a" => 1} of String => Int32).resolve_template_attribute("one?").should be_true
      ({} of String => Int32).resolve_template_attribute("one?").should be_false
    end

    it "returns the expected result when requesting the 'present?' attribute" do
      ({"a" => 1, "b" => 2, "c" => 3} of String => Int32).resolve_template_attribute("present?").should be_true
      ({} of String => Int32).resolve_template_attribute("present?").should be_false
    end

    it "returns the expected result when requesting the 'size' attribute" do
      ({"a" => 1, "b" => 2, "c" => 3} of String => Int32).resolve_template_attribute("size").should eq 3
      ({} of String => Int32).resolve_template_attribute("size").should eq 0
    end

    it "returns the expected result when requesting the 'values' attribute" do
      ({"a" => 1, "b" => 2, "c" => 3} of String => Int32).resolve_template_attribute("values").should eq [1, 2, 3]
    end
  end
end
