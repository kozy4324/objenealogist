# frozen_string_literal: true

require "test_helper"

class TestObjenealogist < Minitest::Test
  def test_to_tree
    expected = /C Objenealogist \(location: .*objenealogist.rb:7\)/

    assert_match expected, Objenealogist.to_tree(Objenealogist)
  end

  def test_to_tree_with_show_methods_false
    result = Objenealogist.to_tree(MyClass, show_methods: false)

    assert_match(/C MyClass/, result)
    refute_match(/│ .* c\b/, result) # メソッド表示がないこと
  end

  def test_to_tree_with_show_locations_false
    result = Objenealogist.to_tree(MyClass, show_locations: false)

    assert_match(/C MyClass$/, result) # locationが表示されないこと
    refute_match(/\(location:/, result)
  end

  def test_to_tree_with_show_locations_regexp
    result = Objenealogist.to_tree(MyClass, show_locations: /MyClass/)

    assert_match(/C MyClass \(location:/, result)
    assert_match(/M M2$/, result) # M2はRegexpにマッチしないのでlocationなし
  end

  def test_to_tree_includes_modules
    result = Objenealogist.to_tree(MyClass)

    assert_match(/M M1/, result)
    assert_match(/M M2/, result)
  end

  def test_to_tree_includes_superclass
    result = Objenealogist.to_tree(MyClass)

    assert_match(/C NS::C2/, result)
    assert_match(/C C1/, result)
  end

  def test_to_tree_includes_methods
    result = Objenealogist.to_tree(MyClass)

    assert_match(/│ .* c\b/, result) # インスタンスメソッド
    assert_match(/│ .* singleton_c\b/, result) # シングルトンメソッド
  end

  def test_to_tree_includes_inherited_module_methods
    result = Objenealogist.to_tree(MyClass)

    assert_match(/│ .* m1\b/, result)
    assert_match(/│ .* m2\b/, result)
  end

  def test_to_tree_nested_class
    result = Objenealogist.to_tree(NS::C2)

    assert_match(/C NS::C2 \(location:/, result)
    assert_match(/M M4/, result)
    assert_match(/C C1/, result)
  end
end

class TestClassVisitor < Minitest::Test
  def test_visit_class_node
    source = <<~RUBY
      class Foo
      end
    RUBY

    visitor = Objenealogist::ClassVisitor.new([:Foo])
    Prism.parse(source).value.accept(visitor)

    assert_equal 1, visitor.found.size
    assert_equal :Foo, visitor.found.first[0]
  end

  def test_visit_module_node
    source = <<~RUBY
      module Bar
      end
    RUBY

    visitor = Objenealogist::ClassVisitor.new([:Bar])
    Prism.parse(source).value.accept(visitor)

    assert_equal 1, visitor.found.size
    assert_equal :Bar, visitor.found.first[0]
  end

  def test_visit_nested_class
    source = <<~RUBY
      module Outer
        class Inner
        end
      end
    RUBY

    visitor = Objenealogist::ClassVisitor.new([:"Outer::Inner"])
    Prism.parse(source).value.accept(visitor)

    assert_equal 1, visitor.found.size
    assert_equal :"Outer::Inner", visitor.found.first[0]
  end

  def test_visit_multiple_targets
    source = <<~RUBY
      class A; end
      class B; end
      class C; end
    RUBY

    visitor = Objenealogist::ClassVisitor.new(%i[A C])
    Prism.parse(source).value.accept(visitor)

    assert_equal 2, visitor.found.size
    assert_equal %i[A C], visitor.found.map(&:first)
  end

  def test_visit_with_string_target
    source = <<~RUBY
      class Foo; end
    RUBY

    visitor = Objenealogist::ClassVisitor.new(["Foo"]) # 文字列で指定
    Prism.parse(source).value.accept(visitor)

    assert_equal 1, visitor.found.size
  end
end

class TestFormatLocations < Minitest::Test
  def test_format_locations_with_string
    result = Objenealogist.format_locations("/path/to/file.rb:10")

    assert_equal " (location: /path/to/file.rb:10)", result
  end

  def test_format_locations_with_empty_string
    result = Objenealogist.format_locations(":")

    assert_equal "", result
  end

  def test_format_locations_with_nil
    result = Objenealogist.format_locations(nil)

    assert_equal "", result
  end

  def test_format_locations_with_show_locations_false
    result = Objenealogist.format_locations("/path/to/file.rb:10", show_locations: false)

    assert_equal "", result
  end

  def test_format_locations_with_regexp_match
    result = Objenealogist.format_locations("/path/to/file.rb:10", show_locations: /MyClass/, target: "MyClass")

    assert_equal " (location: /path/to/file.rb:10)", result
  end

  def test_format_locations_with_regexp_no_match
    result = Objenealogist.format_locations("/path/to/file.rb:10", show_locations: /MyClass/, target: "OtherClass")

    assert_equal "", result
  end

  def test_to_tree_from_class
    expected = Objenealogist.to_tree(MyClass)
    result = MyClass.to_tree

    assert_equal expected, result
  end

  def test_to_tree_accepts_object
    obj = MyClass.new
    expected = Objenealogist.to_tree(MyClass)
    result = Objenealogist.to_tree(obj)

    assert_equal expected, result
  end
end
