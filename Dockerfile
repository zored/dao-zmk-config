FROM zmkfirmware/zmk-build-arm:stable

WORKDIR /app
COPY run.sh /run.sh
RUN /run.sh init

CMD ["sleep", "99999"]
