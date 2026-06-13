require "./spec_helper"

describe Marten::Template::Parser::Token do
  describe "#type" do
    it "returns the token type" do
      token = Marten::Template::Parser::Token.new(Marten::Template::Parser::TokenType::TAG, "for", 1)
      token.type.should eq Marten::Template::Parser::TokenType::TAG
    end
  end

  describe "#content" do
    it "returns the token content" do
      token = Marten::Template::Parser::Token.new(Marten::Template::Parser::TokenType::TAG, "for", 1)
      token.content.should eq "for"
    end
  end

  describe "#line_number" do
    it "returns the token line number" do
      token = Marten::Template::Parser::Token.new(Marten::Template::Parser::TokenType::TAG, "for", 1)
      token.line_number.should eq 1
    end
  end

  describe "#trim_left?" do
    it "returns whether leading whitespace should be trimmed" do
      token = Marten::Template::Parser::Token.new(
        Marten::Template::Parser::TokenType::TAG, "for", 1, trim_left: true
      )
      token.trim_left?.should be_true
    end
  end

  describe "#trim_right?" do
    it "returns whether trailing whitespace should be trimmed" do
      token = Marten::Template::Parser::Token.new(
        Marten::Template::Parser::TokenType::TAG, "for", 1, trim_right: true
      )
      token.trim_right?.should be_true
    end
  end
end
