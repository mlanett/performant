require "optparse"
require "ostruct"

module Performant
module Utilities
class Task

  class << self
    attr_accessor :options
  end

  def self.option( short_option, long_name, options = {} )
    options = OpenStruct.new( { default: 0, short_option: short_option, long_name: long_name }.merge( options ) )
    self.options ||= []
    self.options << options
    attr_accessor long_name
  end

  def self.parse( argv )
    me = new
    self.options.each { |o| me.send("#{o.long_name}=", o.default) if o.default }
    OptionParser.new do |opts|
      opts.banner = "Usage: #{__FILE__} [options]*"
      opts.on( "-h", "--help", "Display this usage summary." ) { puts opts; exit }
      self.options.each do |o|
        opts.on( "-#{o.short_option}", "--#{o.long_name} VAL", "How many #{o.long_name}.") { |s| me.send("#{o.long_name}=",s.to_i) }
      end
    end.parse!( argv )
    me
  end

end # Task
end # Utilities
end # Performant



