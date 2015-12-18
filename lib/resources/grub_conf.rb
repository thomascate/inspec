# encoding: utf-8
# author: Thomas Cate
# license: All rights reserved

require 'utils/simpleconfig'

class GrubConfig < Inspec.resource(1)
  name 'grub_conf'
  desc "Use the grub_conf InSpec audit resource to test the boot config of Linux systems that use Grub."
  example "
    describe grub_conf('/etc/grub.conf') do
      its('kernel') { should include '/vmlinuz-2.6.32-573.7.1.el6.x86_64' }
      its('kernel') { should include 'audit=1' }
      its('default') { should_not include '1' }
    end
  "

  def initialize(path = nil)
    @conf_path = path || '/etc/grub.conf'
  end

  def method_missing(name)
    read_params[name.to_s]
  end

  def to_s
    'Grub Config'
  end

  private

  def read_params
    return @params if defined?(@params)

    # read the file
    file = inspec.file(@conf_path)
    if ( !file.file? && !file.symlink? )
      skip_resource "Can't find file '#{@conf_path}'"
      return @params = {}
    end

    content = file.content
    if content.empty? && file.size > 0
      skip_resource "Can't read file '#{@conf_path}'"
      return @params = {}
    end

    lines = content.split("\n")
    kernel_opts = {}
    lines.each_with_index do |file_line,index|
      if ( file_line =~ /^title.*/ )
        puts file_line
        lines.drop(index+1).each do |kernel_line|
          if ( kernel_line =~ /^\s.*/ )
            option_type = kernel_line.split(' ')[0]
            line_options = kernel_line.split(' ').drop(1)
            if ( kernel_opts[option_type].kind_of?(Array) )
              kernel_opts[option_type].push(*line_options)
            else
              kernel_opts[option_type] = line_options
            end
          else
            break
          end
        end
      end
    end

    # parse the file
    conf = SimpleConfig.new(
      content,
      multiple_values: true,
    ).params
    @params = conf.merge(kernel_opts)
  end
end