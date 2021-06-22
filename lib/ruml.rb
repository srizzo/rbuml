# frozen_string_literal: true

require "ruml/version"
require 'binding_of_caller'
require 'set'

module Ruml
  class Tracer
    class Error < StandardError; end

    TRACER_CALLS = %w[Ruml#trace TracePoint.tracer Ruml#process].freeze

    def trace
      @group_by_glob = File.absolute_path(ENV.fetch('RUML_GROUP_BY_GLOB'))
      @app_glob = File.absolute_path(ENV.fetch('RUML_APP_GLOB'))
      @exclude_call_regex = ENV['RUML_EXCLUDE_CALL_REGEX']
      @exclude_caller_regex = ENV['RUML_EXCLUDE_CALLER_REGEX']
      @exclude_callee_regex = ENV['RUML_EXCLUDE_CALLEE_REGEX']

      @participants = Hash.new { |hash, key| hash[key] = Set.new }
      @calls = Hash.new { |hash, key| hash[key] = [] }

      TracePoint.trace(:call) { |trace_point| process(trace_point) }
      at_exit { write_to_disk }
    end

    # @param trace_point [TracePoint]
    def process(trace_point)
      # filter callee
      callee = trace_point.self

      return unless File.fnmatch(@app_glob, File.absolute_path(trace_point.path), File::FNM_EXTGLOB | File::FNM_PATHNAME)

      return if callee.instance_of?(Ruml)
      return if callee.is_a?(Module) && !callee.is_a?(Class)
      return if @exclude_callee_regex && participant_label(trace_point, callee).match?(@exclude_callee_regex)

      # filter caller
      caller = trace_point.binding.of_caller(TRACER_CALLS.size).receiver
      return if caller.instance_of?(Ruml) || participant_class(caller) == participant_class(callee)
      return if @exclude_caller_regex && participant_label(trace_point, caller).match?(@exclude_caller_regex)

      # filter call
      # call = trace_point.method_id
      call = trace_point.method_id
      return if @exclude_call_regex && call.match?(@exclude_call_regex)

      # filter initiators
      group_by = (caller_locations || []).map(&:absolute_path)
                                         .compact
                                         .select do |f|
        File.fnmatch(@group_by_glob, f,
                     File::FNM_EXTGLOB | File::FNM_PATHNAME)
      end
                                         .last
      return unless group_by

      parameters = trace_point.parameters.map { |(_type, name)| _type.in?([:req, :keyreq]) ? trace_point.binding.local_variable_get(name) : name }

      add_call(group_by, caller, callee, call, parameters, "#{trace_point.path}:#{trace_point.lineno}")
    rescue StandardError => e
      STDERR.puts
      warn e.message
      warn e.backtrace[0..5]
    end

    def participant_class(obj)
      obj.is_a?(Module) ? obj : obj.class
    end

    def write_to_disk
      @participants.keys.each do |group_by|
        puts 'Writing ' + group_by + '.ruml.puml'
        File.open(group_by + '.ruml.puml', 'w') do |file|
          file.puts("@startuml\n")
          @participants[group_by].each { |participant| file.puts(participant) }
          file.puts('')
          @calls[group_by].each do |(caller_label, callee_label, call, parameters_label, source_location)|
            file.puts("#{caller_label} -> #{callee_label}: #{call}(#{parameters_label}) /'#{source_location}'/")
          end
          file.puts('@enduml')
        end
      end
    end

    private

    def participant_label(obj)
      if obj.is_a?(Module)
        "\"#{obj}\""
      elsif obj.instance_of?(Class)
        "\":#{obj.class}\""
      else
        "\":#{obj.class}\""
      end
    end

    def add_participant(group_by, participant_type, participant)
      @participants[group_by].add("#{participant_type} #{participant}")
    end

    def parameter_label(parameter)
      if parameter.is_a?(Hash) && parameter.size <= 3
        parameter.transform_values(&:class)
      else
        parameter.class
      end
    end

    def add_call(group_by, caller, callee, call, parameters, source_location)
      callee_label = participant_label(callee)

      caller_class_name = participant_class(caller).name
      caller_path = caller_class_name && Module.const_source_location(caller_class_name).first

      caller_label = participant_label(caller)

      caller_participant_type = if caller_path && File.absolute_path(caller_path).include?(@app_glob)
                                  'participant'
                                else
                                  'actor'
                                end

      add_participant(group_by, caller_participant_type, caller_label)
      add_participant(group_by, 'participant', callee_label)

      parameters_label = parameters.map { |parameter| parameter_label(parameter) }.join(', ')

      @calls[group_by] << [caller_label, callee_label, call, parameters_label, source_location]
    end
  end
end

Ruml::Tracer.new.trace
