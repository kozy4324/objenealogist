# frozen_string_literal: true

require "prism"

require_relative "objenealogist/version"

class Objenealogist
  class ClassVisitor < Prism::Visitor
    attr_reader :found

    def initialize(target_class_name)
      @target_class_name = target_class_name.to_s.to_sym
      @found = []
    end

    def visit_class_node(node)
      @found << node.location if node.name == @target_class_name
      super
    end
  end

  class << self
    def to_tree(clazz)
      # @ ClassNode (location: (1,0)-(3,3))
      # ├── flags: newline
      # ├── locals: []
      # ├── class_keyword_loc: (1,0)-(1,5) = "class"
      # ├── constant_path:
      # │   @ ConstantReadNode (location: (1,6)-(1,13))
      # │   ├── flags: ∅
      # │   └── name: :Article
      locations = search_class_def_location(clazz)

      "C #{clazz} (location: #{locations.join(", ")})"
    end

    def search_class_def_location(clazz)
      instance = clazz.allocate
      methods = clazz.methods(false) +
                instance.public_methods(false) +
                instance.private_methods(false) +
                instance.protected_methods(false)
      source_locations = methods.map do |m|
        if clazz.respond_to?(m)
          clazz.method(m).source_location.first
        elsif instance.respond_to?(m)
          instance.method(m).source_location.first
        end
      end.compact.uniq
      source_locations.map do |source_location|
        source = File.open(source_location).read
        visitor = ClassVisitor.new(clazz)
        Prism.parse(source).value.accept(visitor)
        visitor.found.map { |class_def_location| "#{source_location}:#{class_def_location.start_line}" }
      end.flat_map.compact
    end
  end
end
