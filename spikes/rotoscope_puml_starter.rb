# frozen_string_literal: true

require 'rotoscope'

rs = Rotoscope::CallLogger.new('rotoscope_puml.csv',
                               blacklist: [
                                 /^((?!app).)*$/,
                                 /(test)/
                               ])
rs.start_trace

at_exit { rs.stop_trace; rs.close }
