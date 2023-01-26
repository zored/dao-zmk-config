FROM zmkfirmware/zmk-build-arm:stable

COPY ./ /app/
WORKDIR /app/
RUN ./run.sh init

CMD ["sleep", "99999"]
