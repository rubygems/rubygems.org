class Dry::StructCompiler
  attr_reader :struct, :debug

  # @api private
  def initialize(struct, debug: true)
    @struct = struct
    @debug = debug
  end

  def self.add_attributes(struct:, schema:)
    new(struct).call(schema.ast)
  end

  # @api private
  def call(ast)
    visit(ast, { level: 0 })
  end

  # @api private
  def visit(node, opts = {})
    meth, rest = node
    if debug
      print "#{'  ' * opts[:level]}| "
      ap({ meth:, rest:, opts: }, multiline: false)
    end
    public_send(:"visit_#{meth}", rest, opts.merge(level: opts[:level] + 1)).tap do
      if debug
        print "#{'  ' * opts[:level]}-> "
        ap(_1, multiline: false)
      end
    end
  end

  # @api private
  def visit_set(node, opts = {})
    if (opts[:pred] && opts[:holder]) || opts[:each]
      opts[:holder][opts[:key]][:blk] = lambda {
        c = Dry::StructCompiler.new(self)
        node.map { c.visit(_1, **opts.slice(:level)) }
      }
      return
    end
    visit_and(node, opts)
  end

  def visit_and(node, opts = EMPTY_HASH)
    node.reduce(nil) do |acc, elem|
      nelem = visit(elem, **opts, pred: acc)
      if acc && nelem
        case [acc, nelem]
        in [*, Dry::Types::Undefined]
          nelem
        in [Dry::Types::Undefined, *]
          acc
        in Dry::Types::Type, Dry::Types::Constrained
          nelem
        in [Dry::Types::Type, *]
          acc & nelem
        else
          Dry::Schema::TypesMerger.new.(Dry::Logic::Operations::And, acc, nelem)
        end
      elsif nelem
        nelem
      else
        acc
      end
    end
  rescue
    ap(node:, opts:)
    raise
  end

  def visit_implication(node, opts)
    v = remove_undefined(node.map { visit(_1, **opts, required: false) })
    if v.first.nil?
      v.last
    elsif v.last.nil?
      v.first
    elsif node.first == [:not, [:predicate, [:nil?, [[:input, Dry::Types::Undefined]]]]]
      # maybe
      v.last
    else
      Dry::Schema::TypesMerger.new.(Dry::Logic::Operations::Implication, *v)
    end
  end

  def visit_predicate(node, opts = {})
    name, rest = node

    if name.equal?(:key?)
      nil
    else
      type =
        case name
        when :hash?
          ::Hash
        when :array?
          ::Array
        when *Dry::Types::PredicateInferrer::TYPE_TO_PREDICATE.values
          return Dry::Types[Dry::Types::PredicateInferrer::TYPE_TO_PREDICATE.key(name).name.downcase.delete_suffix("class")]
        when :lteq?, :gteq?
          opts[:pred]
        when :filled?
          return opts[:pred]&.constrained(filled: true)
        when :included_in?
          return opts[:pred].enum(*remove_undefined(rest.map { visit(_1, opts) }.flatten(1)))
        when :type?
          return Dry.Types.Nominal(*remove_undefined(rest.map { visit(_1, opts) }))
        else
          return opts[:pred].constrained(name.to_s.chomp("?").to_sym => remove_undefined(rest.map { visit(_1, opts) }).sole) if opts[:pred]
          raise "Unknown predicate #{name}"
        end
      Dry::Types::Nominal[type].new(type)
    end
  end

  def visit_list(node, _opts)
    node
  end

  def visit_type(node, _opts)
    node
  end

  def visit_input(node, _opts)
    node
  end

  def visit_not(node, opts)
    Dry::Logic::Operations::Negation.new visit(node, opts)
  end

  def visit_key(node, opts = {})
    name, rest = node

    req = opts.delete(:required) { true }

    holder = opts.fetch(:holder, {}).merge(name => {})
    type = visit(rest, opts.merge(key: name, holder:))
    blk = holder[name][:blk]
    type = Dry::Types::Undefined if blk && !array?(type)

    method = req ? :attribute : :attribute?
    @struct.public_send(method, name, type, &blk)
    type
  end

  def visit_each(node, opts)
    # ap(each: node)
    opts[:holder][opts[:key]][:blk] = lambda {
      c = Dry::StructCompiler.new(self)
      c.visit(node, **opts.slice(:level))
    }
    nil
    # visit(node, opts.merge(each: true))
  end

  def remove_undefined(elem)
    elem.reject { _1 == Dry::Types::Undefined }
  end

  def visit_num(node, _opts)
    node
  end

  def visit_regex(node, _opts)
    node
  end

  def visit_or(node, opts)
    # TODO: handle overlaps
    node[0, 1].map { visit(_1, opts) }.reduce(&:|)
  end

  def array?(type)
    return type.primitive == ::Array if type.respond_to?(:primitive)

    case type
    when Dry::Types::Intersection
      a = [type.left, type.right].map { array?(_1) }.uniq
      raise "#{type} has multiple values for array? #{a}" if a.size > 1
      a.sole
    when NilClass
      false
    else
      raise "Unhandled type #{type} (#{type.class})"
    end
  end
end
