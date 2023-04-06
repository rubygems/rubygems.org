class Dry::StructCompiler
  attr_reader :struct, :debug

  # @api private
  def initialize(struct, debug: false)
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
      (Rails.logger.debug { "#{'  ' * opts[:level]}| " }
       Rails.logger.debug({ meth:, rest:, opts: }, multiline: false))
    end
    public_send(:"visit_#{meth}", rest, opts.merge(level: opts[:level] + 1)).tap do
      if debug
        (Rails.logger.debug { "#{'  ' * opts[:level]}-> " }
         Rails.logger.debug(_1, multiline: false))
      end
    end
  end

  # @api private
  def visit_set(node, opts = {})
    if opts[:pred] && opts[:holder]
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
        acc & nelem
      elsif nelem
        nelem
      else
        acc
      end
    end
  end

  def visit_implication(node, opts)
    node.reduce(nil) do |acc, el|
      visit(el, **opts, implication: acc, required: false)
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
          Dry::Types::PredicateInferrer::TYPE_TO_PREDICATE.key(name)
        when :filled?
          return
        when :included_in?
          return opts[:pred].enum(*remove_undefined(rest.map { visit(_1, opts) }.flatten(1)))
        when :type?
          return Dry.Types.Nominal(*remove_undefined(rest.map { visit(_1, opts) }))
        else
          return opts[:pred].constrained(name.to_s.chomp("?").to_sym => remove_undefined(rest.map { visit(_1, opts) }).sole) if opts[:pred]
          raise "Unknown predicate #{name}"
        end
      Dry::Types[type.name.downcase.delete_suffix("class")]
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
    Dry::Logic::Operations::Negation.new visit(node, opts).rule
  end

  def visit_key(node, opts = {})
    name, rest = node

    req = opts.delete(:required) { true }

    holder = opts.fetch(:holder, {}).merge(name => {})
    type = visit(rest, opts.merge(key: name, holder:))
    blk = holder[name][:blk]
    type = Dry::Types::Undefined if blk && !type.primitive.equal?(::Array)

    method = req ? :attribute : :attribute?
    @struct.public_send(method, name, type, &blk)
    nil
  end

  def visit_each(node, opts)
    opts[:holder][opts[:key]][:blk] = lambda {
      c = Dry::StructCompiler.new(self)
      c.visit(node, **opts.slice(:level))
    }
    nil
  end

  def remove_undefined(a)
    a.reject { _1 == Dry::Types::Undefined }
  end

  def visit_num(node, _opts)
    node
  end

  def visit_regex(node, _opts)
    node
  end
end
