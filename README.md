Nagios plugin for ESX
=====================

This plugin adds capability for Nagios for monitor
memory and datastores on a specific VMware ESX and
ESXi server.

Installation
------------

The nagios plugin depends on libvirt and ruby-libvirt gem
To install this gem, you may need install development files
of libvirt package, libvirt-dev or libvirt-devel, depending on
your favorite Linux distribution's package naming conventions.

For installing ruby-libvirt, you will need libxml2 and libxslt
development packages too, because it depens on Nokogiri what is
depends on them.

To install ruby-libvirt, simply type

    gem install --no-rdoc --no-ri ruby-libvirt

After successful installing of this gem, you need to put
`check_esx.rb` into your nagios plugins store. It is usually
/usr/lib/nagios/plugins or /usr/local/nagios/plugins.

Usage
-----

`chec_esx.rb` listens on --help switch and displays a following
screen:

    Usage: check_esx [options]
        -s, --server SERVER              ESX Server or vCenter host
        -u, --user USER                  Username for ESX/vCenter
        -p, --password PASSWORD          Password for ESX/vCenter
        -D, --datacenter DATACENTER      Datacenter name on vSphere
        -C, --cluster CLUSTER            Cluster name on vSphere in datacenter
        -N, --node NODE                  Node name or IP on vSphere in cluster
        -h, --help                       Displays this screen
        -S, --datastore DATASTORE        Specify datastore to query
        -m, --memory                     Display memory informations
        -w, --warning TRESHOLD           Percent of allocation to be warning
        -c, --critical TRESHOLD          Percent of allocation to be critical
        -d, --debug                      Toggle debugging

For querying, you need to specify `--server`, `--user` and `--password` switches to specify
connection informations, `--warning` and `--critical` switches for tresholds, and
exactly one of `--memory` or `--datastore`. You cannot specify both and you cannot specify
more than one datastore for monitoring.
The `--debug` switch turns on some debugging informations.

Connecting to vCenter server you need specify --datacenter, --cluster and --node switches.

The tresholds must be specified in percents and you can suffix it with % character but it is
not needed. So 80 and 80% are equivalents.

Example usage

    check_esx -s 192.168.0.25 -u root -p s3cr3tP45sw0rd -m -w 80 -c 90
    check_esx -s 192.168.0.25 -u root -p s3cr3tP45sw0rd -S datastore1 -w 75% -c 80%
    check_esx -s 192.168.0.25 -u administrator -p s3cr3tP45sw0rd -D DC1 -C cluster1 -N 10.10.10.1 -S datastore1 -w 75% -c 80%

Known limitations/bugs
----------------------

 - Cannot monitor vCenter systems where clusters/nodes organized to folders

Planned features
----------------

 - Monitoring some VM informations
 - Monitoring some CPU informations

Licensing
---------

This project is licensed under the terms of CreativeCommony BY-SA 3.0 license.
To check terms please visit http://creativecommons.org/licenses/by-sa/3.0/

Copyright (c) 2012 Gabor Garami. Some rights reserved.
