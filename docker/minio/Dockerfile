
FROM minio/minio:latest

WORKDIR /data


COPY init_minio.sh /usr/local/bin/init_minio.sh
RUN chmod +x /usr/local/bin/init_minio.sh

EXPOSE 9000 9001

# Lancement
ENTRYPOINT ["/bin/sh", "-c", "minio server /data --console-address ':9001' & sleep 5 && /usr/local/bin/init_minio.sh && wait -n"]
