$: << File.dirname(__FILE__)
require 'spec_helper'

describe Kanar do
  describe "validation" do
    # Journey from A to B through C (111m+71m)
    before :all do
      encoder = GoogleMapsPolyline::Encoder.new StringIO.new
      @trace = Kanar.validate( "1:" + encoder.encode_points([[50_00000, 20_00000],[50_00100, 20_00000],[50_00100, 20_00100]]).string,[
        Blip.new({ 'data' => Blip.encode([1, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 22, 22, 22, 22, 23, 1, 2, 5, 6, 7]), 'user' => "foo", 'time' => Time.parse("26.06.2010 16:30:02").to_i }),
        Blip.new({ 'data' => Blip.encode([0, 0, 0, 22, 22, 22, 22, 23, 1, 2, 5, 6, 7]), 'user' => "bar", 'time' => Time.parse("26.06.2010 16:30:10").to_i }),
        Blip.new({ 'data' => Blip.encode([0, 0, 0, 3, 6, 1, 9, 4, 2, 8, 5, 4, 7]), 'user' => "fake", 'time' => Time.parse("26.06.2010 16:30:10").to_i }),
        Blip.new({ 'data' => Blip.encode([0, 0, 0, 3, 6, 1, 9, 4, 2, 8, 5, 4, 7, 3, 6, 8]), 'user' => "fake2", 'time' => Time.parse("26.06.2010 16:30:10").to_i }),
        Blip.new({ 'data' => Blip.encode([0, 0, 0, 22, 22, 22, 22, 23, 1, 2, 5, 6, 7]), 'user' => "fake3", 'time' => Time.parse("26.06.2010 16:20:10").to_i })
      ])
    end

    it "should return polyline id" do
      @trace['polyline_id'].should eql("1")
    end

    it "should estimate departure time" do
      @trace['time'].should eql(Time.parse("26.06.2010 16:30:13").to_i)
    end
    
    it "should discard fake blips" do
      @trace['polluters'].should eql(["fake", "fake2", "fake3"])
    end

    it "should calculate waiting time for each valid blip submitter" do
      @trace['commuters'].should eql({"foo"=>11, "bar"=>3})
    end
    
    it "should tell where the vehicle was in each second" do
      @trace['points'].should be_similar([
        [50.0002, 20.0],
        [50.0004, 20.0],
        [50.0006, 20.0],
        [50.0008, 20.0],
        [50.001, 20.0],
        [50.001, 20.0002],
        [50.001, 20.0004],
        [50.001, 20.0006],
        [50.001, 20.0008],
        [50.001, 20.001]
      ], 0.00005)
    end
  end
end
