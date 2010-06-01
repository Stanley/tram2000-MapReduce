# Krok 0
# Wywołanie: ruby factory.rb <liczba linii> <liczba pasażerów>

lines_count = ARGV[0].to_i
passengers_count = ARGV[1].to_i

raise ArgumentError unless passengers_count and lines_count 

def distance(start, finish)
  r = 6371
  to_rad = 3.142 / 180
  d_lat = (finish.lat - start.lat) * to_rad
  d_lng = (finish.lng - start.lng) * to_rad
  a = Math.sin(d_lat / 2) * Math.sin(d_lat / 2) +
      Math.cos(start.lat * to_rad) * Math.cos(finish.lat * to_rad) *
      Math.sin(d_lng / 2) * Math.sin(d_lng / 2)
  c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
  r * c * 1000
end

db = CouchRest.database("http://Wasiutynski:staszek@db.wasiutynski.net/blips_development")
date = Time.now

timetables = []
all_lines = Line.by_no :startkey => [1], :endkey => [100]

# Chose lines_count random lines
lines_count.times do |i|
  line = all_lines.sample
  line.timetables[0..-2].each do |timetable|
    timetables.push timetable
  end
  # lines.push line['destination']
end

passengers_count.times do
  begin
    blip = {}
    timetable = timetables.sample
    r = Kernel.rand( timetable.minutes(date).size )
    speed = timetable.speed(date, r)*60

    blip['time'] = timetable.arrival(date, r).to_i
    blip['beg'] = timetable.stop_id
    blip['end'] = timetable.nextinline.stop_id

    distance = distance( timetable.stop, timetable.nextinline.stop )
    duration = speed + Kernel.rand(speed/2) - (speed/4)
    position = 0
    data = ""

    duration.times do |i|
      step = (distance - position) / (duration - i)
      step = (step + Kernel.rand(step/2) - (step/4)).round
      data += (step + 64).chr
      position += step
    end
    blip['data'] = data
    blip['owner'] = "Anonymus"
    p db.save_doc( blip )
  rescue
    p $!
  end

end


