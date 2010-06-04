$: << File.join(File.dirname(__FILE__), "/../lib") 
require 'kanar'

class Blip
  def self.new(args)
    defaults = {:user => "anonym", :time => Time.new.to_i}
    super(defaults.merge(args))
  end
end

describe Kanar do
  describe "mean" do
    it "should calculate the mean" do
      Kanar.mean([Blip.new(:data => Blip.encode([0,1,2,3])), Blip.new(:data => Blip.encode([0,3,4,5]))]).should eql([0,2,5,9])
    end

    it "should calculate the mean and cut of waiting time" do
      Kanar.mean([Blip.new(:data => Blip.encode([1,-1,1,2,3])), Blip.new(:data => Blip.encode([2,-1,-1,3,4,5]))]).should eql([0,2,5,9])
    end
    
    it "should return trace starting from departure" do
      Kanar.mean([Blip.new(:data => Blip.encode([1,-1,1,1,2,1])), Blip.new(:data => Blip.encode([3,-3,1,1,2,1]))]).should eql([0,1,2,4,5])
    end
  end
    
  describe "validation" do
    it "should calculate waiting time for each blip owner" do
      Kanar.validate( "",
                      [
                        Blip.new({ :data => Blip.encode([1,0,0,0,0,0,0,0,0,0,-1,1,1,1,2,3,4,3,3,3,2,1,0]), :user => "foo" }),
                        Blip.new({ :data => Blip.encode([0,0,0,1,1,1,2,3,4,3,3,3,2,1,0]), :user => "bar" })
                      ]
                    )[:pass].should eql({
                      "foo" => 10,
                      "bar" => 2
                    })
    end
    
    it "should discard fake blips" do
      Kanar.validate( "",
                      Array.new(10, Blip.new(:data => Blip.encode([-2,0,-2,1,1,1,2,2,2,3,1,2,4,5,6,3,2,1,0,0,0,0,1,1,2,3,1]))) + [
                        Blip.new({ :data => Blip.encode([1,0,0,0,0,0,0,0,0,0,-1,1,1,1,2,3,4,3,3,3,2,1,0]), :user => "foo" }),
                        Blip.new({ :data => Blip.encode([0,0,0,1,1,1,2,3,4,3,3,3,2,1,0]), :user => "bar" })
                      ]
                    )[:fake].should eql(["foo", "bar"])
    end
  end
  
  describe "-ek" do
    it "should tell the time of departure" do
      beg = Time.now.to_i
      
      Kanar.validate(nil, [Blip.new(:data => Blip.encode( Array.new(10,1) ), :time => beg)])[:time].should eql(beg)
      
      Kanar.validate(nil, [Blip.new(:data => Blip.encode( [2,0,-2] + Array.new(9,1) ), :time => beg-2)])[:time].should eql(beg)
      
      Kanar.validate(nil, [
        Blip.new(:data => Blip.encode( [2,0,-2] + Array.new(9,1) ), :time => beg-2),
        Blip.new(:data => Blip.encode( [1,1,0,0,0,0,0,-2] + Array.new(9,1) ), :time => beg-7),
        Blip.new(:data => Blip.encode( [0,2,1,0,0,-2,0,1,0,0,-2] + Array.new(9,1) ), :time => beg-10)
      ])[:time].should eql(beg)
    end
    
    it "should return array of relative (to path) distances ridden in each second" do
      # Straight line
      Kanar.validate("foo:" + Polyline.new.encode([[50,20],[50,21]])[:points], [Blip.new(:data => Blip.encode( Array.new(60,1) ))])[:footprint].should eql( Array.new(60,1) )
      
      # Go straight (for 40 sec) and go back (for 20 sec)
      Kanar.validate("foo:" + Polyline.new.encode([[50,20],[50,21]])[:points], [Blip.new(:data => Blip.encode( Array.new(40,1) + Array.new(20,-1) ))])[:footprint].should eql( Array.new(60,1) )
      
      # Go straight and turn left
    end
  
    it "sum of distances should be equal to the length of path" do
      points = Polyline.new.encode([[50,20],[50,21],[51,21]])[:points]
      Kanar.validate("foo:" + points, [Blip.new(:data => Blip.encode( Array.new(60,1) ))])[:footprint].size.should eql( Polyline.decode(polyline).size )
    end
  end
end
