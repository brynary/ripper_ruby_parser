module RipperRubyParser
  module SexpHandlers
    module HelperMethods
      def handle_potentially_typeless_sexp exp
        if exp.nil?
          []
        elsif exp.first.is_a? Symbol
          process(exp)
        else
          exp.map { |sub_exp| process(sub_exp) }
        end
      end

      def convert_block_args(args)
        args && s(:lasgn, args[1][1])
      end

      def handle_statement_list exp
        statements = map_body exp

        wrap_in_block(statements)
      end

      def identifier_node_to_symbol exp
        extract_node_symbol exp
      end

      def extract_node_symbol exp
        _, ident, _ = exp.shift 3

        ident.to_sym
      end

      def generic_add_star exp
        _, args, splatarg = exp.shift 3
        items = args.map { |sub| process(sub) }
        items << s(:splat, process(splatarg))
        s(*items)
      end

      def is_literal? exp
        exp.sexp_type == :lit
      end

      def map_body body
        body.
          map { |sub_exp| process(sub_exp) }.
          reject { |sub_exp| sub_exp.sexp_type == :void_stmt }
      end

      def wrap_in_block statements
        if statements.length == 1
          statements.first
        else
          s(:block, *statements)
        end
      end

    end
  end
end
