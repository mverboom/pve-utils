#!/bin/bash
#
# libpve.sh: library for interacting with pve api
#
# ToDo:
# * check local variables
# * check return values
# * declare constants
# * check function arguments
# * internal sanity check

# public variables

# Named indices for found information on vm
readonly R_CLUS=0 R_HOST=1 R_ID=2 R_VM=3 R_TYPE=4 R_STATE=5

# "private" variables
_PVE_CFGDEFAULT=~/.pve.ini
_PVE_SW="jq curl flock"
_PVE_CACHE=~/.pve-cache
_PVE_TIMEOUT=1
# Login session time cache
_PVE_SESSION=300

# pve_req <cluster> "extra args"
pve_apireq() {
   local CMD; local data; local cookie; local token; local cache; local age
   local age
   local now; local cluster; local ret
   #CMD="curl -m $_PVE_TIMEOUT --fail --silent --insecure -D/dev/null"
   local CMD="curl --fail --insecure -D/dev/null"
   test "$verbose" -le 0 && CMD="$CMD --silent"

   local cluster="$1"
   shift

   test -e "$_PVE_CACHE" && { hmod 600 "$_PVE_CACHE"; cache="$(grep -m 1 ^$cluster$'\t' $_PVE_CACHE)"; }
   if test "$cache" != ""; then
      message 2 "$cluster: Login cookie in cache."
      now=$(date "+%s")
      age=$(echo "$cache" | cut -d$'\t' -f 2)
      #message 1 "$cluster: ${now}_ _${age}_"
      if test "$(( now - age ))" -lt "$_PVE_SESSION"; then
         message 2 "$cluster: Already logged in."
         token="$(echo "$cache" | cut -d$'\t' -f 3)"
         cookie="$(echo "$cache" | cut -d$'\t' -f 4- )"
      else
         flock -x -w 2 "$_PVE_CACHE" sed -i "/^$cluster\t/d" "$_PVE_CACHE"
         message 1 "$cluster: Cache invalid."
      fi
   fi

   if test "$cookie" = ""; then
      message 1 "$cluster: Logging in."
      data=$($CMD -d @<(cat <<<"username=${user[$cluster]}&password=${password[$cluster]}")  https://${hostname[$cluster]}:8006/api2/json/access/ticket 2> /dev/null)
      ret=$?
      test $ret -eq 7 && { message -1 "${hostname[$cluster]}: Failed to connect."; exit 1; }
      test $ret -eq 28 && { message -1 "${hostname[$cluster]}: Timed out."; exit 1; }
      test "$data" = "${data/ticket/}" && { message -1 "${hostname[$cluster]}: Unable to login."; exit 1; }
      cookie=$(echo $data | jq --raw-output '.data.ticket' | sed 's/^/PVEAuthCookie=/')
      token=$(echo $data | jq --raw-output '.data.CSRFPreventionToken')
      flock -x -w 2 "$_PVE_CACHE" echo -e "$cluster\t$(date '+%s')\t$token\t$cookie" >> "$_PVE_CACHE"
   fi
   $CMD --header "CSRFPreventionToken:$token" --cookie "$cookie" https://${hostname[$cluster]}:8006/api2/json/"$@"
   return $?
}

# Read configuration file
#
# ToDo:
# * multiple config file check
# * check for file exists
pve_readconfig() {
   local var
   local val
   local section
   local cfg

   test "$1" = "" && cfg="$_PVE_CFGDEFAULT"

   while IFS='= ' read var val
   do
      if [[ $var == \[*] ]]
      then
          section=${var:1:-1}
      elif [[ $val ]]
      then
          declare -g -A "$var[$section]=$val"
      fi
   done < <(grep -v "^#" $cfg)
}

# find name in specific cluster
find_name() {
   local cluster=$1
   local name=$2
   local nodes; local node; local data; local result

   unset clause
   #test $active -eq 1 && clause="and .status == \"running\""

   nodes=$(CURL $cluster nodes/ | jq -r ".data[] | .node")
   for node in $nodes; do
      data="$(CURL $cluster nodes/$node/lxc/) $(CURL $cluster nodes/$node/qemu/)"
      while read result; do 
         test "$result" != "" && echo "$cluster $result"
      done < <(echo $data | jq -r ".data[] | select((.name  | contains(\"$name\")) $clause) | \"$node \(.vmid) \(.name) \(.type // \"qemu\") \(.status)\"")
   done
}

sanity_check() {
   err=0

   ! test -f $_PVE_CFG && { message - "No config file found ($_PVE_CFG)."; err=1; }

   test $err -eq 0 && test $(stat -c %a $_PVE_CFG) -gt 600 && { message -1 "Unsafe permissions on config file."; err=1; }

   for name in $_PVE_SW
   do
      if ! which $name > /dev/null 2>&1
      then
         missing="$missing $name"
         err=1
      fi
   done
   test "$missing" != "" && message -1 "Missing required software to run script:$missing"

   test $# -lt 1 && { message -1 "At least one argument required."; err=1; }

   test $err -ne 0 && usage
}
