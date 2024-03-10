#! /bin/bash

#year=$(date +%y)

git clone https://github.com/CoppeliaRobotics/CoppeliaSimLib.git

pushd CoppeliaSimLib
git ls-remote --tags --sort=committerdate | grep -o 'v.*' > ../tag.txt
popd

tags=$(cat tag.txt)
mkdir -p link
mkdir -p release
for tag in $tags; do
    if [ ! -f ./link/${tag}.txt ]; then
        touch ./link/${tag}.txt
        version=$(echo ${tag} | sed -e "s/^\s*./V/g" | sed -e "s/-/_/g" | sed -e "s/\./_/g")
        echo "Processing version: ${version}"
        pushd CoppeliaSimLib && tag_date=$(git log -1 --format=%as coppeliasim-${tag}) && popd
        year=$(date -d ${tag_date} +%y)
        nums=(0 2 4)
        for i in ${nums[@]}; do
            if ((year%2 == 0)); then
                ubuntu_year=$((year-i))
            else
                ubuntu_year=$((year-i-1))
            fi

            #echo $ubuntu_year
            url="https://downloads.coppeliarobotics.com/${version}/CoppeliaSim_Edu_${version}_Ubuntu${ubuntu_year}_04.tar.xz"
            wget --spider ${url}
            if [ $? -eq 0 ]; then
                echo "${version} ${url}" >> ./link/${tag}.txt
                wget -P release ${url} 
            fi
        done

        if [ -s ./link/${tag}.txt ]; then
            # The file is not-empty.
            touch release_tag.txt
            echo "${tag}" > release_tag.txt
            break
        else
            # The file is empty.
            rm -f ./link/${tag}.txt
        fi
    fi
done
