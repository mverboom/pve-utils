#/usr/bin/env bash

_pve()
{
   local cmd i a

   COMPREPLY=()

   cmd="${COMP_WORDS[1]}"

   echo "type=$COMP_TYPE"

   case "$cmd" in
   "stat")
      case "$COMP_CWORD" in
      2)  
         IFS=$'\n' a=( $(IFS=# compgen -W "<vmname> - VM name#<vmid@cluster> - ID in cluster" "${COMP_WORDS[2]}" ) )
         for i in "${!a[@]}"; do
            a[$i]="$(printf '%*s' "-$COLUMNS"  "${a[$i]}")"
         done
         COMPREPLY=( "${a[@]}" )
      ;;
      3)
         IFS=$'\n' a=( $(IFS=# compgen -W "<interval> - Update interval" ) )
         for i in "${!a[@]}"; do
            a[$i]="$(printf '%*s' "-$COLUMNS"  "${a[$i]}")"
         done
         COMPREPLY=( "${a[@]}" )
      ;;
      esac
   ;;
   "status")
      IFS=$'\n' a=( $( IFS=# compgen -W "<vmname> - VM name#<vmid@cluster> - ID in cluster" "${COMP_WORDS[2]}" ) )
      for i in "${!a[@]}"; do
         a[$i]="$(printf '%*s' "-$COLUMNS"  "${a[$i]}")"
      done
      COMPREPLY=( "${a[@]}" )
   ;;
   "list")
      if test "$COMP_CWORD" = 2; then
         local a=( $(pve list-clusters) lsdf )
         COMPREPLY=( $(compgen -W "${a[*]}" "${COMP_WORDS[2]}" ) )
      fi
   ;;
   *)
      case "$COMP_TYPE" in
      9|63)
      IFS=$'\n' a=( $( IFS=# compgen -W "-v - Be more verbose#-q - Be quiet#-x - Debug#status - Get a status#stat - Stat a vm#list - Get a list" "${COMP_WORDS[1]}" ) )
      for i in "${!a[@]}"; do
         a[$i]="$(printf '%*s' "-$COLUMNS"  "${a[$i]}")"
      done
      COMPREPLY=( "${a[@]}" )
      ;;
      37)
         COMPREPLY=( "Dit is een test" "Dit is regel 2" "En regel 3")
      ;;
      esac
   ;;
   esac

   # Don't use single tab if all are non completable options
   if test "$COMP_TYPE" = 9; then
      local ok=0
      for i in "${!COMPREPLY[@]}"; do
         test "${COMPREPLY[$i]:0:1}" != "<" && ok=1
      done
      test "$ok" = 0 && COMPREPLY=()
   fi

   # Strip any comment for tab complete
   if test "$COMP_TYPE" = 9 -a "${#COMPREPLY[*]}" -eq 1; then
      COMPREPLY=( ${COMPREPLY[0]%% - *} )
   fi
}

complete -o nosort -F _pve pve
#complete -F _pve pve
