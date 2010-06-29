$: << File.join(File.dirname(__FILE__), "/.")
require 'spec_helper'

PERIMETER = 40_041_455

describe Segment do
  describe "length" do
    it "should return 0 for point" do
      segment = Segment.new([50.0, 20.0],[50.0, 20.0])
      segment.length.should == 0
    end
    
    it "should return length in meters" do
      segment = Segment.new([50.0, 20.0],[51.0, 20.0])
      segment.length.should be_close PERIMETER/360, 50
      
      segment = Segment.new([0, 0],[0, 1])
      segment.length.should be_close PERIMETER/360, 50
    end
  end
  
  describe "intersection" do
    it "should find one intersection with circle (tangent)" do
      segment = Segment.new([1, -1],[1, 1])
      segment.intersection(0, 0, Segment.length([0,0],[1,0])).should eql([1,0])
    end
    
    it "should return null value when there is no intersection" do
      segment = Segment.new([50.0, 20.0],[51.0, 21.0])
      segment.intersection(49.0, 19.0, 50_000).should be_nil
      segment.intersection(50.0, 21.0, 30_000).should be_nil
    end
    
    it "should return one intersection with circle when segments begins inside and ends outside" do   
      segment = Segment.new([50.0, 20.0],[51.0, 21.0])
      segment.intersection(50.0, 20.0, segment.length/2).should be_similar([50.5, 20.5], 0.005)
    end

    it "should not return intersection outside the segment" do
      seg = Segment.new([50.001, 20], [50, 20])
      seg.intersection(50, 20, 22).first.should be_close(50.0005, 0.0005)
    end
    
    it "should return one, closest intersection when there are two intersections (secant)" do
      segment = Segment.new([50.0, 20.0],[54.0, 24.0])
      segment.intersection(52, 22, segment.length/4).should be_similar([51, 21], 0.05)
      
      segment = Segment.new([54.0, 24.0], [50.0, 20.0])
      segment.intersection(52, 22, segment.length/4).should be_similar([53, 23], 0.05)
      
      segment = Segment.new([50.0, 20.0],[52.0, 22.0])
      segment.intersection(51, 21, segment.length/2).should be_similar([50, 20], 0.005)
    end
  end
end
