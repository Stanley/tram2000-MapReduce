# Line on the map between two points
class Segment

  R = 6371 * 1000   # Earth radius in meters
  Rad = 3.142 / 180 # Converts degrees do radians

  # Haversine formula
  def self.length(a, b)
  
    dLat = (b[0] - a[0]) * Rad
    dLon = (b[1] - a[1]) * Rad

    d = Math.sin(dLat / 2) ** 2 +
        Math.cos(a[0] * Rad) * Math.cos(b[0] * Rad) *
        Math.sin(dLon / 2) ** 2
        
    R * 2 * Math.atan2(Math.sqrt(d), Math.sqrt(1-d))
  end

  # Input: two points. Each defined by array: [lat, lng]
  def initialize(a, b)
   @a = a
   @b = b
  end

  # Output: length in meters
  def length
    Segment.length(@a, @b)
  end

  # Finds segment intersecion(s) with circle (ellipse)
  # In case of two points, the one closer to segment will be returned
  # Input: circle center and radius
  # Output: null or [lat, lng] of intersecion
  def intersection(lat, lng, r)
    
    # Convert degrees to meters
    x1 = Segment.length([lat, lng], [lat, @a[1]]) # lng
    x1 *= -1 if lng > @a[1]
#p "Segment.length([#{lat}, #{lng}], [#{lat}, #{@a[1]}]) = #{x1}"

    y1 = Segment.length([lat, lng], [@a[0], lng]) # lat
    y1 *= -1 if lat > @a[0]
#p "Segment.length([#{lat}, #{lng}], [#{@a[0]}, #{lng}]) = #{y1}"
        
    x2 = Segment.length([lat, lng], [lat, @b[1]]) # lng
    x2 *= -1 if lng > @b[1]
#p "Segment.length([#{lat}, #{lng}], [#{lat}, #{@b[1]}]) = #{x2}"

    y2 = Segment.length([lat, lng], [@b[0], lng]) # lat
    y2 *= -1 if lat > @b[0]
#p "Segment.length([#{lat}, #{lng}], [#{@b[0]}, #{lng}]) = #{y2}"
    
    # ???
    # Circle equation: lat**2 + lng**2 = r**2
    # Segment equation: y = y1 + (x-x1)/(x2-x1) * (y2-y1)
    sol = []
    sol.push (-Math.sqrt((-2*x1*y1**2+2*x1*y1*y2+2*x1+2*x2*y1**2-2*x2*y1*y2)**2-4*(-x1**2+2*x1*x2-x2**2-1)*(r**2*x1**2-2*r**2*x1*x2+r**2*x2**2+x1**2*y1**2-2*x1**2*y1*y2-x1**2+2*x1*x2*y1*y2-x2**2*y1**2))+2*x1*y1**2-2*x1*y1*y2-2*x1-2*x2*y1**2+2*x2*y1*y2)/(2*(-x1**2+2*x1*x2-x2**2-1))

    sol.push ( Math.sqrt((-2*x1*y1**2+2*x1*y1*y2+2*x1+2*x2*y1**2-2*x2*y1*y2)**2-4*(-x1**2+2*x1*x2-x2**2-1)*(r**2*x1**2-2*r**2*x1*x2+r**2*x2**2+x1**2*y1**2-2*x1**2*y1*y2-x1**2+2*x1*x2*y1*y2-x2**2*y1**2))+2*x1*y1**2-2*x1*y1*y2-2*x1-2*x2*y1**2+2*x2*y1*y2)/(2*(-x1**2+2*x1*x2-x2**2-1))
    
    # Segment equation
    f = lambda{ |x| y1 + (x-x1)/(x2-x1) * (y2-y1) if (x1..x2).include?(x) || (x2..x1).include?(x) }
    
#    # Solve the simultaneous equations (segment + circle)
#    # y**2 = y1**2 + (x-x1)**2 / (x2-x1)**2 * (y2-y1)**2 + 2*y1 * (x-x1)/(x2-x1) * (x2-y1)
#    _t = (y2-y1)**2 / (x2-x1)**2
#    _u = (y2-y1) / (x2-x1)
#    
#    a = 1 + _t
#    b = -2*x1*_t + 2*y1*_u
#    c = y1**2 + x1**2*_t + 2*y1*(-x1/x2-x1)*_u - r**2
#    
#    # Delta
#    delta = b**2 - 4*a*c
    
    if true #delta > 0
          
      #d = Math.sqrt delta
      # Results
#      [(-b-d) / 2*a,  (-b+d) / 2*a].each do |x|

      sol.each do |x|

        y = f[x] || next

        # What we're really looking for
        intersection_lat = 180*y / (Math::PI * R) + lat
        intersection_lng = 180*x / (R*Math.cos( intersection_lat )) + lng

        return [intersection_lat, intersection_lng]
      end
            
    elsif delta < 0
      p "< 0"
    else
      p "==0"
    end
    
  end

end
