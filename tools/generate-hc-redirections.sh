#!/bin/bash
###############LINK REDIRECTION GENERATOR###################

usage="$(basename "$0") [-h] [-d path] [-m path] [-s path] [-g git hosting] [-e environment] -- program to generate redirection links for OTC HC documents

where:
    -h  show this help text
    -d  path to document repositories
    -m  path to otc metadata repository
    -s  path to system-config repository
    -g  set the git hostying type (gitea, github)
    -e  set the environment (internal, public, swiss_public)

environment variables:
    DOC_PATH            path to document repositories
    META_PATH           path to otc metadata repository
    GIT_HOSTING         set the git hostying type (gitea, github)
    SYSTEM_CONFIG_PATH  path to system-config repository
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
META_PATH=${META_PATH}/otc_metadata/data
GIT_HOSTING=${GIT_HOSTING:-"github"}
SYSTEM_CONFIG_PATH=${SYSTEM_CONFIG_PATH:-"/opt/system-config"}
SYSTEM_CONFIG_PATH=${SYSTEM_CONFIG_PATH%/}
ENVIRONMENT=${ENVIRONMENT:-"public"}
DEFAULT=${DEFAULT:-"NO"}
TARGET_REDIR_PATH="${SYSTEM_CONFIG_PATH}/kubernetes/docsportal/overlays/helpcenter_${ENVIRONMENT}"

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
echo "DEFAULT              = ${DEFAULT}"

# Update metadata
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

for row in $(cat $META_PATH/documents/*.yaml | yq . |jq -r '.| @base64') ; do
    decode=$(echo $row |base64 --decode);
    echo $row;
    echo $decode;
    service_name=$(echo $decode | jq -r .link | cut -f2 -d"/") ;
    service_type=$(echo $decode | jq -r .service_type);
    doc_type=$(echo $decode | jq -r .type);
    echo $doc_type
    echo $service_type
    if egrep "^environment: hidden|^environment: internal" $META_PATH/services/$service_type.yaml &> /dev/null ; then
        continue ;
    fi
    if ! egrep "hc_location" $META_PATH/documents/$service_type-* &> /dev/null ; then
        continue ;
    fi
    if egrep "disable_import: true" $META_PATH/documents/$service_type-$doc_type.yaml &> /dev/null ; then
        echo skipping service $service_type and document $doc_type
        continue ;
    fi
    hc_old_location=$(echo $decode | jq -r .hc_location);
    rst_location=$(echo $decode | jq -r .rst_location);
    hc_new_location=$(echo $decode | jq -r .link) ;
    echo $service_name $hc_old_location $rst_location $hc_new_location;
    if cd $DOC_PATH/$service_name/$rst_location; then
        for file in $(find .  -name \*.rst); do
            hc_old_name=$(grep original_name $file | cut -f2 -d" ");
            hc_new_name=$(echo $file | cut -f2 -d"."| cut -f2- -d"/");
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

# Add en-us redirections
cd $DOC_PATH
for i in *.map; do
    echo $i;
    sed 's/  \(.*\)/  \/en-us\1/g' $i >> $i.new;
    cat $i.new >> $i;
    rm $i.new
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

# Updating nginx-site.conf if necessary
cd ${TARGET_REDIR_PATH}/configs/redirect_maps/;
for i in *; do
    if ! grep "$i;" ${TARGET_REDIR_PATH}/configs/nginx-site.conf &> /dev/null; then
        echo New redirection file $i to be added to nginx-site.conf
        block=$(grep "include /etc/nginx/redirect/" ${TARGET_REDIR_PATH}/configs/nginx-site.conf)
        new_item="include /etc/nginx/redirect/$i;";
        new_block=$(echo $block $new_item | sed 's/; /;\n/g' |sort -n | sed -z 's/;\n/;\\n/g')
        end_pattern="# server_names_hash_bucket_size 128;"
        sed -z -i "s:  include.*\n$end_pattern:  $new_block}\n\n$end_pattern:g" ${TARGET_REDIR_PATH}/configs/nginx-site.conf
        sed -i 's/^include.*/  &/g' ${TARGET_REDIR_PATH}/configs/nginx-site.conf
    fi
done

# Updating kustomization.yaml if necessary
cd ${TARGET_REDIR_PATH}/configs/redirect_maps/;
services=$(grep configs/redirect_map ${TARGET_REDIR_PATH}/kustomization.yaml | cut -f2 -d'"' | cut -f3 -d"/")

for i in *; do
    if ! grep "/$i\"" ${TARGET_REDIR_PATH}/kustomization.yaml &> /dev/null; then
        echo New redirection file $i to be added to kustomization.yaml
        services=$(echo $services $i | sed 's/ /\n/g' | sort -n)
    fi
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
