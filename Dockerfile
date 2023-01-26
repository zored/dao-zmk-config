FROM zmkfirmware/zmk-build-arm:stable

COPY . /app
WORKDIR /app

RUN ./run.sh init

COMMAND ["sleep", "99999"]
