# frozen_string_literal: true

require "prism"

require_relative "objenealogist/version"

class Objenealogist
  class ClassVisitor < Prism::Visitor
    attr_reader :found

    def initialize(target_class_names)
      @target_class_names = target_class_names.map(&:to_s).map(&:to_sym)
      @found = []
      @stack = []
    end

    def visit_class_node(node)
      @stack << node.name
      name = @stack.join("::").to_sym
      @found << [name, node.location] if @target_class_names.include?(name)
      super
      @stack.pop
    end

    alias visit_module_node visit_class_node
  end

  class << self
    def to_tree(clazz, show_methods: true, show_locations: true)
      # ruby -r./lib/objenealogist -e 'puts Objenealogist.to_tree(Objenealogist)'
      process_one(clazz, show_methods:, show_locations:).join("\n")
    end

    def process_one(clazz, result = [], location_map = create_location_map(clazz), indent = "", show_methods: true,
                    show_locations: true)
      locations = location_map[clazz.to_s.to_sym]

      result << "#{indent}C #{clazz}#{format_locations(locations, show_locations:)}" if indent == ""
      if locations && locations[:methods] && show_methods
        locations[:methods].sort { |a, b| a[2] <=> b[2] }.each_with_index do |method, index|
          m, path, line = method
          mark = locations[:methods].size - 1 == index ? "└" : "├"
          result << "#{indent}│   #{mark} #{m}#{format_locations("#{path}:#{line}", show_locations:)}"
        end
        result << "#{indent}│"
      end

      (clazz.included_modules - (clazz.superclass&.included_modules || [])).each do |mod|
        locations = location_map[mod.to_s.to_sym]
        result << "#{indent}├── M #{mod}#{format_locations(locations, show_locations:)}"
        if locations && locations[:methods] && show_methods # rubocop:disable Style/Next
          locations[:methods].sort { |a, b| a[2] <=> b[2] }.each_with_index do |method, index|
            m, path, line = method
            mark = locations[:methods].size - 1 == index ? "└" : "├"
            result << "#{indent}|   #{mark} #{m}#{format_locations("#{path}:#{line}", show_locations:)}"
          end
          result << "#{indent}|"
        end
      end

      if clazz.superclass
        locations = location_map[clazz.superclass.to_s.to_sym]
        result << "#{indent}└── C #{clazz.superclass}#{format_locations(locations, show_locations:)}"
        process_one(clazz.superclass, result, location_map, "    #{indent}", show_methods:, show_locations:)
      else
        result
      end
    end

    def format_locations(locations, show_locations: true)
      if locations.is_a?(String)
        if locations != ":0" && show_locations
          " (location: #{locations})"
        else
          ""
        end
      elsif locations && locations[:locations]&.any? && show_locations
        " (location: #{locations[:locations].map { |path, loc| "#{path}:#{loc.start_line}" }.join(", ")})"
      else
        ""
      end
    end

    def create_location_map(clazz)
      instance = clazz.allocate
      methods = clazz.methods + instance.methods
      source_locations = methods.map do |m|
        if clazz.respond_to?(m) && clazz.method(m).source_location
          [m] + clazz.method(m).source_location
        elsif instance.respond_to?(m) && instance.method(m).source_location
          [m] + instance.method(m).source_location
        end
      end.compact
      location_map = {}
      source_locations.uniq { |_, path,| path }.each do |method, path, line|
        next unless File.exist?(path)

        source = File.open(path).read
        visitor = ClassVisitor.new(clazz.ancestors)
        Prism.parse(source).value.accept(visitor)
        visitor.found.each do |name, def_location|
          (location_map[name] ||= { name: name, locations: [], methods: [] })[:locations] << [path, def_location]
        end
      end
      source_locations.uniq(&:join).each do |m, path, line|
        locations = location_map.values.find do |location|
          location[:locations].any? do |_path, loc|
            path == _path && loc.start_line <= line && line <= loc.end_line
          end
        end
        if locations
          locations[:methods] << [m, path, line]
        else
          location_map[clazz.to_s.to_sym]&.[](:methods)&.<< [m, nil, 0]
        end
      end
      # {M1:
      #   {name: :M1,
      #    locations: [["objenealogist.rb", (122,0)-(124,3)]],
      #    methods: [[:m1, "objenealogist.rb", 123]]}}
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

module NS
  class C2 < C1
    include M4
    def c2 = :c2
  end
end

class MyClass < NS::C2
  include M1
  include M2
  def c = :c
  def self.singleton_c = :singleton_c
end
