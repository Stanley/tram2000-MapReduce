RSpec::Matchers.define :be_similar do |expected, delta|
  match do |actual|
    actual.flatten.zip(expected.flatten).map do |a,b|
      (a-b).abs
    end.all?{|z| z < delta}
  end

  description do
    "each value should be +/- #{delta}"
  end

  failure_message_for_should do |actual|
    "expected that each value in #{actual} would be +/- #{delta} close to #{expected}"
  end
end