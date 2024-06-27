#!/bin/bash

#COLORS
RED_COLOR='\033[0;31m'
GREEN_COLOR='\033[0;32m'
ORANGE_COLOR='\033[0;33m'
NO_COLOR='\033[0m'

#Expiration date in years
default_expiration=2
default_server=true
default_timeunit=year

usage() {
#cat << EOF
echo -e "
Usage: $0 [OPTIONS]
Delete branch if the last commit date of the branch is lower than the years passed as parameter 

Parameters:
-h  --help 
  Display this help and exit
-e  --expiration
  Expiration date in years [${ORANGE_COLOR}$default_expiration${NO_COLOR}]
-s  --server
  Delete branches from git server [${ORANGE_COLOR}$default_server${NO_COLOR}]  
-t  --timeunit 
  Timeunit of the expiration parameter [${ORANGE_COLOR}$default_timeunit${NO_COLOR}]  	
	Possible values: [${ORANGE_COLOR}minute,hout,day,week,month,year${NO_COLOR}]
"
}

exit_abnormal() {
  usage
  exit 1
}

options=$(getopt -u -o "ht:s:e:" -l "help,expiration:,server:,timeunit:" -- "$@")
if [ $? -ne 0 ]; then exit_abnormal; fi

set -- $options
while [ $# -gt 0 ]; do
    case $1 in
    -h|--help) shift; usage; exit 0 ;;
    -e|--expiration) shift; expiration=$1 ;;
		-s|--server) shift; server=$1 ;;
		-t|--timeunit) shift; timeunit=$1 ;;
    (--) shift; break;;
    (-*) echo "$0: error - unrecognized option $1" 1>&2; exit_abnormal;;
    (*) break;;
    esac
    shift
done

if [ -z "$expiration" ] ; then
  read -p "Expiration in years [$default_expiration years]: " expiration
  expiration=${expiration:-$default_expiration}
fi
server=${server:-$default_server}
timeunit=${timeunit:-$default_timeunit}

#La pasamos a segundos para facilitar la comparacion: +%s seconds since 1970-01-01 00:00:00 UTC
expire_date=$(date +%s -d"${expiration} ${timeunit} ago")
git pull --all
#git for-each-ref --sort=-authordate --format="%(refname) %(authordate)" refs/remotes | cut -d' ' -f1 | grep -Po "origin(/.*)+"
pattern="refs/heads"
if [ "$server" == "false" ]; then
	pattern="refs/remotes"	
fi

git for-each-ref --sort=-authordate --format="commit=%(objectname) ref=%(refname) last_commit_date=%(authordate:short)" --shell $pattern | \
while read entry
do
	eval "$entry"
	echo -e "\n***** BRANCH: $ref DATE: $last_commit_date"
	
	branch_name=$(echo $ref | cut -d'/' -f 3-)	
	branch_date=$(date +%s --date="$last_commit_date")
	#echo "DATE: $branch_date. EXPIRE_DATE: $expire_date"
	if test $(echo "$branch_name" | grep -iE "develop|master|release/release"); then
		echo "The branch: \"$branch_name\" is ommited"
		continue
	fi

	if [ $branch_date -lt $expire_date ]; then
		echo -e "ELIMINAR BRANCH: $branch_name. DATE: $(date +%F --date="$last_commit_date"). COMMIT: $commit"

		if [ "$server" == "true" ]; then
			echo "git branch -D $branch_name"
			#DESCOMENTAR
			#git branch -D $branch_name	
		else 
			#Comentamos esta linea que borrar la rama en local. Lo que interesa es hacer el borrado en remoto desde el cliente.
			##git branch -D $branch_name

			echo "git push origin --delete $branch_name"
			#DESCOMENTAR
			#git push origin --delete $branch_name
		fi
	fi
done

git gc --prune
git count-objects -vH
git prune

