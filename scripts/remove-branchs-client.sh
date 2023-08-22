#!/bin/bash

#La pasamos a segundos para facilitar la comparacion: +%s seconds since 1970-01-01 00:00:00 UTC
expire_date=$(date +%s -d'2 year ago')
#git for-each-ref --sort=-authordate --format="%(refname) %(authordate)" refs/remotes | cut -d' ' -f1 | grep -Po "origin(/.*)+"
#Para listar los tags y su fecha de creacion:
#git for-each-ref --sort=-authordate --format="commit=%(objectname) ref=%(refname) last_commit_date=%(taggerdate:short)" refs/tags
git for-each-ref --sort=-authordate --format="commit=%(objectname) ref=%(refname) last_commit_date=%(authordate:short)" --shell refs/remotes | \
while read entry
do
	eval "$entry"
	#echo "BRANCH: $ref DATE: $last_commit_date"

	branch_date=$(date +%s --date="$last_commit_date")
	#echo "DATE: $branch_date. EXPIRE_DATE: $expire_date"

	if [ $branch_date -lt $expire_date ]; then
		branch_name=$(echo $ref | grep -Po "origin(/.*)+" | cut -d'/' -f2-)
		echo -e "\nELIMINAR BRANCH: $branch_name. DATE: $(date +%F --date="$last_commit_date"). COMMIT: $commit"
		#Podrías crear un tag antes de eliminar la rama
		tag_message=$(echo $branch_name | awk -F "/" '{print $NF}' -)
		tag_version=$(echo $tag_message | grep -m1 -wPo "\\w+\-?\\d+" | head -1)
		if [ -z "$tag_version" ]; then
			tag_version=$tag_message
		fi
		echo "git tag -a $tag_version $commit -m \"$tag_message\""
		echo "git push origin --delete $branch_name"
		git push origin --delete $branch_name
	fi
done

#Limpiamos en local las rama remotas que ya no existan. Este comando solo habría que hacerlo si el script se ejecuta en local
#git fetch origin –-prune --prune-tags (no se si interesa borrar los tags; son solo un puntero)
#git fetch origin –-prune
echo "git gc –-prune=now"
git gc --prune=now
