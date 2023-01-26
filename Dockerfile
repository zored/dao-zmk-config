FROM zmkfirmware/zmk-build-arm:stable

WORKDIR /app

RUN ./run.sh init

COMMAND ["sleep", "99999"]
