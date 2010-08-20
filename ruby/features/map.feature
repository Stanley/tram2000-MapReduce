Feature: mapper

  In order to reconstruct geo locations of each vehicle
  As a cron job
  I want to parse user's blips grupped by segment+time 

  Scenario: simple map
    When I run "ruby ../../lib/mapper.rb" and type:
      """
      1:_sdpH_gayBgE??gE	[{"data": "A@@@@@@@@@?VVVVWABEFG", "user": "foo", "time": 1277562602}, {"data": "@@@VVVVWABEFG", "user": "bar", "time": 1277562610}, {"data": "@@@CFAIDBHEDG", "user": "fake", "time": 1277562610}, {"data": "@@@CFAIDBHEDGCFH", "user": "fake2", "time": 1277562610}, {"data": "@@@VVVVWABEFG", "user": "fake3", "time": 1277562010}]
      """
    Then the output should contain:
      """
      {"time": 1277562613, "commuters": {"foo": 11, "bar": 3}, "polluters": ["fake", "fake2", "fake3"], "polyline_id": "1", "points": [[50.00019785075331, 20.0], [50.00039570150661, 20.0], [50.000593552259915, 20.0], [50.00079140301322, 20.0], [50.000998246982576, 20.0], [50.001000000000005, 20.000187549733], [50.001000000000005, 20.000351647858274], [50.001000000000005, 20.000593052215326], [50.001000000000005, 20.000798934555903], [50.001000000000005, 20.000995218510713]]}
      """
