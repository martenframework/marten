module Marten
  module Template
    class Parser
      # The Marten template lexer.
      #
      # This class allows to perform a lexical analysis from a raw template: given a text input, the `#tokenize` method
      # converts a sequence of characters into an array of tokens that represents the ramifications of the considered
      # template (tags, variables, comments and raw text).
      class Lexer
        def initialize(@source : String)
        end

        # Processes the template source and returns an array of lexical tokens.
        def tokenize : Array(Token)
          # We are going to iterate over the raw template by splitting it so that raw text bits and template structures
          # (tags, variables and comments) can be processed separately. Each iteration will result in the creation of
          # corresponding token. When splitting a raw template like this, the first string in the resulting array will
          # always be a possible raw text token (even if it is an empty string), hence why `is_text` is equal to `true`
          # at the beginning. We also need to track line numbers for debugging purposes while handling the special
          # `{% verbatim %}...{% endverbatim %}` tag that allows to disable template parsing for specific portions of
          # templates.
          is_text = true
          verbatim = false
          line_number = 1

          @source.split(TOKENIZER_RE).compact_map do |bit|
            token, verbatim, line_number = process_raw_token(bit, is_text, verbatim, line_number) if !bit.empty?
            is_text = !is_text
            token
          end
        end

        private TAG_START = "{%"
        private TAG_END   = "%}"

        private VARIABLE_START = "{{"
        private VARIABLE_END   = "}}"

        private COMMENT_START = "{#"
        private COMMENT_END   = "#}"

        private TOKENIZER_RE = Regex.new(
          "(#{TAG_START}-?.*?-?#{TAG_END}|" \
          "#{VARIABLE_START}-?.*?-?#{VARIABLE_END}|" \
          "#{COMMENT_START}-?.*?-?#{COMMENT_END})"
        )

        private VERBATIM_TAG_NAME = "verbatim"

        private def process_raw_token(raw_token, is_text, verbatim, line_number)
          if !is_text && raw_token.starts_with?(TAG_START)
            block_content, _, _ = extract_delimited_content(raw_token, TAG_START, TAG_END)
            block_content = block_content.strip
            verbatim = false if verbatim.is_a?(String) && block_content == verbatim
          end

          token = if !is_text && !verbatim && raw_token.starts_with?(VARIABLE_START)
                    content, trim_left, trim_right =
                      extract_delimited_content(raw_token, VARIABLE_START, VARIABLE_END)
                    Token.new(TokenType::VARIABLE, content.strip, line_number, trim_left, trim_right)
                  elsif !is_text && !verbatim && raw_token.starts_with?(TAG_START)
                    block_content, trim_left, trim_right =
                      extract_delimited_content(raw_token, TAG_START, TAG_END)
                    block_content = block_content.strip
                    verbatim = "end#{block_content}" if block_content.starts_with?(VERBATIM_TAG_NAME)
                    Token.new(TokenType::TAG, block_content, line_number, trim_left, trim_right)
                  elsif !is_text && !verbatim && raw_token.starts_with?(COMMENT_START)
                    _, trim_left, trim_right =
                      extract_delimited_content(raw_token, COMMENT_START, COMMENT_END)
                    Token.new(TokenType::COMMENT, "", line_number, trim_left, trim_right)
                  else
                    Token.new(TokenType::TEXT, raw_token, line_number)
                  end

          line_number += raw_token.count('\n')

          {token, verbatim, line_number}
        end

        private def extract_delimited_content(raw_token, start, finish) : {String, Bool, Bool}
          trim_left = raw_token[start.size]? == '-'
          content_start = start.size + (trim_left ? 1 : 0)

          trim_right = raw_token[-(finish.size + 1)]? == '-'
          content_end = trim_right ? -(finish.size + 1) : -finish.size

          {raw_token[content_start...content_end], trim_left, trim_right}
        end
      end
    end
  end
end
