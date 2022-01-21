require "./spec_helper"

describe Marten::Core::Validation::ErrorSet do
  describe "::new" do
    it "initializes an empty error set" do
      error_set = Marten::Core::Validation::ErrorSet.new
      error_set.should be_empty
    end
  end

  describe "#[]" do
    it "returns all the errors associated with a specific field expressed as a string" do
      error_set = Marten::Core::Validation::ErrorSet.new
      error_set.add("slug", "Size must be greater than 10 characters")
      error_set.add("slug", "Cannot contain spaces")
      error_set.add("content", "This is invalid!")

      error_set["slug"].size.should eq 2
      error_set["slug"][0].message.should eq "Size must be greater than 10 characters"
      error_set["slug"][1].message.should eq "Cannot contain spaces"
    end

    it "returns all the errors associated with a specific field expressed as a symbol" do
      error_set = Marten::Core::Validation::ErrorSet.new
      error_set.add("slug", "Size must be greater than 10 characters")
      error_set.add("slug", "Cannot contain spaces")
      error_set.add("content", "This is invalid!")

      error_set[:slug].size.should eq 2
      error_set[:slug][0].message.should eq "Size must be greater than 10 characters"
      error_set[:slug][1].message.should eq "Cannot contain spaces"
    end

    it "returns all the global errors if applicable" do
      error_set = Marten::Core::Validation::ErrorSet.new
      error_set.add("slug", "Size must be greater than 10 characters")
      error_set.add("slug", "Cannot contain spaces")
      error_set.add("This is invalid!")

      error_set[nil].size.should eq 1
      error_set[nil][0].message.should eq "This is invalid!"
    end

    it "returns an empty array if there are no errors associated with the passed field" do
      error_set = Marten::Core::Validation::ErrorSet.new
      error_set.add("slug", "Size must be greater than 10 characters")
      error_set.add("slug", "Cannot contain spaces")
      error_set.add("content", "This is invalid!")

      error_set[:unknown].should be_empty
    end
  end

  describe "#add" do
    it "allows to add a default error to the set" do
      error_set = Marten::Core::Validation::ErrorSet.new
      error_set.add("This is invalid!")

      error_set.size.should eq 1
      error_set.first.message.should eq "This is invalid!"
      error_set.first.type.should eq Marten::Core::Validation::ErrorSet::DEFAULT_ERROR_TYPE.to_s
      error_set.first.field.should be_nil
    end

    it "allows to add a default error associated with a specific string field to the set" do
      error_set = Marten::Core::Validation::ErrorSet.new
      error_set.add("content", "This is invalid!")

      error_set.size.should eq 1
      error_set.first.message.should eq "This is invalid!"
      error_set.first.type.should eq Marten::Core::Validation::ErrorSet::DEFAULT_ERROR_TYPE.to_s
      error_set.first.field.should eq "content"
    end

    it "allows to add a default error associated with a specific symbol field to the set" do
      error_set = Marten::Core::Validation::ErrorSet.new
      error_set.add(:content, "This is invalid!")

      error_set.size.should eq 1
      error_set.first.message.should eq "This is invalid!"
      error_set.first.type.should eq Marten::Core::Validation::ErrorSet::DEFAULT_ERROR_TYPE.to_s
      error_set.first.field.should eq "content"
    end

    it "allows to add a custom error as a string to the set" do
      error_set = Marten::Core::Validation::ErrorSet.new
      error_set.add("This is invalid!", type: "blank")

      error_set.size.should eq 1
      error_set.first.message.should eq "This is invalid!"
      error_set.first.type.should eq "blank"
      error_set.first.field.should be_nil
    end

    it "allows to add a custom error as a symbol to the set" do
      error_set = Marten::Core::Validation::ErrorSet.new
      error_set.add("This is invalid!", type: :blank)

      error_set.size.should eq 1
      error_set.first.message.should eq "This is invalid!"
      error_set.first.type.should eq "blank"
      error_set.first.field.should be_nil
    end

    it "allows to add a custom error as a string associated with a specific field to the set" do
      error_set = Marten::Core::Validation::ErrorSet.new
      error_set.add("content", "This is invalid!", type: "blank")

      error_set.size.should eq 1
      error_set.first.message.should eq "This is invalid!"
      error_set.first.type.should eq "blank"
      error_set.first.field.should eq "content"
    end

    it "allows to add a custom error as a symbol associated with a specific field to the set" do
      error_set = Marten::Core::Validation::ErrorSet.new
      error_set.add(:content, "This is invalid!", type: :blank)

      error_set.size.should eq 1
      error_set.first.message.should eq "This is invalid!"
      error_set.first.type.should eq "blank"
      error_set.first.field.should eq "content"
    end
  end

  describe "#clear" do
    it "allows to clear an error set" do
      error_set = Marten::Core::Validation::ErrorSet.new
      error_set.add("This is invalid!")
      error_set.add(:content, "This is invalid!")

      error_set.size.should eq 2

      error_set.clear

      error_set.size.should eq 0
    end
  end

  describe "#global" do
    it "returns an array of all the global errors" do
      error_set = Marten::Core::Validation::ErrorSet.new
      error_set.add("slug", "Size must be greater than 10 characters")
      error_set.add("slug", "Cannot contain spaces")
      error_set.add("This is invalid!")

      error_set.global.size.should eq 1
      error_set.global.first.message.should eq "This is invalid!"
    end

    it "returns an empty array if there are no global errors" do
      error_set = Marten::Core::Validation::ErrorSet.new
      error_set.add("slug", "Size must be greater than 10 characters")
      error_set.add("slug", "Cannot contain spaces")

      error_set.global.should be_empty
    end
  end
end
