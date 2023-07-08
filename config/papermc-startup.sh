#!/bin/bash

latest_papermc_version=$PAPERMC_VERSION
latest_papermc_build=$PAPERMC_BUILD

if [[ -z "$latest_papermc_version" || "$latest_papermc_version" == "latest" ]]; then
    echo "Checking latest PaperMC version..."
    latest_papermc_version=$(
        curl "https://api.papermc.io/v2/projects/paper" |
            awk 'BEGIN{RS="]"; FS="\"versions\""}NF>1{print $NF}' |
            awk -F'"' '{ for(i=2; i<=NF; i+=2) print $i }' |
            sort -t "." -k1,1n -k2,2n -k3,3n |
            tail -n 1
    )

    echo "Latest PaperMC version: $latest_papermc_version"
fi

if [[ -z "$latest_papermc_build" || "$latest_papermc_build" == "latest" ]]; then
    echo "Checking latest PaperMC $latest_papermc_version build..."
    latest_papermc_build=$(
        curl "https://api.papermc.io/v2/projects/paper/versions/$latest_papermc_version" |
            awk 'BEGIN{RS="]"; FS="\"builds\""}NF>1{print $NF}' |
            grep -o '[0-9]\+' |
            sort |
            tail -n 1
    )

    echo "Latest PaperMC $latest_papermc_version build: $latest_papermc_build"
fi

papermc_jar="paper-$latest_papermc_version-$latest_papermc_build.jar"
papermc_url="https://api.papermc.io/v2/projects/paper/versions/$latest_papermc_version/builds/$latest_papermc_build/downloads/$papermc_jar"

if [[ ! -f "/app/data/cache/$papermc_jar" ]]; then
    echo "JAR not found in cache."

    if [[ -f "/app/data/cache/$papermc_jar.part" ]]; then
        echo "Removing partial download from cache..."
        rm -f "/app/data/cache/$papermc_jar.part"
    fi

    echo "Downloading \"$papermc_jar\"..."
    mkdir -p "/app/data/cache"
    curl "$papermc_url" -o "/app/data/cache/$papermc_jar.part"

    echo "Moving downloaded JAR..."
    mv "/app/data/cache/$papermc_jar.part" "/app/data/cache/$papermc_jar"
    echo "\"$papermc_jar\" downloaded."
fi

if [[ ! -f "/app/data/cache/$papermc_jar" ]]; then
    echo "PaperMC JAR not available."
    exit 1
fi

if [[ "$MINECRAFT_ACCEPTEULA" == "true" ]]; then
    accept_eula=false

    if [[ -f "/app/data/eula.txt" ]] && grep -q "eula=false" "/app/data/eula.txt"; then
        echo "Marking EULA as accepted..."
        sed -i "/eula=false/c\eula=true" /app/data/eula.txt
    elif [[ ! -f "/app/data/eula.txt" ]]; then
        echo "Creating an EULA accepted marker..."
        echo eula=true > /app/data/eula.txt
    fi
fi

echo "Launching PaperMC $latest_papermc_version (build $latest_papermc_build)..."

cd /app/data
java -XX:MaxRAMPercentage=80 -jar "/app/data/cache/$papermc_jar" --nogui
