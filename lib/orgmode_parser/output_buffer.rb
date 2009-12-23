module Orgmode

  # The OutputBuffer is used to accumulate multiple lines of orgmode
  # text, and then emit them to the output all in one go. The class
  # will do the final textile substitution for inline formatting and
  # add a newline character prior emitting the output.
  class OutputBuffer

    # This is the buffer that we accumulate into.
    attr_reader :buffer

    # This is the current type of output being accumulated. 
    attr_accessor :output_type

    # This is an optional string that will get emitted when the buffer
    # is flushed.
    attr_accessor :paragraph_modifier

    # Creates a new OutputBuffer object that is bound to an output object.
    # The output will get flushed to =output=.
    def initialize(output)
      @output = output
      @buffer = ""
      @output_type = :start
      @list_indent_stack = []
    end

    # Prepares the output buffer to receive content from a line.
    # As a side effect, this may flush the current accumulated text.
    def prepare(line)
      if not should_accumulate_output?(line) then
        flush!
      end
      @output_type = line.paragraph_type
      maintain_list_indent_stack(line)
    end

    # Accumulate the string @str@.
    def << (str)
      @buffer << str
    end

    # Flushes the current buffer
    def flush!
      if (@output_type == :blank) then
        @output << "\n\n"
      elsif (@buffer.length > 0) then
        @output << @paragraph_modifier if @paragraph_modifier
        @output << @buffer.textile_substitution << "\n"
      end
      @buffer = ""
    end

    # Gets the current list indent level. 
    def list_indent_level
      @list_indent_stack.length
    end

    ######################################################################
    private

    def maintain_list_indent_stack(line)
      if (line.plain_list?) then
        while (not @list_indent_stack.empty? \
               and (@list_indent_stack.last > line.indent)) 
          @list_indent_stack.pop
        end
        if (@list_indent_stack.empty? \
            or @list_indent_stack.last < line.indent)
          @list_indent_stack.push(line.indent)
        end
      else
        @list_indent_stack = []
      end
    end

    # Tests if the current line should be accumulated in the current
    # output buffer.  (Extraneous line breaks in the orgmode buffer
    # are removed by accumulating lines in the output buffer without
    # line breaks.)
    def should_accumulate_output?(line)

      # Special case: Multiple blank lines get accumulated.
      return true if line.paragraph_type == :blank and @output_type == :blank
      
      # Currently only "paragraphs" get accumulated with previous output.
      return false unless line.paragraph_type == :paragraph
      if ((@output_type == :ordered_list) or
          (@output_type == :unordered_list)) then

        # If the previous output type was a list item, then we only put a paragraph in it
        # if its indent level is greater than the list indent level.

        return false unless line.indent > @list_indent_stack.last
      end
      true
    end
  end                           # class OutputBuffer
end                             # module Orgmode
