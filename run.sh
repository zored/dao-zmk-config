#!/bin/sh
set -ex

case $1 in
  image)
    case $2 in
      flow-build-docker)
        for v in prepare run; do
          $0 image $v
        done
        ;;
      flow|flow-build-firwmare)
        docker start zored-dao
        for v in sync build save; do
          $0 image $v
        done
        ;;
      bash)
        docker exec -it zored-dao bash
        ;;
      prepare)
        docker build -t zored-dao .
        ;;
      run)
        docker run -d --name zored-dao zored-dao
        ;;
      build)
        docker exec -it zored-dao ./run.sh build
        ;;
      sync)
        docker cp ./ zored-dao:/app/
        ;;
      save)
        d="./flash/$(date +%s)"
        docker cp zored-dao:/app/flash "$d"
        cp "$d/"* ./flash/
        ;;
      *)
        exit 2
        ;;
    esac
    ;;
  flash|flash-mac)
    while ! ls /Volumes/NRF52BOOT/; do
      echo 'no volume, waiting'
      sleep 3
    done
    cp "flash/$3/dao_$2-zmk.uf2" /Volumes/NRF52BOOT/
    osascript -e 'tell application "Finder" to eject (every disk whose ejectable is true)'
    ;;
  init)
    apt update
    apt install -y curl
    curl https://github.com/mikefarah/yq/releases/download/v4.30.8/yq_linux_amd64 -Lo /usr/local/bin/yq
    chmod +x /usr/local/bin/yq
    mkdir -p build/artifacts
    ;;
  build)
    west init -l config || true
    west update
    west zephyr-export
    rm -rf flash/*

    yq eval '.include[] | "SHIELD=" + (.shield // "") + " BOARD=" + .board' build.yaml > build/envs
    cat build/envs | while read -r v; do
      eval "export $v"
      if [ -n "$SHIELD" ]; then
        export EXTRA_CMAKE_ARGS="-DSHIELD=$SHIELD" ARTIFACT_NAME="$SHIELD-$BOARD-zmk" DISPLAY_NAME="$SHIELD - $BOARD"
      else
        export EXTRA_CMAKE_ARGS="" DISPLAY_NAME="$BOARD" ARTIFACT_NAME="$BOARD-zmk"
      fi
      west build -p -s zmk/app -b $BOARD -- -DZMK_CONFIG=/app/config $EXTRA_CMAKE_ARGS
      cat build/zephyr/.config | grep -v "^#" | grep -v "^$"
      mkdir -p ./flash/
      if [ -f build/zephyr/zmk.uf2 ]; then
        cp build/zephyr/zmk.uf2 "flash/$ARTIFACT_NAME.uf2"
      elif [ -f build/zephyr/zmk.hex ]; then
        cp build/zephyr/zmk.hex "flash/$ARTIFACT_NAME.hex"
      fi
    done
    ;;
  *)
    exit 1
    ;;
esac