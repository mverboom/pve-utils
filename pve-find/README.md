# NAME

pve-find - find vm's or containers over multiple clusters and/or systems.

# SYNOPSIS

`pve-find [name]`

# DESCRIPTION

Makes it easier to find on which virtualisation server a vm or container is
running.

The name specified on the commandline is not required to be an exact match.
All names that match will be shown.

# CONFIGURATION FILE

The script requires a configuration file which should be locates at:

`~/.pve-find.ini`

An example configuration file is included.

As this file contains account information, place the appropriate protection on
the file and choose credentials that have the least possible rights.

The configuration file is in "ini" style format.

Each section name is the name of the cluster or node that needs to be checked.

In each section the following fields need to be present:

* `hostname`<br>
Specifies the hostname of the node or a node in the cluster. No protocol or port
numbers should be specified, just the name.<br>
For example:<br>
`hostname=pvenode.example.com`

* `user`<br>
User to log in as. The user can have minimal rights, as long as information about
all containers and vm's can be retrieved. The realm that the user exists in needs
to be specified.<br>
So, for example for the user info in the realm pve:<br>
`user=info@pve`

* `password`<br>
This is the password coupled to the specified user.

# FILES

`~/.pve-find.ini`

Configuration file

# EXAMPLES

Find all vm's or containers where the name contains server

    pve-find server
    production: server1
    production: server2
    test: server-test

# AUTHOR

Written by Mark Verboom

# REPORTING BUGS

Prefferably by opening an issue on the github page.

# COPYRIGHT

Copyright  ©  2014  Free Software Foundation, Inc.  License GPLv3+: GNU
GPL version 3 or later <http://gnu.org/licenses/gpl.html>.
This is free software: you are free  to  change  and  redistribute  it.
There is NO WARRANTY, to the extent permitted by law.
