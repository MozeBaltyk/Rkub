#!/bin/bash
set -eo pipefail

### podman-load.sh
# This scripts have for purpose to upload images in you collections before to execute playbooks.
#  
# Two methodes to load images:
#   - search for images in roles helm charts: roles/*/files/helm/*.tgz
#   - list images in meta/ee-images.txt  
###

# To be use when building container
export PATH=$PATH:$HOME/.arkade/bin

if [[ $# -eq 0 ]]; then 
  format="oci-archive"
  printf "\e[1;34mINFO\e[m: Format by default: $format \n"
else 
  format=$1
  printf "\e[1;34mINFO\e[m: Format wanted: $format \n"
fi

list_requirement="helm yq podman"
dir="../.."

check_command(){
  for require in ${list_requirement}; do 
    if command -v ${require} >/dev/null 2>&1; then
      printf "\e[1;34mINFO\e[m: ${require} \e[1;32mis present.\n"
    else 
      printf "\e[1;31mERROR\e[m: ${require} is missing.\n"
      exit 1
    fi 
  done;
}

load_helm_images(){
  if ls ../../roles/*/files/helm/*.tgz 1> /dev/null 2>&1; then 
    # look in helm charts
    for helm in $(ls ../../roles/*/files/helm/*.tgz); do
      printf "\e[1;34m[INFO]\e[m Look for images in ${helm}...\n"

      images=$(helm template -g $helm |yq -N '..|.image? | select(.)'|sort|uniq|grep ":"|egrep -v '*:[[:blank:]]' || echo "")
      product=$(basename -a $helm | awk -F '-' '{print $1}')

      if [ "$images" != "" ]; then
        printf "\e[1;34m[INFO]\e[m Images found in the helm charts: ${images}\n"
        printf "\e[1;34m[INFO]\e[m Create directory: ${dir}/images/${product} \n"

        mkdir -p ${dir}/images/${product}

        while i= read -r image_name; do
          archive_name=$(basename -a $(awk -F : '{print $1}'<<<${image_name}));
          tag=$(awk -F : '{print $2}'<<<${image_name});
          printf "\e[1;34m[INFO]\e[m Pulling image ${archive_name} with tag: ${tag} \n"
          podman pull ${image_name};
          printf "\e[1;34m[INFO]\e[m Push ${image_name} in ${dir}/images/${product}/${archive_name}-${tag}\n"
          podman save ${image_name} --format ${format} -o ${dir}/images/${product}/${archive_name}-${tag};
        done <<< ${images}
      else
        printf "\e[1;34m[INFO]\e[m No Images found in the helm charts: ${helm}\n"
      fi
    done
  else
    printf "\e[1;34m[INFO]\e[m No helm charts found in roles/*/files/helm/*.tgz\n" || true
  fi
}

load_images(){
  # look in meta/ee-images.txt
  for line in $(cat  ../../meta/ee-images.txt | grep -v "^#" ); do
    echo "### Realize line: ${line} ###"
    image=$( echo "${line}" | awk  -F ";" '{print $1}' )
    tag=$( echo "${line}" | awk  -F ";" '{print $1}' | awk  -F ":" '{print $2}')
    archive_name=$(basename -a $(awk -F : '{print $1}'<<<$image));
    product=$( echo "${line}" | awk  -F ";" '{print $3}' )
    #dir=$( echo "${line}" | awk  -F ";" '{print $2}' )
    echo "#### Create directory: ${dir}/images/${product}/${archive_name}-${tag} ####"
    mkdir -p  ${dir}/images/${product}
    printf "\e[1;34m[INFO]\e[m Pulling image ${archive_name} with tag: ${tag}\n"
    podman pull ${image}
    printf "\e[1;34m[INFO]\e[m Push ${image_name} in ${dir}/images/${product}/${archive_name}-${tag}\n"
    podman save ${image} --format ${format} -o ${dir}/images/${product}/${archive_name}-${tag};
  done
}

check_command
load_helm_images
load_images