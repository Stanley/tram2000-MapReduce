# Line on the map between two points
class Segment

  R = 6371 * 1000   # Earth radius in meters
  Rad = Math::PI / 180 # Converts degrees do radians

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

  # Finds segment intersecion(s) with circle
  # In case of two points, the one closer to segment beginning (@a) will be returned
  # Input: circle center and radius
  # Output: null or [lat, lng] of intersecion
  def intersection(lat, lng, r)
    
    # Convert degrees to meters
    x1 = Segment.length([lat, lng], [lat, @a[1]]) # lng
    x1 *= -1 if lng > @a[1]

    y1 = Segment.length([lat, lng], [@a[0], lng]) # lat
    y1 *= -1 if lat > @a[0]
        
    x2 = Segment.length([lat, lng], [lat, @b[1]]) # lng
    x2 *= -1 if lng > @b[1]

    y2 = Segment.length([lat, lng], [@b[0], lng]) # lat
    y2 *= -1 if lat > @b[0]
    
    # Circle equation: lat**2 + lng**2 = r**2
    # Segment equation: lat = y1 + (lng-x1)/(x2-x1) * (y2-y1)
    # See also: http://mathworld.wolfram.com/Circle-LineIntersection.html
    
    dx = x2 - x1
    dy = y2 - y1
    dr = Math.sqrt(dx**2 + dy**2) # Caution: this is estimation
    d = x1*y2 - x2*y1    
    delta = r**2 * dr**2 - d**2    

    sgn = lambda{ |x| x < 0 ? -1 : 1 }
    coordinates = lambda do |sign|
      x = (d*dy + sign * sgn[dy] * dx * Math.sqrt(delta)) / dr**2
      y = (-d*dx + sign * dy.abs * Math.sqrt(delta)) / dr**2

      intersection_lat = 180*y / (Math::PI * R) + lat
      intersection_lng = x / ( Math.cos(intersection_lat*Rad)*R) * (180/Math::PI) + lng
      
      [intersection_lat, intersection_lng] if (@a[1]..@b[1]).include?(intersection_lng) || (@b[1]..@a[1]).include?(intersection_lng)
    end
    
    if delta > 0
      # Return closest point (to point @a) of two
      [-1, 1].map{ |sign| coordinates[sign] }.compact.sort_by{|x,y| y }.first
    elsif delta == 0
      # Tangent line: only one point
      coordinates[0]
    else
      # No intersecting points
      nil
    end
  end
end
