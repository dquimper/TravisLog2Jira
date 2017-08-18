require 'rails_helper'

RSpec.describe TravisLogParser, type: :model do
  Dir["#{Rails.root}/spec/fixtures/travis_logs/*.txt"].each do |logfile|
    it "parses #{logfile}" do
      base_file = File.basename(logfile, ".txt")
      dir_name = File.dirname(logfile)
      # puts "\e[34m" + "base_file=#{(base_file).inspect}" + "\e[39m"
      File.open(logfile) do |f|
        tests, report = TravisLogParser.new(f.read).tests
        yml_file_count = 0
        Dir["#{dir_name}/#{base_file}*.yml"].each_with_index do |ymlfile, idx|
          yml_file_count+=1
          yml_data = YAML.load_file(ymlfile)
          expect(tests[idx].title).to eq(yml_data[:title])
          expect(tests[idx].trace).to eq(yml_data[:trace])
        end

        if yml_file_count == 0
          puts "------"
          h = {
            title: tests[0].title,
            trace: tests[0].trace,
          }
          puts h.to_yaml
          puts "------"
        end
        expect(report).to eq(yml_file_count)
      end
    end
  end
end
