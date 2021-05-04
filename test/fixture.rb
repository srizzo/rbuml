class BaseClassA
  def base_method_a; end
end

class A < BaseClassA
  def method_a
    private_method_a
    base_method_a
    A.class_method_a
    B.new.method_b(1, a: 2)
  end

  def self.class_method_a; end

  def private_method_a; end
end

class B
  def method_b(_a, _b)
    C.new.method_c
    C.class_method_c
  end
end

class C
  def method_c
    'Inside c!'
  end

  def self.class_method_c
    'Inside class method c!'
  end
end

puts A.new.method_a
