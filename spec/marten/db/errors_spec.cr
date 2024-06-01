require "./spec_helper"

describe Marten::DB::Errors::InvalidRecord do
  it "produces the expected exception message when initialized from an invalid record" do
    invalid_record = Tag.new
    invalid_record.valid?

    error = Marten::DB::Errors::InvalidRecord.new(invalid_record)

    error.message.should eq(
      "Invalid Tag record: name (This field cannot be null.); is_active (This field cannot be null.)"
    )
  end
end
