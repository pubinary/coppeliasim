#! /bin/bash

files=$(ls ./extra_link)

for file in $files; do
    if [ -s ./extra_link/${file} ]; then
        #There are extra links to process
        links=$(cat ./extra_link/${file})

        for link in ${links[@]}; do
            wget --spider ${link}
            if [ $? -eq 0 ]; then
                echo "Downloading ${link}"
                wget -P release ${link} 
            fi
        done

        extension="${file##*.}"
        tag="${file%.*}"
        touch release_tag.txt
        echo "${tag}" > release_tag.txt
        truncate -s -1 release_tag.txt

        #Empty the file
        true > ./extra_link/${file}
        break
    fi
done
