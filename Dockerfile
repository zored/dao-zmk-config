FROM zmkfirmware/zmk-build-arm:stable

WORKDIR /app
RUN ./run.sh init

CMD ["sleep", "99999"]
