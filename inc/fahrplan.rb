Encoding.default_external = "UTF-8"
Encoding.default_internal = "UTF-8"

require 'sqlite3'
require 'csv'
require 'json'
require 'digest/sha1'
require 'open-uri'
require 'uri'
require 'cgi'
require 'base64'
require 'openssl'

class FPlanImporter
  @db = nil
  @k_insert = nil

  def self.init
    self.db_init
    sql = File.open("#{FPLAN_SQL_PATH}/01-schema.sql", "r").read
    @db.execute_batch(sql)
  end
  
  def self.db_init
    if @db
      return
    end
    
    @db = SQLite3::Database.new(DB_PATH)
    @db.results_as_hash = true
  end
  
  def self.db_add_indexes
    self.db_init
    sql = File.open("#{FPLAN_SQL_PATH}/02-indexes.sql", "r").read
    @db.execute_batch(sql)
  end
  
  def self.import_stations
    self.db_init

    @db.transaction
      IO.foreach("#{FPLAN_PATH}/BFKOORD_GEO", :encoding => 'iso-8859-1').with_index do |line, k_line|
        sql_row = {
          'stop_id' => line[0..6],
          'stop_name' => line[39..(line.length-1)].chomp,
          'stop_lon' => line[8..17].to_f,
          'stop_lat' => line[19..28].to_f,
        }

        sql = "INSERT INTO stops (#{sql_row.keys.join(', ')}) VALUES (#{(["?"] * sql_row.keys.length).join(', ')})"

        @db.execute(sql, sql_row.values)

        if (k_line > 0) && ((k_line % 10000) == 0)
          @db.commit
          @db.transaction
        end

      end
    @db.commit
  end

  def self.import_timetables
    self.db_init
    @k_insert = 0
    @trip_id = 1

    # Default is 'train', see below
    map_class_id_station_type = {
      4 => 'boat',
      6 => 'bus',
      7 => 'cable',
      9 => 'tram',
    }
    station_type_default = 'train'

    vehicle_map_station_type = {}
    
    IO.foreach("#{FPLAN_PATH}/ZUGART") do |line|
      if line[29] != '#' 
        next
      end
      
      vehicle_type = line[0..2].strip
      vehicle_class_id = line[4..5].strip.to_i
      
      vehicle_map_station_type[vehicle_type] = map_class_id_station_type[vehicle_class_id] || station_type_default
    end

    vehicle_type = nil

    station_map_types = {}

    IO.foreach("#{FPLAN_PATH}/FPLAN").with_index do |line, k_line|
      if line.start_with? "*"
        if line.start_with? "*G"
          vehicle_type = line[3..5].strip
        end
      else
        stop_id = line[0..6]
        if station_map_types[stop_id].nil?
          station_map_types[stop_id] = []
        end

        station_type = vehicle_map_station_type[vehicle_type]

        if !station_map_types[stop_id].include? station_type
          station_map_types[stop_id].push(station_type)  
        end
      end
    end

    station_type_order = ['train', 'tram', 'bus', 'boat', 'cable']
    
    k_insert = 0
    @db.transaction
      station_map_types.each do |stop_id, station_types|
        order_id = 99
        station_types.each do |station_type|
          order_id = [station_type_order.index(station_type), order_id].min
        end

        station_type = station_type_order[order_id]
        sql = "UPDATE stops SET stop_main_type = ?, stop_types = ? WHERE stop_id = ?"
        @db.execute(sql, station_type, station_types.join(','), stop_id)

        if (k_insert > 0) && ((k_insert % 10000) == 0)
          @db.commit
          @db.transaction
        end

        k_insert += 1
      end
    @db.commit

    sql = 'DELETE FROM stops WHERE stop_main_type IS NULL'
    @db.execute(sql)
  end

  def self.reverse_geoocde
    geocoder_cache_folder = "#{TMP_PATH}/cache/google-geocoder"
    if ! File.directory? geocoder_cache_folder
      print "Creating #{geocoder_cache_folder}\n"
      system "mkdir -p #{geocoder_cache_folder}"
    end

    self.db_init

    sql = 'SELECT stop_id, stop_name, stop_lon, stop_lat FROM stops ORDER BY stop_id'
    rows = @db.execute(sql)

    k_insert = 0
    @db.transaction
      rows.each do |row|
        latlng = "#{row['stop_lat']},#{row['stop_lon']}"
        cache_file = "#{geocoder_cache_folder}/#{Digest::SHA1.hexdigest(latlng)}.json"
        geocoder_url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=#{CGI.escape(latlng)}"
        geocoder_url = self.append_google_service_signature(geocoder_url)

        self.url_content_get(geocoder_url, cache_file, 0.3)
        geocoder_json = JSON.parse(File.open(cache_file).read)

        if geocoder_json['status'] != 'OK'
          print "Bad status from #{geocoder_url}\n"
          print "   local file #{cache_file}\n"
          next
        end

        address = geocoder_json['results'][0]['formatted_address']
        sql = "UPDATE stops SET stop_address = ? WHERE stop_id = ?"
        @db.execute(sql, address, row['stop_id'])

        if (k_insert > 0) && ((k_insert % 10000) == 0)
          @db.commit
          @db.transaction
        end

        k_insert += 1
      end
    @db.commit
  end

  def self.append_google_service_signature(url)
    geocoder_client = nil
    geocoder_client_private_key = nil

    if geocoder_client.nil? || geocoder_client_private_key.nil?
      return url
    end

    if url.match('client=').nil?
      uri = URI::parse(url)

      if uri.query.nil?
        url += "?"
      else
        url += "&"
      end
      url += "client=#{geocoder_client}"
    end

    private_key_decoded = Base64.decode64(geocoder_client_private_key)

    uri = URI::parse(url)
    string_to_sign = "#{uri.path}?#{uri.query}"

    signature = OpenSSL::HMAC.digest('sha1', private_key_decoded, string_to_sign)
    signature = Base64.encode64(signature).strip
    signature = signature.gsub('+', '-').gsub('/', '_')
    
    url += "&signature=#{signature}"

    return url
  end

  def self.url_content_get(url, cache_file, sleep_seconds = 1)
    if File.file? cache_file
      content = IO.read(cache_file)
    else
      begin
        sleep sleep_seconds
        content = open(url).read
        File.open(cache_file, 'w') {|f| f.write(content) }
      rescue
        p "Connection issue with #{url}"
        return nil
      end
    end
    
    return content
  end

  def self.export_geojson
    geojson = {
      "type" => "FeatureCollection",
      "features" => []
    }

    sql_fields = ["stop_id", "stop_name", "stop_types", "stop_main_type", "stop_address"]

    self.db_init
    sql = "SELECT * FROM stops ORDER BY stop_id"
    @db.execute(sql).each do |row|
      feature = {
        "type" => "Feature",
        "properties" => {},
        "geometry" => {
          "type" => "Point",
          "coordinates" => [row['stop_lon'].to_f, row['stop_lat'].to_f]
        }
      }

      sql_fields.each do |column|
        feature['properties'][column] = row[column]
      end

      geojson['features'].push(feature)
    end

    File.open("#{TMP_PATH}/../map/stops.geojson", "w") {|f| f.write(JSON.pretty_generate(geojson)) }
  end
  
end