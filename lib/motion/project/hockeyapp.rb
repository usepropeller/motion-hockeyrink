# Copyright (c) 2013, Turboprop Inc, Clay Allsopp <clay@usepropeller.com>
# Copyright (c) 2012, Laurent Sansonetti <lrz@hipbyte.com>
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

unless defined?(Motion::Project::Config)
  raise "This file must be required within a RubyMotion project Rakefile."
end

class HockeyAppConfig
  PROPERTIES = HockeyApp::Version::ATTRIBUTES + HockeyApp::Version::POST_PAYLOAD + [:app_id, :api_token]
  attr_accessor *PROPERTIES

  # Coerce these values to be :symbols
  [["NOTES_TYPES", "notes_type"], ["STATUS","status"]].each do |constant, prop|
    # i.e. Hockey::Version::NOTES_TYPE_TO_SYM
    constant = HockeyApp::Version.const_get(constant + "_TO_SYM")
    define_method("#{prop}=") do |new_value|
      if new_value.is_a?(Numeric)
        new_value = constant[new_value]
      end
      instance_variable_set("@#{prop}", new_value.to_sym)
    end
  end

  def notify=(notify)
    @notify = string_or_num_to_bool(notify)
  end

  def mandatory=(mandatory)
    @mandatory = string_or_num_to_bool(mandatory)
  end

  def initialize(config)
    @config = config
  end

  def client
    if !api_token
      puts "You need to specify an app.hockeyapp.api_token"
      return
    end
    @client ||= HockeyApp.build_client
  end

  def app
    return if !client

    @app ||= HockeyApp::App.from_hash({"public_identifier" => app_id}, client)
  end

  def api_token=(api_token)
    @api_token = api_token
    config_client
    @api_token
  end

  def inspect
    h = {}
    PROPERTIES.each do |prop|
      h[prop] = self.send(prop)
    end
    h
  end

  # Public: Creates a HockeyApp::Version object from this configuraiton
  #
  # Returns the new HockeyApp::Version object
  def make_version
    version = HockeyApp::Version.new(app, client)
    version.notes = self.notes
    version.notes_type = HockeyApp::Version::NOTES_TYPES_TO_SYM.invert[self.notes_type]
    version.notify = HockeyApp::Version::NOTIFY_TO_BOOL.invert[self.notify]
    version.status = HockeyApp::Version::STATUS_TO_SYM.invert[self.status]
    version.tags = self.tags
    version
  end

  private
  def config_client
    HockeyApp::Config.configure do |config|
      config.token = api_token
    end
  end

  def string_or_num_to_bool(object)
    if object.is_a?(Symbol)
      notify = notify.to_s
    end
    if object.is_a?(String)
      object = (object == "true") ? true : false
    end
    if object.is_a?(Numeric)
      object = HockeyApp::Version::NOTIFY_TO_BOOL[object]
    end
    object
  end
end

module Motion; module Project; class Config

  attr_accessor :hockeyapp_mode

  variable :hockeyapp

  def hockeyapp
    @hockeyapp ||= HockeyAppConfig.new(self)
    yield @hockeyapp if block_given? && hockeyapp?
    @hockeyapp
  end

  def hockeyapp?
    @hockeyapp_mode == true
  end

end; end; end

namespace 'hockeyapp' do
  desc "Submit an archive to HockeyApp"
  task :submit do

    # Set the build status
    App.config_without_setup.hockeyapp_mode = true

    # Validate configuration settings.
    prefs = App.config.hockeyapp
    App.fail "A value for app.hockeyapp.api_token is mandatory" unless prefs.api_token
    App.fail "A value for app.hockeyapp.app_id is mandatory" unless prefs.app_id

    # Allow CLI overrides for all properties
    env_configs = HockeyAppConfig::PROPERTIES
    env_configs.each do |config|
      value = ENV[config.to_s]
      if value
        prefs.send("#{config}=", value)
      end
    end

    # Create an archive
    Rake::Task["archive"].invoke

    # An archived version of the .dSYM bundle is needed.
    app_dsym = App.config.app_bundle('iPhoneOS').sub(/\.app$/, '.dSYM')
    app_dsym_zip = app_dsym + '.zip'
    if !File.exist?(app_dsym_zip) or File.mtime(app_dsym) > File.mtime(app_dsym_zip)
      Dir.chdir(File.dirname(app_dsym)) do
        sh "/usr/bin/zip -q -r \"#{File.basename(app_dsym)}.zip\" \"#{File.basename(app_dsym)}\""
      end
    end

    # This is an HockeyApp::Version object
    hockey_version = prefs.make_version
    hockey_version.ipa = File.new(App.config.archive, 'r')
    hockey_version.dsym = File.new(app_dsym_zip, 'r')

    App.info "Upload", "#{hockey_version.inspect}"
    result = prefs.client.post_new_version hockey_version
    hockey_version.ipa.close
    hockey_version.dsym.close
    App.info "Result", "#{result.inspect}"
  end


  desc "Records if the device build is created in hockeyapp mode, so some things can be cleaned up between mode switches"
  task :record_mode do
    hockeyapp_mode = App.config_without_setup.hockeyapp_mode ? "True" : "False"

    platform = 'iPhoneOS'
    bundle_path = App.config.app_bundle(platform)
    build_dir = File.join(App.config.versionized_build_dir(platform))
    FileUtils.mkdir_p(build_dir)
    previous_hockeyapp_mode_file = File.join(build_dir, '.hockeyapp_mode')

    previous_hockeyapp_mode = "False"
    if File.exist?(previous_hockeyapp_mode_file)
      previous_hockeyapp_mode = File.read(previous_hockeyapp_mode_file).strip
    end
    if previous_hockeyapp_mode != hockeyapp_mode
      App.info "HockeyApp", "Cleaning executable, Info.plist, and PkgInfo for mode change (was: #{previous_hockeyapp_mode}, now: #{hockeyapp_mode})"
      [
        App.config.app_bundle_executable(platform), # main_exec
        File.join(bundle_path, 'Info.plist'), # bundle_info_plist
        File.join(bundle_path, 'PkgInfo') # bundle_pkginfo
      ].each do |path|
        rm_rf(path) if File.exist?(path)
      end
    end
    File.open(previous_hockeyapp_mode_file, 'w') do |f|
      f.write hockeyapp_mode
    end
  end

end

desc 'Same as hockeyapp:submit'
task 'hockeyapp' => 'hockeyapp:submit'

# record hockeyapp mode before every device build
task 'build:device' => 'hockeyapp:record_mode'
