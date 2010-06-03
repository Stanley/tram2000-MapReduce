require "decoder"
require "segment"
require "blip"

# This class is responsible for validating input data
class Kanar

  # Input: polyline and Array of blips
  # Output: trace
  # Trace is a Hash with following properties:
  # * beg - id of begining stop
  # * end - id of ending stop
  # * time - time when vehicle left _beg_
  # * pass - Hash of users who send valid blips. Keys are seconds spend waiting for vehicle
  # * fail - Array of users who send rubbish
  # * foootprint
  def self.validate(polyline, blips)
    
    # Output value
    trace = {}
    
    # Hash which remembers how much time has each passenger waited
    passengers = {} 
        
    # Average blip
    footprint = mean(blips)

    # Calculate waiting time for each user and cut it out
    trace[:pass] = {}
    blips.each do |blip|
      trace[:pass][blip[:user]] = blip.data.size - footprint.size
    end      

    trace[:footprint] = Blip.encode footprint
    
    # Get rid of fake blips 

    
    # Convert absolute distance values to array of distances on the path
    # going from end to begining
#    steps = Polyline.decode(polyline).reverse # polyline.gsub("\\\\", "\\") 
#    avg.reverse!
#    
#    enum = steps.each_cons(2) # polyline enumerator
#    length = 0 # how far we are form stop A in straight line
#    dist = 0   # how far is the latest segment from the beginning


#    # Calculates footprint (lat-lng pairs)
#    footprint = []
#    
#    # For each second
#    avg.each do |m|
#      length += m
#      
#      # Find appropriate segnent
#      seg = nil
#      while length > dist
#        seg = Segment.new enum.next
#        dist = beg.to seg.last
#      end
#      
#      # Calculate point of segment in which we are now
#      # steps.last stans for location of beginning stop
#      seg.intersection *steps.last, length
#      
#      # TODO: what if null?
#                  
#    end
    trace
  end
  
  # Mean values of all blips data
  # Returns mean, absolute distances form begining stop without waiting time
  def self.mean(blips)
  
    # Cumulated values of each blip
    sum = []
      
    blips.map{|blip| Blip.new blip}.each do |blip|
      blip.decode.reverse.each.with_index do |byte,i|
        sum[i] ||= 0    
        sum[i] += byte
      end
    end
  
    avg = sum.map{|b| (b/blips.size).round }.reverse
    
    sum = 0 
    acc = avg.map{|d| sum += d }
    min = acc.min
    acc.drop_while{|b| b != min}
  end
end
