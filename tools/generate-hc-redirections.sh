#!/bin/bash
###############LINK REDIRECTION GENERATOR###################

usage="$(basename "$0") [-h] [-d path] [-m path] [-s path] [-g git hosting] [-e environment] -- program to generate redirection links for OTC HC documents

where:
    -h  show this help text
    -d  path to document repositories
    -c  clone all repositories (optional)
    -m  path to otc metadata repository
    -s  path to system-config repository
    -g  set the git hostying type (gitea, github)
    -e  set the environment (internal, public, swiss_public)
    -p  product name (only single service will be processed)

environment variables:
    DOC_PATH            full path to document repositories
    META_PATH           full path to otc metadata repository
    GIT_HOSTING         set the git hostying type (gitea, github)
    SYSTEM_CONFIG_PATH  full path to system-config repository
    ENVIRONMENT         set the environment (internal, public, swiss_public)

example usage:
    ./redirect_github.sh -d /opt/github-services/ -m /opt/otc-metadata/ -s /opt/system-config/ -g github -e public"

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--doc-path)
            DOC_PATH="$2"
            shift # past argument
            shift # past value
            ;;
        -c|--clone-repos)
            CLONE_REPOS=YES
            shift # past argument
            ;;
        -m|--meta-path)
            META_PATH="$2"
            META_PATH=${META_PATH%/}
            shift # past argument
            shift # past value
            ;;
        -g|--git-hosting)
            GIT_HOSTING="$2"
            shift # past argument
            shift # past value
            ;;
        -s|--systemconfig-path)
            SYSTEM_CONFIG_PATH="$2"
            shift # past argument
            shift # past value
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift # past argument
            shift # past value
            ;;
        --default)
            DEFAULT=YES
            shift # past argument
            ;;
        -h|--help)
            echo "$usage"
            exit
            ;;
        -*|--*)
            echo "Unknown option $1"
            exit 1
            ;;
    esac
done

# Environmental Variables
DOC_PATH=${DOC_PATH:-"/opt/github/services"}
DOC_PATH=${DOC_PATH%/}
META_PATH=${META_PATH:-"/opt/otc-metadata"}
META_PATH=${META_PATH%/}
GIT_HOSTING=${GIT_HOSTING:-"github"}
SYSTEM_CONFIG_PATH=${SYSTEM_CONFIG_PATH:-"/opt/system-config"}
SYSTEM_CONFIG_PATH=${SYSTEM_CONFIG_PATH%/}
ENVIRONMENT=${ENVIRONMENT:-"public"}
DEFAULT=${DEFAULT:-"NO"}
CLONE_REPOS=${CLONE_REPOS:-""}
TARGET_REDIR_PATH="${SYSTEM_CONFIG_PATH}/kubernetes/kustomize/docsportal/overlays/helpcenter_${ENVIRONMENT}"

# Local Variables
gitea_link="ssh://git@gitea.eco.tsi-dev.otc-service.com:2222/"
github_link="git@github.com:"
[ "$ENVIRONMENT" == "internal" ] && var=$ENVIRONMENT || var="public"
[ "$ENVIRONMENT" == "swiss_public" ] && cloud_env="swiss" || cloud_env="eu_de"
[ "$GIT_HOSTING" == "gitea" ] && repo_link=${gitea_link} || repo_link=${github_link}

# Pre-checks
options="gitea,github"
if [[ ! $options =~ (^|,)$GIT_HOSTING($|,) ]]; then
    echo "choose one of the allowed options: ($options)"
    exit 1
fi

options="internal,public,swiss_public"
if [[ ! $options =~ (^|,)$ENVIRONMENT($|,) ]]; then
    echo "choose one of the allowed options: ($options)"
    exit 1
fi

if [ "${CLONE_REPOS}" ]; then
    if [ ! -d $DOC_PATH ]; then
        mkdir -p $DOC_PATH
    fi
    if [ ! -d $META_PATH ]; then
        mkdir -p $META_PATH
    fi
    if [ ! -d $SYSTEM_CONFIG_PATH ]; then
        mkdir -p $SYSTEM_CONFIG_PATH
    fi
fi

