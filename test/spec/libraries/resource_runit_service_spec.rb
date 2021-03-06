#
# Author:: Joshua Timberman <joshua@opscode.com>
# Author:: Seth Chisamore <schisamo@opscode.com>
#
# Copyright:: Copyright (c) 2012, Opscode, Inc. <legal@opscode.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..'))
require 'spec_helper'

describe Chef::Resource::RunitService do

  subject(:resource) { Chef::Resource::RunitService.new(service_name, run_context) }

  let(:service_name) { 'getty.service' }
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }

  its(:class) { should be Chef::Resource::RunitService }
  its(:resource_name) { should eq(:runit_service) }
  its(:provider) { should eq(Chef::Provider::Service::Runit) }
  its(:service_name) { should eq('getty.service') }
  its(:sv_dir) { should eq('/etc/sv') }
  its(:sv_bin) { should eq('/usr/bin/sv') }
  its(:lsb_init_dir) { should eq('/etc/init.d') }
  its(:sv_timeout) { should eq(nil) }
  its(:sv_verbose) { should eq(false) }

  describe 'setting supported default values from node attributes' do
    let(:sv_bin) { '/fake/bin/sv_bin' }
    let(:sv_dir) { '/fake/sv_dir/path' }
    let(:service_dir) { '/fake/service_dir' }
    let(:lsb_init_dir) { '/fake/lsb_init_dir' }
    let(:node) do
      node = Chef::Node.new
      node.set['runit']['sv_bin'] = sv_bin
      node.set['runit']['sv_dir'] = sv_dir
      node.set['runit']['service_dir'] = service_dir
      node.set['runit']['lsb_init_dir'] = lsb_init_dir
      node
    end

    its(:sv_bin) { should eq sv_bin }
    its(:sv_dir) { should eq sv_dir }
    its(:service_dir) { should eq service_dir }
    its(:lsb_init_dir) { should eq lsb_init_dir }
  end

  describe 'backward compatiblility hack' do

    let(:simple_service_name) { "service[#{service_name}]" }

    it 'creates a simple service with the same name' do
      resource_collection = resource.run_context.resource_collection
      simple_service = resource_collection.find(simple_service_name)
      simple_service.to_s.should eq(simple_service_name)
      simple_service.class.should be Chef::Resource::Service
      simple_service.provider.should be Chef::Provider::Service::Simple
    end

  end

  it 'has an sv_dir parameter that can be set' do
    resource.sv_dir('/var/lib/sv')
    resource.sv_dir.should eq('/var/lib/sv')
  end

  it 'allows sv_dir parameter to be set false (so users can use an existing sv dir)' do
    resource.sv_dir(false)
    resource.sv_dir.should be_false
  end

  it 'has a service_dir parameter set to /etc/service by default' do
    resource.service_dir.should eq('/etc/service')
  end

  it 'has a service_dir parameter that can be set' do
    resource.service_dir('/var/service')
    resource.service_dir.should eq('/var/service')
  end

  it 'has a lsb_init_dir parameter set to /etc/init.d by default' do
    resource.lsb_init_dir.should eq('/etc/init.d')
  end

  it 'has a lsb_init_dir parameter that can be set' do
    resource.lsb_init_dir('/other/lsb_init_dir')
    resource.lsb_init_dir.should eq('/other/lsb_init_dir')
  end

  it 'has a control parameter that can be set as an array of service control characters' do
    resource.control %w{ s u }
    resource.control.should eq %w{ s u }
  end

  it 'has an options parameter that can be set as a hash of arbitrary options' do
    resource.options(:binary => '/usr/bin/noodles')
    resource.options.should have_key(:binary)
    resource.options[:binary].should eq('/usr/bin/noodles')
  end

  it 'has an env parameter that can be set as a hash of environment variables' do
    resource.env('PATH' => '$PATH:/usr/local/bin')
    resource.env.should have_key('PATH')
    resource.env['PATH'].should include('/usr/local/bin')
  end

  it 'adds :env_dir to options if env is set' do
    resource.env('PATH' => '/bin')
    resource.options.should have_key(:env_dir)
    resource.options[:env_dir].should eq(::File.join(resource.sv_dir, resource.service_name, 'env'))
  end

  it 'has a log parameter to control whether a log service is setup' do
    resource.log.should be_true
  end

  it 'has a log parameter that can be set to false' do
    resource.log(false)
    resource.log.should be_false
  end

  it 'should return default (true) if the log parameter is set to nil' do
    resource.log(nil)
    resource.log.should be true
  end

  it 'has a cookbook parameter that can be set' do
    resource.cookbook('noodles')
    resource.cookbook.should eq('noodles')
  end

  it 'has a check parameter that is false by default' do
    resource.check.should be_false
  end

  it 'hash a check parameter that controls whether a check script is created' do
    resource.check(true)
    resource.check.should be_true
  end

  it 'has a finish parameter that is false by default' do
    resource.finish.should be_false
  end

  it 'hash a finish parameter that controls whether a finish script is created' do
    resource.finish(true)
    resource.finish.should be_true
  end

  it 'has an owner parameter that can be set' do
    resource.owner('monkey')
    resource.owner.should eq('monkey')
  end

  it 'has a group parameter that can be set' do
    resource.group('primates')
    resource.group.should eq('primates')
  end

  it 'has an enabled parameter to determine if the current resource is enabled' do
    resource.enabled.should be_false
  end

  it 'has a running parameter to determine if the current resource is running' do
    resource.running.should be_false
  end

  it 'has a default_logger parameter that is false by default' do
    resource.default_logger.should be_false
  end

  it 'has a default_logger parameter that controls whether a default log template should be created' do
    resource.default_logger(true)
    resource.default_logger.should be_true
  end

  it 'has a restart_on_update parameter that is true by default' do
    resource.restart_on_update.should be_true
  end

  it 'has a restart_on_update parameter that controls whether a the service is restarted when the run script is updated' do
    resource.restart_on_update(false)
    resource.restart_on_update.should be_false
  end

  it 'sets the run_template_name to the service_name by default' do
    resource.run_template_name.should eq(resource.service_name)
  end

  it 'sets the log_template_name to the service_name by default' do
    resource.log_template_name.should eq(resource.service_name)
  end

  it 'has a run_template_name parameter to allow a custom template name for the run run script' do
    resource.run_template_name('foo_bar')
    resource.run_template_name.should eq('foo_bar')
  end

  it 'has a template_name parameter to allow a custom template name for the run run script for backwards compatiblility' do
    resource.template_name('foo_baz')
    resource.run_template_name.should eq('foo_baz')
  end

  it 'has a log_template_name parameter to allow a custom template name for the log run script' do
    resource.log_template_name('write_noodles')
    resource.log_template_name.should eq('write_noodles')
  end

  it 'sets the control_template_names for each control character to the service_name by default' do
    resource.control %w{ s u }
    resource.control_template_names.should have_key('s')
    resource.control_template_names.should have_key('u')
    resource.control_template_names['s'].should eq(resource.service_name)
    resource.control_template_names['u'].should eq(resource.service_name)
  end

  it 'has a control_template_names parameter to allow custom template names for the control scripts' do
    resource.control_template_names(
      's' => 'banana_start',
      'u' => 'noodle_up'
      )
    resource.control_template_names.should have_key('s')
    resource.control_template_names.should have_key('u')
    resource.control_template_names['s'].should eq('banana_start')
    resource.control_template_names['u'].should eq('noodle_up')
  end

  it 'sets the check_script_template_name to the service_name by default' do
    resource.check_script_template_name.should eq(resource.service_name)
  end

  it 'has a check_script_template_name parameter to allow a custom template name for the check script' do
    resource.check_script_template_name('eat_bananas')
    resource.check_script_template_name.should eq('eat_bananas')
  end

  it 'sets the finish_script_template_name to the service_name by default' do
    resource.finish_script_template_name.should eq(resource.service_name)
  end

  it 'has a finish_script_template_name parameter to allow a custom template name for the finish script' do
    resource.finish_script_template_name('eat_bananas')
    resource.finish_script_template_name.should eq('eat_bananas')
  end

  it 'has a sv_templates parameter to control whether the sv_dir templates are created' do
    resource.sv_templates(false)
    resource.sv_templates.should be_false
  end

  it 'has a sv_timeout parameter to control sv_bin timeout' do
    resource.sv_timeout(30)
    resource.sv_timeout.should eq(30)
  end

  it 'has a sv_verbose parameter to control sv_bin verbose mode' do
    resource.sv_verbose(true)
    resource.sv_verbose.should eq(true)
  end

  it 'has a log_size parameter to control the maximum log size' do
    resource.log_size(1_000_000)
    resource.log_size.should eq(1_000_000)
  end

  it 'has a log_num parameter to control the maximum number of logs' do
    resource.log_num(10)
    resource.log_num.should eq(10)
  end

  it 'has a log_min parameter to control the minimum number of logs' do
    resource.log_min(5)
    resource.log_min.should eq(5)
  end

  it 'has a log_timeout parameter to control the maximum age of a log file' do
    resource.log_timeout(60 * 60)
    resource.log_timeout.should eq(60 * 60)
  end

  it 'has a log_processor parameter to allow logs to be fed through it after rotation' do
    resource.log_processor('/usr/local/bin/process')
    resource.log_processor.should eq('/usr/local/bin/process')
  end

  it 'has a log_socket parameter to allow log lines to be sent to a UDP socket' do
    resource.log_socket('127.0.0.1:1514')
    resource.log_socket.should eq('127.0.0.1:1514')
  end

  it 'has a log_prefix parameter to allow log lines to be prefixed with a fixed string' do
    resource.log_prefix('myservice:')
    resource.log_prefix.should eq('myservice:')
  end

  it 'has a log_config_append parameter to allow arbitrary configuration entries to be added to the configuration' do
    resource.log_config_append('-bogus')
    resource.log_config_append.should eq('-bogus')
  end
end
