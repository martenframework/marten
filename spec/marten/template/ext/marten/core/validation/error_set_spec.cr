require "./spec_helper"

describe Marten::Core::Validation::ErrorSet do
  describe "#resolve_template_attribute" do
    it "is able to return a specific set of errors" do
      error_set = Marten::Core::Validation::ErrorSet.new
      error_set.add("slug", "Size must be greater than 10 characters")
      error_set.add("slug", "Cannot contain spaces")
      error_set.add("content", "This is invalid!")

      errors = error_set.resolve_template_attribute("slug")
      errors.should be_a Array(Marten::Core::Validation::Error)
      errors = errors.as(Array(Marten::Core::Validation::Error))
      errors.size.should eq 2
      errors[0].message.should eq "Size must be greater than 10 characters"
      errors[1].message.should eq "Cannot contain spaces"
    end

    it "is able to return global errors" do
      error_set = Marten::Core::Validation::ErrorSet.new
      error_set.add("slug", "Size must be greater than 10 characters")
      error_set.add("slug", "Cannot contain spaces")
      error_set.add("This is invalid!")

      errors = error_set.resolve_template_attribute("global")
      errors.should be_a Array(Marten::Core::Validation::Error)
      errors = errors.as(Array(Marten::Core::Validation::Error))
      errors.size.should eq 1
      errors.first.message.should eq "This is invalid!"
    end

    it "returns an empty array if the passed attribute name is not found" do
      error_set = Marten::Core::Validation::ErrorSet.new

      error_set.resolve_template_attribute("unknown").should be_empty
    end
  end
end
