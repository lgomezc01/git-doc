#!/bin/bash

#La pasamos a segundos para facilitar la comparacion: +%s seconds since 1970-01-01 00:00:00 UTC
expire_date=$(date +%s -d'1 year ago')
#git for-each-ref --sort=-authordate --format="%(refname) %(authordate)" refs/remotes | cut -d' ' -f1 | grep -Po "origin(/.*)+"
git for-each-ref --sort=-authordate --format="commit=%(objectname) ref=%(refname) last_commit_date=%(authordate:short)" --shell refs/heads | \
while read entry
do
        eval "$entry"
        #echo "BRANCH: $ref DATE: $last_commit_date"

        branch_name=$(echo $ref | cut -d'/' -f 3-)
        branch_date=$(date +%s --date="$last_commit_date")
        #echo "DATE: $branch_date. EXPIRE_DATE: $expire_date"

        if [ $branch_date -lt $expire_date ]; then
                echo -e "\nELIMINAR BRANCH: $branch_name. DATE: $(date +%F --date="$last_commit_date"). COMMIT: $commit"
                #Podrías crear un tag antes de eliminar la rama
                tag_message=$(echo $branch_name | awk -F "/" '{print $NF}' -)
                tag_version=$(echo $tag_message | grep -m1 -wPo "\\w+\-?\\d+" | head -1)
                if [ -z "$tag_version" ]; then
                        tag_version=$tag_message
                fi
                echo "git tag -a $tag_version $commit -m \"$tag_message\""
                echo "git push origin –-delete $tag_message"
                #git push origin –-delete $ref
                git branch -D $branch_name
        fi
done

git gc --prune
git count-objects -vH
git prune

