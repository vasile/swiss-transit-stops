import 'inc/fahrplan.rb'

FPLAN_PATH = nil
FPLAN_SQL_PATH = "#{Dir.pwd}/resources/sql"
TMP_PATH = "#{Dir.pwd}/tmp"
DB_PATH = "#{TMP_PATH}/sbb-pois.db"

if FPLAN_PATH.nil?
  print "ERROR: FPLAN_PATH var is missing\nDownload and unzip the latest version from http://www.fahrplanfelder.ch/\n"
  exit
end

if ! File.file? "#{FPLAN_PATH}/BFKOORD_GEO"
  print "ERROR: #{FPLAN_PATH} folder is missing BFKOORD_GEO file\n"
  exit
end

print "FPLAN folder: #{FPLAN_PATH}\n"

namespace :setup do
  desc "SETUP: init"
  task :init do
    if ! File.directory? TMP_PATH
      sh "mkdir #{TMP_PATH}"
    end

    print "DB: remove #{DB_PATH}\n"
    sh "rm -f #{DB_PATH}"
    print "DB: create #{DB_PATH}\n"
    FPlanImporter.init
  end
  
  desc "DB: add indexes"
  task :indexes do
    print "DB: add indexes to #{DB_PATH}\n"
    FPlanImporter.db_add_indexes
  end
end

namespace :import_sqlite do
  desc "IMPORT: ALL tasks"
  task :all do
    print "START " + Time.new.strftime("%H:%M:%S") + "\n"
    Rake::Task["setup:init"].execute
    Rake::Task["import_sqlite:stations"].execute
    Rake::Task["import_sqlite:timetables"].execute
    Rake::Task["setup:indexes"].execute
    print "END " + Time.new.strftime("%H:%M:%S") + "\n"
  end
  
  desc "IMPORT: stations"
  task :stations do
    print "Parsing #{FPLAN_PATH}/BFKOORD_GEO\n"
    FPlanImporter.import_stations
  end
  
  desc "IMPORT: timetables"
  task :timetables do
    print "Parsing #{FPLAN_PATH}/FPLAN\n"
    FPlanImporter.import_timetables
  end

  desc "IMPORT: Reverse Geocode Coordinates"
  task :reverse_geoocde do
    FPlanImporter.reverse_geoocde
  end
end

namespace :export do
  desc "GeoJSON"
  task :geojson do
    FPlanImporter.export_geojson
  end
end