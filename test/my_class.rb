# frozen_string_literal: true

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
