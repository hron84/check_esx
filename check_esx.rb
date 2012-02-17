#!/usr/bin/ruby

require 'rubygems'
require 'optparse'
require 'pp'

def ok(msg)
  puts "ESX OK - #{msg}"
  exit 0
end

def warn(msg)
  puts "ESX WARNING - #{msg}"
  exit 1
end

def crit(msg)
  puts "ESX CRITICAL - #{msg}"
  exit 2
end

def unk(msg)
  puts "ESX UNKNOWN - #{msg}"
  exit 3
end

def debug(msg)
  return unless $DEBUG
  STDERR.puts "DEBUG - #{msg}"
  STDERR.flush
end

begin
  require 'libvirt'
rescue LoadError
  unk("You need to install libvirt library and ruby-libvirt gem")
end


creds = {}
server = "localhost"
protocol = "esx"
options = {}


optparse = OptionParser.new do |opts|
  opts.on('-s', '--server SERVER', 'ESX Server or vCenter host') { |optval| server = optval }
  opts.on('-u', '--user USER', 'Username for ESX/vCenter') { |optval| creds[Libvirt::CRED_AUTHNAME] = optval }
  opts.on('-p', '--password PASSWORD', 'Password for ESX/vCenter') { |optval| creds[Libvirt::CRED_PASSPHRASE] = optval }
  opts.on('-D', '--datacenter DATACENTER', 'Datacenter name on vSphere') { |optval| options[:datacenter] = optval }
  opts.on('-C', '--cluster CLUSTER', 'Cluster name on vSphere in datacenter') { |optval| options[:cluster] = optval }
  opts.on('-N', '--node NODE', 'Node name or IP on vSphere in cluster') { |optval| options[:node] = optval }
  opts.on('-h', '--help', 'Displays this screen') { puts opts; exit 3 }
  opts.on('-S', '--datastore DATASTORE', 'Specify datastore to query') { |optval| options[:datastore] = optval }
  opts.on('-m', '--memory', 'Display memory informations') { options[:memory] = true }
  opts.on('-w', '--warning TRESHOLD', 'Percent of allocation to be warning') { |optval| options[:warn] = optval.sub(/%$/, '').to_f }
  opts.on('-c', '--critical TRESHOLD', 'Percent of allocation to be critical') { |optval| options[:crit] = optval.sub(/%$/, '').to_f }
  opts.on('-d', '--debug', 'Toggle debugging') { $DEBUG = true }
end

optparse.parse!

if server == '' or creds.empty?
  unk("Please specify connection data (--server, --user, --password)")
end

if options[:datacenter] or options[:cluster] or options[:node]
  protocol = 'vpx'
end

if protocol == 'vpx'
  if options[:datacenter].nil? or options[:cluster].nil? or options[:node].nil?
    unk("For vSphere checking you must specify both --datacenter, --cluster and --node")
  end
  if options[:datacenter].empty? or options[:cluster].empty? or options[:node].empty?
    unk("For vSphere checking you must specify valid values for --datacenter, --cluster and --node")
  end
end

if not options[:warn] or not options[:crit]
  unk("You must specify both warning and critical values")
end

if options[:datastore] and options[:memory]
  unk("You can specify one query once!")
elsif not options[:datastore] and not options[:memory]
  unk("You must specify a query")
end

if protocol == 'vpx'
  uri = "vpx://#{server}/#{options[:datacenter]}/#{options[:cluster]}/#{options[:node]}?no_verify=1"
else
  uri = "esx://#{server}/?no_verify=1"
end

debug "Connecting to '#{uri}'"
conn = Libvirt.open_auth(uri, [Libvirt::CRED_AUTHNAME, Libvirt::CRED_PASSPHRASE]) { |cred| creds[cred["type"]] }

begin
  if options[:datastore]
    # Query datastore
    ds = conn.list_storage_pools
    unk("The specified datastore not found") unless ds.include?(options[:datastore])
    pool = conn.lookup_storage_pool_by_name options[:datastore]
    avail =  pool.info.available
    capacity = pool.info.capacity
    usage = ((capacity - avail) * 100) / capacity.to_f
    if usage > options[:crit]
      crit("Datastore [#{options[:datastore]}]: Cap #{capacity / 1073741824} GB / Free #{avail / 1073741824} GB (#{(100 - usage).to_i} %)|free=#{avail}, used=#{capacity - avail}, capacity=#{capacity}")
    elsif usage > options[:warn]
      warn("Datastore [#{options[:datastore]}]: Cap #{capacity / 1073741824} GB / Free #{avail / 1073741824} GB (#{(100 - usage).to_i} %)|free=#{avail}, used=#{capacity - avail}, capacity=#{capacity}")
    else
      ok("Datastore [#{options[:datastore]}]: Cap #{capacity / 1073741824} GB / Free #{avail / 1073741824} GB (#{(100 - usage).to_i} %)|free=#{avail}, used=#{capacity - avail}, capacity=#{capacity}")
    end
  elsif options[:memory]
    ninfo = conn.node_get_info
    # It is returned by kbytes, converting to bytes
    capacity = ninfo.memory * 1024
    avail = conn.node_free_memory
    usage = ((capacity - avail) * 100) / capacity.to_f

    if usage > options[:crit]
      crit("Memory: Cap #{capacity / 1073741824} GB / Free #{avail / 1073741824} GB (#{(100 - usage).to_i} %)|free=#{avail}, used=#{capacity - avail}, capacity=#{capacity}")
    elsif usage > options[:warn]
      warn("Memory: Cap #{capacity / 1073741824} GB / Free #{avail / 1073741824} GB (#{(100 - usage).to_i} %)|free=#{avail}, used=#{capacity - avail}, capacity=#{capacity}")
    else
      ok("Memory: Cap #{capacity / 1073741824} GB / Free #{avail / 1073741824} GB (#{(100 - usage).to_i} %)|free=#{avail}, used=#{capacity - avail}, capacity=#{capacity}")
    end
  end
ensure
  conn.close
end
# vim: ts=2 sw=2 et
