# frozen_string_literal: true

# RUBYOPT="-I "

require 'rotoscope'
require 'set'
require 'binding_of_caller'

class RotoscopePumlTracer
  def trace
    @group_by_glob = File.absolute_path(ENV.fetch('RUML_GROUP_BY_GLOB'))

    @app_glob = File.absolute_path(ENV.fetch('RUML_APP_GLOB'))
    @exclude_call_regex = ENV['RUML_EXCLUDE_CALL_REGEX']
    @exclude_caller_regex = ENV['RUML_EXCLUDE_CALLER_REGEX']
    @exclude_callee_regex = ENV['RUML_EXCLUDE_CALLEE_REGEX']

    @participants = Hash.new { |hash, key| hash[key] = Set.new }
    @calls = Hash.new { |hash, key| hash[key] = [] }

    @rotoscope = Rotoscope.new(&method(:process))
    @rotoscope.start_trace
    at_exit do
      @rotoscope.stop_trace
      write_to_disk
    end
  end

  # @param call [Rotoscope]
  def process(call)
    # filter caller

    return if call.caller_class == Object
    return if call.caller_class == Array
    return if call.caller_class == Method
    return if @exclude_caller_regex && participant_label(call.caller_object).match?(@exclude_caller_regex)

    # filter call
    return if @exclude_call_regex && call.method_name.match?(@exclude_call_regex)
    return unless File.fnmatch(@app_glob, File.absolute_path(call.caller_path), File::FNM_EXTGLOB | File::FNM_PATHNAME)

    # filter callee

    callee_path = if call.singleton_method?
                    call.receiver_class.method(call.method_name).source_location&.first
                  else
                    call.receiver.method(call.method_name).source_location&.first
                  end

    return unless callee_path

    return unless callee_path
    return unless File.fnmatch(@app_glob, File.absolute_path(callee_path), File::FNM_EXTGLOB | File::FNM_PATHNAME)

    return if call.receiver.is_a?(Module) && !call.receiver.is_a?(Class)
    return if @exclude_callee_regex && participant_label(call.receiver).match?(@exclude_callee_regex)

    # filter self calls
    return if participant_class(call.caller_object) == participant_class(call.receiver)

    # filter initiators
    group_by = (caller_locations || []).map(&:absolute_path)
                                       .compact
                                       .select do |f|
      File.fnmatch(@group_by_glob, f,
                   File::FNM_EXTGLOB | File::FNM_PATHNAME)
    end
                                       .last
    return unless group_by

    add_call(group_by, call)
  rescue StandardError => e
    STDERR.puts
    warn e.message
    warn e.backtrace[0..5]

    @rotoscope.stop_trace
    exit
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
        @calls[group_by].each do |(caller_label, callee_label, call)|
          file.puts("#{caller_label} -> #{callee_label}: #{call}")
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

  def add_call(group_by, call)
    callee_label = participant_label(call.receiver)

    caller_class_name = participant_class(call.caller_object).name

    caller_path = caller_class_name && Module.const_source_location(caller_class_name).first

    caller_label = participant_label(call.caller_object)

    caller_participant_type = if caller_path && File.absolute_path(caller_path).include?(@app_glob)
                                'participant'
                              else
                                'actor'
                              end

    add_participant(group_by, caller_participant_type, caller_label)
    add_participant(group_by, 'participant', callee_label)

    @calls[group_by] << [caller_label, callee_label, call.method_name]
  end
end

RotoscopePumlTracer.new.trace
