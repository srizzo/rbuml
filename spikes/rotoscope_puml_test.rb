require 'rotoscope'

class Dog
  def bark
    Noisemaker.speak('woof!')
  end
end

class Noisemaker
  def self.speak(str)
    puts(str)
  end
end

log_file = File.expand_path('dog_trace.csv')
puts "Writing to #{log_file}..."

Rotoscope::CallLogger.trace(log_file) do
  dog1 = Dog.new
  dog1.bark
end