if [ ! -d $DOC_PATH ]; then
    echo "Directory $DOC_PATH doesn't exist!"
    exit 1
fi

if [ ! -d $META_PATH ]; then
    echo "Directory $META_PATH doesn't exist!"
    exit 1
fi

if [ ! -d $SYSTEM_CONFIG_PATH ]; then
    echo "Directory $SYSTEM_CONFIG_PATH doesn't exist!"
    exit 1
fi

# Summary of collected inputs
echo "DOCUMENT REPOS PATH  = ${DOC_PATH}"
echo "METADATA PATH        = ${META_PATH}"
echo "SYSTEM CONFIG PATH   = ${SYSTEM_CONFIG_PATH}"
echo "ENVIRONMENT          = ${ENVIRONMENT}"
echo "GIT HOSTING          = ${GIT_HOSTING}"
echo "CLONE REPOSITORIES   = ${CLONE_REPOS}"
echo "DEFAULT              = ${DEFAULT}"

# Clone All Repositories
if [ "${CLONE_REPOS}" ]; then
    git clone ${github_link}opentelekomcloud-infra/system-config.git $SYSTEM_CONFIG_PATH
    git clone ${gitea_link}infra/otc-metadata-rework.git ${META_PATH}

    for i in $META_PATH/otc_metadata/data/repositories/*.yaml ; do
        echo $i
        # repo=$(yq -o json -r '.repositories[] | select(.environment == strenv(var) and .cloud_environments[] == strenv(cloud_env)) | .repo' $i)
        repo=$(yq -o json -r '.repositories[] | select(.environment=="'"$var"'" and .cloud_environments[]=="'"$cloud_env"'") | .repo' $i)
        if [ "${repo}" ]; then
            echo $repo_link
            echo $repo
            echo $DOC_PATH
            echo git clone ${repo_link}${repo}.git ${DOC_PATH}/${repo/*\//}
            git clone ${repo_link}${repo}.git ${DOC_PATH}/${repo/*\//}
        fi
    done
fi
# Update metadata
META_PATH=${META_PATH}/otc_metadata/data
cd $META_PATH
if ! git diff --exit-code &> /dev/null; then
    echo Metadata repository contains local changes, exiting! ;
    exit 1;
fi

git checkout main
git pull

echo Fetched the latest metadata succesfully!

# Update git document repositories
cd $DOC_PATH
for i in $(ls -d */  | sed 's/\/$//g'); do
    cd $i;
    if ! git diff --exit-code &> /dev/null; then
        echo $i repository contains local changes, exiting! ;
        exit 1;
    fi
    cd $DOC_PATH;
done

cd $DOC_PATH;

for i in $(ls -d */  | sed 's/\/$//g'); do
    cd $i;
    git checkout main;
    git pull
    echo Fetched the latest document repository for service $i succefully!
    cd $DOC_PATH;
done

echo Fetched the latest document repositories succefully!

# Update System Config repository
cd $SYSTEM_CONFIG_PATH;
if ! git diff --exit-code &> /dev/null; then
    echo System Config repository contains local changes, exiting! ;
    exit 1;
fi

git checkout main
git pull

echo Fetched the latest system config repository succesfully!

# Link Generation
cd $DOC_PATH;
rm -f *.map
rm -f *.map.new
shopt -s nullglob

