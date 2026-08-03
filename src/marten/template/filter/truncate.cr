module Marten
  module Template
    module Filter
      # The `truncate` filter.
      #
      # The `truncate` filter truncates a string to the given number of characters. Truncated strings end with an
      # ellipsis (`"..."`) that is accounted for in the resulting size. A filter argument corresponding to the maximum
      # size is mandatory.
      #
      # ```
      # {{ value|truncate:15 }}
      # ```
      class Truncate < Base
        def apply(value : Value, arg : Value? = nil) : Value
          raise Errors::InvalidSyntax.new("The 'truncate' filter requires one argument") if arg.nil?

          truncate_at = extract_truncate_at(arg)
          str = value.to_s

          return Value.from(str) if str.size <= truncate_at

          omission = OMISSION
          stop = truncate_at - omission.size

          if stop <= 0
            return Value.from(omission[0, truncate_at])
          end

          Value.from("#{str[0, stop]}#{omission}")
        end

        private OMISSION = "..."

        private def extract_truncate_at(arg : Value) : Int32
          case raw = arg.raw
          when Int32
            truncate_at = raw
          when Int64
            truncate_at = raw.to_i32
          else
            begin
              truncate_at = arg.to_s.to_i32
            rescue ArgumentError
              raise Errors::UnsupportedType.new(
                "The 'truncate' filter requires an integer argument, #{raw.class} given"
              )
            end
          end

          if truncate_at < 0
            raise Errors::UnsupportedValue.new("The 'truncate' filter requires a non-negative integer argument")
          end

          truncate_at
        end
      end
    end
  end
end
