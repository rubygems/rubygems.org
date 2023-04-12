class DrySchemaField < Avo::Fields::BaseField
  attr_reader :schema

  def initialize(name, schema:, **args, &block)
    @schema = schema
    super(name, **args, &block)
  end

  def nested_fields
    FieldCompiler.new.call(schema)
  end

  class FieldCompiler
    def initialize
      @fields = {}
    end

    def call(schema)
       visit(schema.try(:to_ast), {})
       @fields.compact_blank.keep_if { |_, v| v.is_a? Avo::Fields::BaseField}
    end

    def visit(node, opts)
      type, body = node
      send(:"visit_#{type}", body, opts)
    end

    def visit_schema(node, opts)
      keys, options, meta = node
      keys.map { visit(_1, opts) }
    end

    def visit_key(node, opts)
      name, rest = node

      @fields[name] = visit(rest, opts.merge(key: name))
    end

    alias visit_lax visit
    
    def visit_constructor(node, opts)
      nominal, fn = node
      visit(nominal, opts)
    end

    def visit_intersection(node, opts)
      left, right = node
      node.reduce(nil) do |acc, elem|
        visit(elem, opts.merge(and: acc))
      end
    end

    def visit_array(node, opts)
      member, meta = node
      member = visit(member, opts)

      # todo: create an array field
      # member
      ap(member:)
      nil
    end

    def visit_nominal(node, opts)
      type, meta = node

      case type
      when ActiveSupport::Duration.singleton_class
        visit_nominal(String, opts)
      when String.singleton_class
        Avo::Fields::TextField.new(opts.fetch(:key))
      else
        raise "Unhandled type #{type.inspect}"
      end
    end

    def visit_struct(node, opts)
      struct, ast = node

      DrySchemaField.new(opts.fetch(:key), schema: struct.schema)
    end

    def visit_constrained(node, opts)
      nominal, rule = node
      visit(nominal, opts)
    end

    def visit_set(node, opts)
      node.map { visit(_1, opts) }.compact
      nil
    end

    def visit_and(node, opts)
      node.reduce(opts[:and]) do |acc, elem|
        visit(elem, opts.merge(and: acc))
      end
    end

    def visit_predicate(node, opts)
      name, rest = node
      return if name == :key?
      

      return case name
      when :key?, :filled?, :lteq?, :gteq?, :format?
        nil
      when :type?
        visit(rest.first, opts)
      when :hash?
        Dry::Types["hash"]
      when *Dry::Types::PredicateInferrer::TYPE_TO_PREDICATE.values
        type = Dry::Types::PredicateInferrer::TYPE_TO_PREDICATE.key(name)
        Dry::Types[type.name.downcase.delete_suffix("class")]
      when :included_in?
        Avo::Fields::SelectField.new opts.fetch(:key), options: to_args(rest.map { visit(_1, opts) }).index_with(&:itself)
      else
        raise "Unhandled: #{node}"
      end.then do |type|
        ap(opts:, type:, node:, ) if opts.values_at(:and, :implied_by).any?
        return opts[:and] if type.nil?
        case opts[:and]
        when ->(a) { a.respond_to?(:primitive) }
          case opts[:and].primitive.name
          when "Array"
            case type
            when Avo::Fields::SelectField
              Avo::Fields::TagsField.new type.id, suggestions: type.options_from_args.keys, enforce_suggestions: true
            else
              return Avo::Fields::TagsField.new opts.fetch(:key) if type.primitive.name == "String"
              # return opts[:and].of(type)
              # raise "Unhandled array member #{type} (in #{opts[:and]})"
            end
          when "String"
            # type
          when "Hash"
            DrySchemaField.new(opts.fetch(:key), schema: type)
          else
            opts[:and].of(type)
          end
        when Avo::Fields::BaseField
          # opts[:and]
          type
        when nil
          type
        else
          raise "Unhandled and: #{type} #{opts} #{node}"
        end
      end
    end

    def visit_each(node, opts)
      visit(node, opts.merge(member: true))
    end

    def visit_implication(node, opts)
      node.reduce(nil) do |acc, elem|
        visit(elem, opts.merge(implied_by: acc))
      end
    end

    def visit_list(node, opts)
      node
    end

    def visit_input(node, opts)
      node
    end

    def visit_type(node, opts)
      case node.name
      when "ActiveSupport::Duration", "String"
        Avo::Fields::TextField.new opts.fetch(:key)
      else
        raise "Unhandled type: #{node} #{opts}"
      end
    end

    def visit_not(node, opts)
      nil
    end

    def to_args(args)
      args.reject { _1 == Dry::Types::Undefined }.flatten(1)
    end

    def visit_or(node, opts)
      
    end
  end
end
