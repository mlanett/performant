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
    def monitor( job )
      Configuration.default.monitor.job(job)
    end

    # @returns a Sampler initialized from the default Configuration
    def sampler
      Configuration.default.sampler
    end

    # @returns a Storage initialized from the default Configuration
    def storage( job )
      Configuration.default.storage.job(job)
    end

  end # class

end # Performant
