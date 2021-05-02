require "./spec_helper"

describe Marten::Template::Condition::Token::Operator::Not do
  describe "#eval" do
    it "applies the not operator as expected" do
      condition = Marten::Template::Condition.new(["var1"])

      token = Marten::Template::Condition::Token::Operator::Not.new
      token.nud(condition)

      token.eval(Marten::Template::Context{"var1" => false}).truthy?.should be_true
      token.eval(Marten::Template::Context{"var1" => true}).truthy?.should be_false
    end
  end

  describe "#id" do
    it "returns the expected identified" do
      Marten::Template::Condition::Token::Operator::Not.new.id.should eq "not"
    end
  end

  describe "#lbp" do
    it "returns the expected left binding power" do
      Marten::Template::Condition::Token::Operator::Not.new.lbp.should eq 8_u8
    end
  end
end
