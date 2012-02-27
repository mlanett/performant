# -*- encoding: utf-8 -*-
File.expand_path(File.dirname(__FILE__)).tap { |d| $: << d unless $:.member?(d) }
require "performant/version"

module Performant
  autoload :Configuration,  "performant/configuration"
  autoload :Monitor,        "performant/monitor"
  autoload :Retriever,      "performant/retriever"
  autoload :Storage,        "performant/storage"

  class << self

    # @returns a Monitor initialized from the default Configuration
    def monitor
      Configuration.default.monitor
    end

    # @returns a Storage initialized from the default Configuration
    def storage
      Configuration.default.storage
    end

  end # class

end # Performant
