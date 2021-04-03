require "./spec_helper"

describe Marten::Template::Parser::Lexer do
  describe "#tokenize" do
    it "returns an empty array for an empty template" do
      lexer = Marten::Template::Parser::Lexer.new("")
      lexer.tokenize.should be_empty
    end

    it "is able to extract text tokens" do
      lexer = Marten::Template::Parser::Lexer.new(
        <<-TEMPLATE
        {% for user in users %}
        Hello {{ user.name }}
        {% endfor %}
        Bye!
        TEMPLATE
      )
      tokens = lexer.tokenize

      tokens[1].type.text?.should be_true
      tokens[1].content.should eq "\nHello "
      tokens[1].line_number.should eq 1

      tokens[3].type.text?.should be_true
      tokens[3].content.should eq "\n"
      tokens[3].line_number.should eq 2

      tokens[5].type.text?.should be_true
      tokens[5].content.should eq "\nBye!"
      tokens[5].line_number.should eq 3
    end

    it "is able to extract tag tokens" do
      lexer = Marten::Template::Parser::Lexer.new(
        <<-TEMPLATE
        {% for user in users %}
        Hello {{ user.name }}
        {% endfor %}
        Bye!
        TEMPLATE
      )
      tokens = lexer.tokenize

      tokens[0].type.tag?.should be_true
      tokens[0].content.should eq "for user in users"
      tokens[0].line_number.should eq 1

      tokens[4].type.tag?.should be_true
      tokens[4].content.should eq "endfor"
      tokens[4].line_number.should eq 3
    end

    it "is able to extract variable tokens" do
      lexer = Marten::Template::Parser::Lexer.new(
        <<-TEMPLATE
        {% for user in users %}
        Hello {{ user.name }}
        {% endfor %}
        Bye!
        TEMPLATE
      )
      tokens = lexer.tokenize

      tokens[2].type.variable?.should be_true
      tokens[2].content.should eq "user.name"
      tokens[2].line_number.should eq 2
    end

    it "is able to extract comment tokens" do
      lexer = Marten::Template::Parser::Lexer.new(
        <<-TEMPLATE
        {% for user in users %}
        Hello {{ user.name }}
        {% endfor %}
        {# Did it work? #}
        Bye!
        TEMPLATE
      )
      tokens = lexer.tokenize

      tokens[6].type.comment?.should be_true
      tokens[6].content.should eq ""
      tokens[6].line_number.should eq 4
    end

    it "is able to process ignored verbatim blocks as expected" do
      lexer = Marten::Template::Parser::Lexer.new(
        <<-TEMPLATE
        {% for user in users %}
        {% verbatim %}
        Hello {{ user.name }}
        {% endverbatim %}
        {% endfor %}
        {# Did it work? #}
        Bye!
        TEMPLATE
      )
      tokens = lexer.tokenize

      tokens[0].type.tag?.should be_true
      tokens[0].content.should eq "for user in users"
      tokens[0].line_number.should eq 1

      tokens[1].type.text?.should be_true
      tokens[1].content.should eq "\n"
      tokens[1].line_number.should eq 1

      tokens[2].type.tag?.should be_true
      tokens[2].content.should eq "verbatim"
      tokens[2].line_number.should eq 2

      tokens[3].type.text?.should be_true
      tokens[3].content.should eq "\nHello "
      tokens[3].line_number.should eq 2

      tokens[4].type.text?.should be_true
      tokens[4].content.should eq "{{ user.name }}"
      tokens[4].line_number.should eq 3

      tokens[5].type.text?.should be_true
      tokens[5].content.should eq "\n"
      tokens[5].line_number.should eq 3

      tokens[6].type.tag?.should be_true
      tokens[6].content.should eq "endverbatim"
      tokens[6].line_number.should eq 4

      tokens[7].type.text?.should be_true
      tokens[7].content.should eq "\n"
      tokens[7].line_number.should eq 4

      tokens[8].type.tag?.should be_true
      tokens[8].content.should eq "endfor"
      tokens[8].line_number.should eq 5

      tokens[9].type.text?.should be_true
      tokens[9].content.should eq "\n"
      tokens[9].line_number.should eq 5

      tokens[10].type.comment?.should be_true
      tokens[10].content.should eq ""
      tokens[10].line_number.should eq 6

      tokens[11].type.text?.should be_true
      tokens[11].content.should eq "\nBye!"
      tokens[11].line_number.should eq 6
    end
  end
end
