#!/bin/sh
set -ex

case $1 in
  image)
    case $2 in
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
      *)
        exit 2
        ;;
    esac
    ;;
  init)
    apt update
    apt install -y curl
    curl https://github.com/mikefarah/yq/releases/download/v4.30.8/yq_linux_amd64 -Lo /usr/local/bin/yq
    chmod +x /usr/local/bin/yq
    mkdir -p build/artifacts
    ;;
  build)
    yq eval '.include[] | "SHIELD=" + (.shield // "") + " BOARD=" + .board' build.yaml > build/envs
    cat build/envs | while read -r v; do
      eval "export $v"
      if [ -n "$SHIELD" ]; then
        EXTRA_CMAKE_ARGS="-DSHIELD=$SHIELD"
        ARTIFACT_NAME="$SHIELD-$BOARD-zmk"
        DISPLAY_NAME="$SHIELD - $BOARD"
      else
        EXTRA_CMAKE_ARGS=
        DISPLAY_NAME="$BOARD"
        ARTIFACT_NAME="$BOARD-zmk"
      fi
      west init -l config
      west update
      west zephyr-export
      west build -s zmk/app -b $BOARD -- -DZMK_CONFIG=./config $EXTRA_CMAKE_ARGS
      cat build/zephyr/.config | grep -v "^#" | grep -v "^$"
      if [ -f build/zephyr/zmk.uf2 ]; then
        cp build/zephyr/zmk.uf2 "build/artifacts/$ARTIFACT_NAME.uf2"
      elif [ -f build/zephyr/zmk.hex ]; then
        cp build/zephyr/zmk.hex "build/artifacts/$ARTIFACT_NAME.hex"
      fi
    done
    ;;
  *)
    exit 1
    ;;
esac