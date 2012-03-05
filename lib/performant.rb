# -*- encoding: utf-8 -*-
require "performant/version"

module Performant
  autoload :Configuration,  "performant/configuration"
  autoload :Monitor,        "performant/monitor"
  autoload :Retriever,      "performant/retriever"
  autoload :Sampler,        "performant/sampler"
  autoload :Storage,        "performant/storage"

  class << self

    # @returns a Monitor initialized from the default Configuration
    def monitor( kind )
      Configuration.default.monitor.kind(kind)
    end

    # @returns a Sampler initialized from the default Configuration
    def sampler
      Configuration.default.sampler
    end

    # @returns a Storage initialized from the default Configuration
    def storage( kind )
      Configuration.default.storage.kind(kind)
    end

  end # class

end # Performant
