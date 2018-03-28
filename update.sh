#!/bin/bash
# needs jq, curl, awk and sed

set -e

ENDPOINT=https://api.github.com/repos/ubccr/xdmod-federated
BRANCHFILTER='xdmod[0-9]\.[0-9]'

branches=$(curl -s $ENDPOINT/releases | jq '.[].target_commitish' | grep -o $BRANCHFILTER)
latest=$(curl -s $ENDPOINT/releases/latest | jq '.target_commitish' | grep -o $BRANCHFILTER)

for branch in $branches;
do
    version=${branch:5}
    filelist=$(git ls-tree --name-only -r origin/$branch docs | egrep '.*\.md$')
    for file in $filelist;
    do
        outfile=$(echo $file | awk 'BEGIN{FS="/"} { for(i=2; i < NF; i++) { printf "%s/", $i } print "'$version'/" $NF}')
        mkdir -p $(dirname $outfile)
        sedscript='/^redirect_from:$/{N;s/^redirect_from:\n    - ""/redirect_from:\n    - "\/'$version'\/"/}'
        if [ "$branch" = "$latest" ]; then
            sedscript='/^redirect_from:$/a\    - "\/'$version'\/"'
            basefile=$(basename $outfile .md)
            if [ "docs/${basefile}.md" = "$file" ]; then
                cat > ${basefile}.md << EOF
---
redirect_to: /$version/${basefile}.html
---
EOF
            fi
        fi
        git show refs/remotes/origin/$branch:$file | sed "$sedscript" > $outfile
    done
done
