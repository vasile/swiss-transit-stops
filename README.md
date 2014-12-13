## Swiss Public Transport Stations
This application shows the public transport stations of Switzerland based on open data offered by [www.fahrplanfelder.ch](http://www.fahrplanfelder.ch) 

## Demo
[maps.vasile.ch](http://maps.vasile.ch/swiss-transit-stops/)

![Screenshot](https://api.monosnap.com/image/download?id=5iUHNnrlm14IoNSEmdb1NUZ4x88I1V)

## Parse the www.fahrplanfelder.ch data yourself

* clone this repo
* download and unzip the latest data from http://www.fahrplanfelder.ch
* update the **FPLAN_PATH** in the Rakefile
* run 
  * `rake import_sqlite:all`
* check the sbb-pois.db SQLite file
* run
  * `rake export:geojson`
* check the map/stops.geojson GeoJSON file

![Screenshot](https://api.monosnap.com/image/download?id=zVRqm098nERY8XTQ9qHYxnL7JGovAr)

## Feedback

Contact me via [this form](https://docs.google.com/forms/d/1ZWCqfF8OvRBlMPHMc5FbL6T3zYhQ-p18B8IIwMt1sRs/) or [Twitter](twitter.com/vasile23).
