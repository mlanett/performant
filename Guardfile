guard "rspec" do
  watch("lib/performant.rb")            { "spec" }
  watch(%r{^lib/performant/(.+)\.rb$})  { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^spec/.+_spec\.rb$})
  watch("spec/helper.rb")               { "spec" }
end
