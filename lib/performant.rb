# -*- encoding: utf-8 -*-
File.expand_path(File.dirname(__FILE__)).tap { |d| $: << d unless $:.member?(d) }
require "performant/version"

module Performant
  autoload :Configuration,  "performant/configuration"
  autoload :Monitor,        "performant/monitor"
  autoload :Storage,        "performant/storage"
end # Performant
