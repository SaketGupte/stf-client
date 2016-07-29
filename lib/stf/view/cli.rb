module Stf
  module CLI
    require 'gli'
    require 'stf/client'

    require 'stf/interactor/start_debug_session_interactor'
    require 'stf/interactor/stop_debug_session_interactor'
    require 'stf/interactor/stop_all_debug_sessions_interactor'
    require 'stf/interactor/remove_all_user_devices_interactor'

    include GLI::App
    extend self

    program_desc 'Smartphone Test Lab client'

    desc 'Be verbose'
    switch [:v, :verbose]

    desc 'Authorization token'
    flag [:t, :token]

    desc 'URL to STF'
    flag [:u, :url]

    pre do |global_options, command, options, args|
      help_now!('STF url is required') if global_options[:url].nil?
      help_now!('Authorization token is required') if global_options[:token].nil?

      Log::verbose(global_options[:verbose])

      $stf = Stf::Client.new(global_options[:url], global_options[:token])
    end

    desc 'Search for a device available in STF and attach it to local adb server'
    command :connect do |c|
      c.action do |global_options, options, args|
        StartDebugSessionInteractor.new($stf).execute
      end
    end

    desc 'Disconnect device(s) from local adb server and remove device(s) from user devices in STF'
    command :disconnect do |c|
      c.desc '(optional) ADB connection url of the device'
      c.flag [:d, :device]
      c.switch [:all]

      c.action do |global_options, options, args|
        if options[:device].nil? && options[:all] == true
          StopAllDebugSessionsInteractor.new($stf).execute
        elsif !options[:device].nil? && options[:all] == false
          StopDebugSessionInteractor.new($stf).execute(options[:device])
        elsif help_now!('Please specify disconnect mode (-all or -device)')
        end
      end
    end

    desc 'Frees all devices that are assigned to current user in STF. Doesn\'t modify local adb'
    command :clean do |c|
      c.action do |global_options, options, args|
        RemoveAllUserDevicesInteractor.new($stf).execute
      end
    end

    exit run(ARGV)
  end
end
