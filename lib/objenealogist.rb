# frozen_string_literal: true

require "prism"

require_relative "objenealogist/version"

class Objenealogist
  class ClassVisitor < Prism::Visitor
    attr_reader :found

    def initialize(target_class_names)
      @target_class_names = target_class_names.map(&:to_s).map(&:to_sym)
      @found = []
    end

    def visit_class_node(node)
      @found << [node.name, node.location] if @target_class_names.include?(node.name)
      super
    end

    alias visit_module_node visit_class_node
  end

  class << self
    def to_tree(clazz)
      # ruby -r./lib/objenealogist -e 'puts Objenealogist.to_tree(Objenealogist)'
      process_one(clazz).join("\n")
    end

    def process_one(clazz, result = [], location_map = create_location_map(clazz), indent = "")
      if indent == ""
        locations = location_map[clazz.to_s.to_sym]
        result << "#{indent}C #{clazz}" + (locations&.any? ? " (location: #{locations.join(", ")})" : "")
      end

      (clazz.included_modules - (clazz.superclass&.included_modules || [])).each do |mod|
        locations = location_map[mod.to_s.to_sym]
        result << "#{indent}├── M #{mod}" + (locations&.any? ? " (location: #{locations.join(", ")})" : "")
      end

      if clazz.superclass
        locations = location_map[clazz.superclass.to_s.to_sym]
        result << "#{indent}└── C #{clazz.superclass}" + (locations&.any? ? " (location: #{locations.join(", ")})" : "")
        process_one(clazz.superclass, result, location_map, "    #{indent}")
      else
        result
      end
    end

    def create_location_map(clazz)
      instance = clazz.allocate
      methods = clazz.methods + instance.methods
      source_locations = methods.map do |m|
        if clazz.respond_to?(m)
          clazz.method(m).source_location&.first
        elsif instance.respond_to?(m)
          instance.method(m).source_location&.first
        end
      end.compact.uniq
      location_map = {}
      source_locations.each do |source_location|
        next unless File.exist?(source_location)

        source = File.open(source_location).read
        visitor = ClassVisitor.new(clazz.ancestors)
        Prism.parse(source).value.accept(visitor)
        visitor.found.each do |name, class_def_location|
          (location_map[name] ||= []) << "#{source_location}:#{class_def_location.start_line}"
        end
      end
      location_map
    end
  end
end

module M1
  def m1 = :m1
end

module M2
  def m2 = :m2
end

module M3
  def m3 = :m3
end

module M4
  include M3
  def m4 = :m4
end

module M5
  def m5 = :m5
end

class C1
  include M5
  def c1 = :c1
end

class C2 < C1
  include M4
  def c2 = :c2
end

class MyClass < C2
  include M1
  include M2
  def c = :c
end