for file in $META_PATH/documents/*.yaml ; do
    if yq -e '.cloud_environments[] | select(.name=="'"$cloud_env"'")' $file &> /dev/null; then
        echo "$cloud_env env is present in $file file."
    else
        echo "$cloud_env env is NOT present in $file file! Skipping."
        continue
    fi
    entry=$(cat $file | yq . -o json |jq -r '.| @base64');
    decode="$(echo "$entry" |base64 --decode)";
    echo $entry;
    echo "$decode";
    service_name=$(echo "$decode" | jq -r .link | cut -f2 -d"/") ;
    service_type=$(echo "$decode" | jq -r .service_type);
    doc_type=$(echo "$decode" | jq -r .type);
    echo $doc_type
    echo $service_type
    echo $service_name
    if ! yq -e 'select(.hc_location)' $META_PATH/documents/$service_type-* &> /dev/null ; then
        echo "cannot find origin location for redirection! Skipping."
        continue ;
    fi
    if yq -e 'select(.disable_import == true)' $file &> /dev/null ; then
        echo skipping service $service_type and document $doc_type
        continue ;
    fi
    rst_location=$(echo "$decode" | jq -r .rst_location);
    if yq -e '.cloud_environments[] | select(.name=="'"$cloud_env"'" and (.visibility!="public" and .visibility!="hidden"))' $META_PATH/services/$service_type.yaml &> /dev/null; then
        repo=$(yq -o json -r '.repositories[] | select(.environment=="'"$var"'" and .cloud_environments[]=="'"$cloud_env"'") | .repo' $META_PATH/repositories/$service_type.yaml)
        echo $repo
        cat $META_PATH/services/$service_type.yaml
        files=( $DOC_PATH/$service_name/$rst_location/* )
        echo ${#files[@]}
        if yq -e '.cloud_environments[] | select(.name=="eu_de" and .visibility=="internal")' $META_PATH/services/$service_type.yaml &> /dev/null && [[ ${#files[@]} -lt 4 ]]; then
            echo "service $service_name is only internal and has no content therefore skipping redirections!"
            continue ;
        fi
    fi
    hc_old_location=$(echo "$decode" | jq -r .hc_location);
    hc_new_location=$(echo "$decode" | jq -r .link) ;
    echo $service_name $hc_old_location $rst_location $hc_new_location;
    if cd $DOC_PATH/$service_name/$rst_location; then
        for file in $(find .  -name \*.rst); do
            hc_old_name=$(grep original_name $file | cut -f2 -d" ");
            hc_new_name=$(echo ${file:1:-4} | cut -f2- -d"/");
            echo \ \ /$hc_old_location/$hc_old_name $hc_new_location$hc_new_name.html\; >> $DOC_PATH/redirect-$service_name.map;
        done;
    fi
done

# Removing duplicates
cd $DOC_PATH
for i in *.map ; do
    echo $i;
    duplicate=$(cat $i | cut -f3 -d" " | sort | uniq -cd | grep .)
    echo $duplicate
    if [ -n "${duplicate}" ]; then
        pattern=$(echo $duplicate|cut -f2 -d" ")
        echo Found duplicate source for redirection: $pattern which would break redirection, forciblly removing them!
        echo $pattern
        sed -i "\:$pattern:d" $i
    fi
done

# Remove null values
cd $DOC_PATH
sed -i '/\/null\//d' *.map

# Add en-us redirections and sort
cd $DOC_PATH
for i in *.map; do
    echo $i;
    sed 's/  \(.*\)/  \/en-us\1/g' $i >> $i.new;
    cat $i.new >> $i;
    rm $i.new
    sort -n $i > $i.tmp
    mv $i.tmp $i
done

# Move files to system-config
cd $DOC_PATH
for i in *.map; do
    newname=${i:9:-4};
    mv $i ${TARGET_REDIR_PATH}/configs/redirect_maps/$newname;
done;


# Split files larger than 1000 lines
cd ${TARGET_REDIR_PATH}/configs/redirect_maps/;
for i in $(ls * | egrep -v "\-a[a-z]$"); do
    count=$(wc -l $i | cut -f1 -d" ");
    if [ "$count" -gt "1000" ] ; then
        echo $i $count;
        split -l 1000 $i $i- ;
        rm $i;
    fi;
done

## Updating nginx-site.conf if necessary
#cd ${TARGET_REDIR_PATH}/configs/redirect_maps/;
#for i in *; do
#    if ! grep "$i;" ${TARGET_REDIR_PATH}/configs/nginx-site.conf &> /dev/null; then
#        echo New redirection file $i to be added to nginx-site.conf
#        block=$(grep "include /etc/nginx/redirect/" ${TARGET_REDIR_PATH}/configs/nginx-site.conf)
#        new_item="include /etc/nginx/redirect/$i;";
#        new_block=$(echo $block $new_item | sed 's/; /;\n/g' |sort -n | sed -z 's/;\n/;\\n/g')
#        end_pattern="# server_names_hash_bucket_size 128;"
#        sed -z -i "s:  include.*\n$end_pattern:  $new_block}\n\n$end_pattern:g" ${TARGET_REDIR_PATH}/configs/nginx-site.conf
#        sed -i 's/^include.*/  &/g' ${TARGET_REDIR_PATH}/configs/nginx-site.conf
#    fi
#done

