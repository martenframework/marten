require "./spec_helper"

describe Marten::Template::Condition::Token::Operator::LessThan do
  describe "#eval" do
    it "applies the less than operator as expected" do
      condition = Marten::Template::Condition.new(["var2"])

      token = Marten::Template::Condition::Token::Operator::LessThan.new
      token.led(condition, Marten::Template::Condition::Token::Value.new("var1"))

      token.eval(Marten::Template::Context{"var1" => 42, "var2" => 42}).truthy?.should be_false
      token.eval(Marten::Template::Context{"var1" => 42, "var2" => 12}).truthy?.should be_false
      token.eval(Marten::Template::Context{"var1" => 12, "var2" => 42}).truthy?.should be_true
    end
  end

  describe "#id" do
    it "returns the expected identified" do
      Marten::Template::Condition::Token::Operator::LessThan.new.id.should eq "less_than"
    end
  end

  describe "#lbp" do
    it "returns the expected left binding power" do
      Marten::Template::Condition::Token::Operator::LessThan.new.lbp.should eq 10_u8
    end
  end
end
