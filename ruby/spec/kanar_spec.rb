$: << File.join(File.dirname(__FILE__), "/../lib") 
require 'kanar'

describe Kanar do
  describe "validation" do
  
    it "should calculate the mean" do
      Kanar.mean([Blip.new(Blip.encode([0,1,2,3])), Blip.new(Blip.encode([0,3,4,5]))]).should eql([0,2,5,9])
    end

    it "should calculate the mean and cut of waiting time" do
      Kanar.mean([Blip.new(Blip.encode([1,-1,1,2,3])), Blip.new(Blip.encode([2,-1,-1,3,4,5]))]).should eql([0,2,5,9])
    end
    
    it "should return trace starting from departure" do
      Kanar.mean([Blip.new(Blip.encode([1,-1,1,1,2,1])), Blip.new(Blip.encode([3,-3,1,1,2,1]))]).should eql([0,1,2,4,5])
    end
    
    it "should calculate waiting time for each blip owner" do
    
      Kanar.validate( nil,
                      [
                        Blip.new({ :data => Blip.encode([1,0,0,0,0,0,0,0,0,0,-1,1,1,1,2,3,4,3,3,3,2,1,0]), :user => "foo" }),
                        Blip.new({ :data => Blip.encode([0,0,0,1,1,1,2,3,4,3,3,3,2,1,0]), :user => "bar" })
                      ]
                    )[:pass].should eql({
                      "foo" => 10,
                      "bar" => 2
                    })
    
    end
    
    it "should discard fake blips"
  
  end
end
