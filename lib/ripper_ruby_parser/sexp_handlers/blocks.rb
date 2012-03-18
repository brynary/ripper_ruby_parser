module RipperRubyParser
  module SexpHandlers
    module Blocks
      def process_method_add_block exp
        _, call, block = exp.shift 3
        block = process(block)
        args = convert_block_args(block[1])
        stmt = block[2].first
        s(:iter, process(call), args, stmt)
      end

      def process_brace_block exp
        handle_generic_block exp
      end

      def process_do_block exp
        handle_generic_block exp
      end

      def process_params exp
        _, normal, defaults, rest, _, block = exp.shift 6

        args = [*normal].map do |id|
          extract_node_symbol id
        end

        assigns = [*defaults].map do |pair|
          sym = extract_node_symbol pair[0]
          args << sym
          val = process pair[1]
          s(:lasgn, sym, val)
        end

        add_arg_unless_nil(rest, args) {|name| :"*#{name}" }

        add_arg_unless_nil(block, args) {|name| :"&#{name}" }

        if assigns.length > 0
          args << s(:block, *assigns)
        end

        s(:args, *args)
      end

      def process_begin exp
        _, body = exp.shift 2

        block = process(body)[1]

        strip_wrapping_block(block)
      end

      def process_rescue exp
        _, eclass, evar, block, _ = exp.shift 5
        rescue_block = s(*map_body(block))

        arr = []
        if eclass
          eclass = handle_potentially_typeless_sexp eclass
          if eclass.first.is_a? Symbol
            arr += eclass[1..-1]
          else
            arr << eclass[0]
          end
        end

        if evar
          evar = process(evar)[1]
          easgn = s(:lasgn, :e, s(:gvar, :$!))
          arr << easgn
        end

        s(:resbody, s(:array, *arr),
          wrap_in_block(rescue_block))
      end

      def process_rescue_mod exp
        _, scary, safe = exp.shift 3
        s(:rescue, process(scary), s(:resbody, s(:array), process(safe)))
      end

      def process_ensure exp
        _, block = exp.shift 2
        wrap_in_block s(*map_body(block))
      end

      private

      def handle_generic_block exp
        _, args, stmts = exp.shift 3
        s(:block, process(args), s(handle_statement_list(stmts)))
      end

      def strip_wrapping_block(block)
        case block.length
        when 1
          s(:nil)
        when 2
          block[1]
        else
          block
        end
      end

      def add_arg_unless_nil(item, args)
        unless item.nil?
          name = extract_node_symbol item[1]
          args << yield(name)
        end
      end
    end
  end
end
