# Encoding: UTF-8

$: << File.join(File.dirname(__FILE__), "/../lib")
require 'blip'

describe Blip do

  describe "init" do
    
    it "should accept Hash and String as an argument" do
      Blip.new({:data=>"ABC", :foo=>:bar }).should eql({:data=>"ABC", :foo=>:bar})
      Blip.new("DEF").should eql({:data => "DEF"})
    end
  
    it "should raise exception on strange argument" do
      lambda{ Blip.new( ["ABC"] )}.should raise_error(ArgumentError)
      lambda{ Blip.new( 500 )}.should     raise_error(ArgumentError)
      lambda{ Blip.new( :abc )}.should    raise_error(ArgumentError)
    end
  end

  describe "encoder" do
    it "should encode simple array of integrs" do
      Blip.encode([1,2,3]).should eql("ABC")
    end
    
    it "should encode simple array of floats by rounding them" do
      Blip.encode([1.1,2.2,3.5]).should eql("ABD")
    end
    
    it "should raise an exeption on array of non-numeric" do
      lambda{
        Blip.encode(["A","B","C"])
      }.should raise_error(ArgumentError)
    end
    
    it "should raise an exeption on non-arrays" do
      lambda{
        Blip.encode("ABC")
      }.should raise_error(ArgumentError)
    end
  end
  
  describe "decoder" do
  
    it "should decode ASCII strings" do
      Blip.new({data: "ABC"}).decode.should eql([1,2,3])
    end
    
    it "should raise an exeption on UTF-8 strings" do
      lambda{
        Blip.new({data: "Źółty"}).decode
      }.should raise_error(ArgumentError)
    end
    
    it "should raise an exeption on non-string" do
      lambda{
        Blip.new({data: ["ABC"]}).decode
      }.should raise_error(ArgumentError)
    end
  
    it "should return the same value after encoding and decoding" do
      Blip.new( Blip.encode((5..50).to_a) ).decode.should eql((5..50).to_a)
      Blip.encode( Blip.new("decoded trace").decode ).should eql("decoded trace")
    end
  end
  
  describe "data" do
  
    it "should return data field" do
      Blip.new( :data => "ABC" ).data.should  eql("ABC")
      Blip.new( 'data' => "ABC" ).data.should eql("ABC")
    end
  
  end
end
