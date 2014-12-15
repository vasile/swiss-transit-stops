## Swiss Public Transport Stations
This script extracts the list of the public transport stations of Switzerland from the dataset offered by [www.fahrplanfelder.ch](http://www.fahrplanfelder.ch). The main output of the script is a SQLite DB defined using the schema defined in `resources/sql/01-schema.sql`

Steps:
* clone this repo
* download and unzip the latest data from http://www.fahrplanfelder.ch
* update the **FPLAN_PATH** in the `Rakefile`
* run 
  * `rake import_sqlite:all`

![Screenshot](https://api.monosnap.com/image/download?id=AyB4x7Uw6n2ViQSY58qzOK3E3SBpKi)
  * **yes, the whole parsing takes 30" on my ordinary MacBook Air machine :o)**

* check the output in `tmp/sbb-pois.db`

![Screenshot](https://api.monosnap.com/image/download?id=f8Ue3T38mNcwgTDlPpPxvsrNlg0k2r) 

The simplest way to visualize the data is to export the SQLite content in a GeoJSON file using `rake export:geojson` task which generates a GeoJSON file in `map/stops.geojson` and that can be visualized if you access the `map/` in a browser

![Screenshot](https://api.monosnap.com/image/download?id=5iUHNnrlm14IoNSEmdb1NUZ4x88I1V)

Live DEMO: [maps.vasile.ch](http://maps.vasile.ch/swiss-transit-stops/)

## Feedback

Contact me via [this form](https://docs.google.com/forms/d/1ZWCqfF8OvRBlMPHMc5FbL6T3zYhQ-p18B8IIwMt1sRs/) or [Twitter](twitter.com/vasile23).
