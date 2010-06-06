require "polyline"
require "segment"
require "blip"

# This class is responsible for validating input data
class Kanar

  # Input: polyline and Array of blips
  # Output: trace
  # Trace is a Hash with following properties:
  # * poly_id - id of polyline connecting two stops
  # * time - time when vehicle left beginning stop
  # * pass - Hash of users who send valid blips. Keys are seconds spend waiting on the stop
  # * fake - Array of users who send rubbish
  # * footprint
  def self.validate(polyline, blips)
    
    # Output value
    trace = {}
    
    # Hash which remembers how much time has each passenger waited
    passengers = {} 
        
    # Average (decoded) blip
    footprint = mean(blips)

    # Calculate waiting time for each user and cut it out
    trace[:pass] = {}
    trace[:fake] = []
    avg_start_time = 0
    
    blips.each do |blip|
      if true
        waited_seconds = blip.data.size - footprint.size
        trace[:pass][blip[:user]] = waited_seconds
        avg_start_time += blip[:time] + waited_seconds
      else # Get rid of fake blips 
        trace[:fake].push blip[:user]
      end
    end   
    
    trace[:time] = avg_start_time / blips.size

    # Recalculate average blip (without fakes)
    
    trace[:footprint] = []
    # Convert absolute distance values to array of relative distances to the path
    polyline_id, polyline_encoded = polyline.split(":")
    steps = Polyline.decode(polyline_encoded) # polyline.gsub("\\\\", "\\") 
    
    enum = steps.each_cons(2) # polyline enumerator, gives me each segment in the path
    seg = nil # current segment
    dist_a = 0 # distance from the begining to the first point of current segment
    dist_c = (seg = Segment.new( *enum.next )).length # distance from the begining to the last point of current segment
    pos = steps.first
     
    # For each second give me distance (dist_b) from the begining
    footprint.each do |dist_b|
       
      # Find appropriate segnent
      while not (dist_a..dist_c).include? dist_b
        seg = Segment.new enum.next
        dist_a = Segment.length( steps.first, seg.first )
      end
       
      # Calculate point of segment in which we are now
      # steps.last stans for location of beginning stop
      trace[:footprint] << Segment.length( pos, pos = seg.intersection( *steps.first, dist_b ) ).round
       
      # TODO: what if null?
       
    end
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
