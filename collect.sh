#! /bin/bash

#year=$(date +%y)

git clone https://github.com/CoppeliaRobotics/CoppeliaSimLib.git

pushd CoppeliaSimLib
git ls-remote --tags --sort=committerdate | grep -o 'v.*' > ../tag.txt
popd

tags=$(cat tag.txt)

for tag in $tags; do
    old_link=()

    if [ -f ./link/${tag}.txt ]; then
        old_link_nossl=($(grep -oP "http://\K[^']+" ./link/${tag}.txt))
        for link in "${old_link_nossl[@]}"; do
            old_link+=("http://" + link)
        done

        old_link_ssl=($(grep -oP "https://\K[^']+" ./link/${tag}.txt))
        for link in "${old_link_ssl[@]}"; do
            old_link+=("https://" + link)
        done

        timestamp_line=$(head -n 1 ./link/${tag}.txt)
        echo "Last timestamp " + $timestamp_line

        first_bracket=${timestamp_line:(1)}
        echo $first_bracket
        last_bracket=${timestamp_line:(-1)}

        timestamp="[$(date --utc +%FT%T.%3NZ)]"
        if [ "${first_bracket}" == "[" ] && [ "${last_bracket}" == "]" ]; then
            sed -i "1s/.*/$timestamp/" ./link/${tag}.txt
        else
            sed -i "1s/^/$timestamp\n/" ./link/${tag}.txt
        fi
    else
        touch ./link/${tag}.txt
        echo "[$(date --utc +%FT%T.%3NZ)]" > ./link/${tag}.txt
    fi

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
            for old_url in "${old_link[@]}"
            do
                if [ "$old_url" == "$url" ]; then
                    echo "Already exist"
                    break
                else
                    echo "${url}" >> ./link/${tag}.txt
                    old_link+=($url)
                fi
            done
        fi
    done

    for link in "${old_link[@]}"
    do
        wget --spider ${url}
        if [ $? -eq 0 ]; then
            wget -P release ${url}
        fi
    done
             
    touch release_tag.txt
    echo "${tag}" > release_tag.txt

    if [ ${#old_link[@]} -eq 0 ]; then
        touch release_link.txt
        echo "Lost" > release_link.txt
        break
    else
        echo "Found " + "${#old_link[@]}" + " links"
        break
    fi
done