# Updating nginx-site.conf if necessary
cd ${TARGET_REDIR_PATH}/configs/redirect_maps/;
new_block="";
for i in *; do
    echo Redirection file $i to be added to nginx-site.conf
    new_item="include /etc/nginx/redirect/$i;";
    new_block=$(echo $new_block $new_item | sed 's/; /;\n/g' |sort -n | sed -z 's/;\n/;\\n/g')
done
end_pattern="# server_names_hash_bucket_size 128;"
sed -z -i "s:  include.*\n$end_pattern:  $new_block}\n\n$end_pattern:g" ${TARGET_REDIR_PATH}/configs/nginx-site.conf
sed -i 's/^ include.*/ &/g' ${TARGET_REDIR_PATH}/configs/nginx-site.conf

# Updating kustomization.yaml if necessary
cd ${TARGET_REDIR_PATH}/configs/redirect_maps/;
# services=$(grep configs/redirect_map ${TARGET_REDIR_PATH}/kustomization.yaml | cut -f2 -d'"' | cut -f3 -d"/")
services=""
echo "Generating kustomization.yaml file"
for i in *; do
    #if ! grep "/$i\"" ${TARGET_REDIR_PATH}/kustomization.yaml &> /dev/null; then
        echo "Redirection file $i to be added to kustomization.yaml"
        services=$(echo $services $i | sed 's/ /\n/g' | sort -n)
    #fi
done
block=$(cat <<EOF
  - name: "nginx-config"
    behavior: "merge"
    # rather then adding redirect_map: helpcenter to every CM we rather replace
    # this value for this CM.
    options:
      labels:
        redirect_map: "no"
    files:
      - "configs/nginx-site.conf"
EOF
)
for i in $services; do

    item=$(cat <<EOF
  - name: "$i"
    files:
      - "configs/redirect_maps/$i"
EOF
    )
    block+=$'\n'$item
done
echo "$block" | sed -z 's/\n/\\n/g'
new_block=$(echo "$block" | sed -z 's/\n/\\n/g')
end_pattern='# kiwigrid sidecar requires "redirect_map: helpcenter" label on all CMs as a'

sed -z -i "s|configMapGenerator:.*\n$end_pattern|configMapGenerator:\n$new_block\n$end_pattern|g" ${TARGET_REDIR_PATH}/kustomization.yaml

# This approach doesn't work as yaml->json->yaml results in broken and more ugly yaml format, but keeping as interesting different approach
# cd ${TARGET_REDIR_PATH}/configs/redirect_maps/;
# for i in *; do
#     if ! grep "/$i\"" ${TARGET_REDIR_PATH}/kustomization.yaml &> /dev/null; then
#         echo New redirection file $i to be added to kustomization.yaml
#         yq . ${TARGET_REDIR_PATH}/kustomization.yaml | jq '
#             del(.configMapGenerator[] | select(.name == "nginx-config") ) |
#             .configMapGenerator += [{ "name": "'"$i"'", "files": [ "configs/redirect_maps/'"$i"'" ] }] |
#             .configMapGenerator|=sort_by(.name) |
#             .configMapGenerator |= [{ "name": "nginx-config", "behavior": "merge", "options": { "labels": { "redirect_map": "no" } }, "files": [ "configs/nginx-site.conf" ] }] + .
#         ' > ${TARGET_REDIR_PATH}/kustomization.yaml.new
#         mv ${TARGET_REDIR_PATH}/kustomization.yaml.new ${TARGET_REDIR_PATH}/kustomization.yaml
#     fi
# done

# Push changes to system-config and create PR
cd ${TARGET_REDIR_PATH}/;
branch=${ENVIRONMENT}_redir_$(date '+%Y-%m-%d')
git checkout -b $branch
git add .
git commit -m "new redirections for $ENVIRONMENT HC portal"
git push origin $branch
