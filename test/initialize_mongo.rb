# -*- encoding: utf-8 -*-
require "mongo"

def db
  $db ||= begin
    host, port = ( config["hosts"] ).sample.split(":")
    Mongo::Connection.new(host, port, :safe => config["safe"]).db( config["database"] )
  end
end

def config
  $config ||= begin
    (YAML.load_file(File.expand_path("../../mongo.yml", __FILE__))[ENV["RACK_ENV"]]).tap do |config|
      config["hosts"]    ||= [ "localhost:27017" ]
      config["database"] ||= "performant_#{ENV["RACK_ENV"]}"
      config["safe"]     ||= false
    end
  end
end
