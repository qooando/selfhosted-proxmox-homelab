FROM postgres:17
# install packages
RUN apt update && \
    apt install -y wget
# install pgvecto.rs
#RUN cd /tmp && \
#    wget https://github.com/tensorchord/pgvecto.rs/releases/download/v0.4.0/vectors-pg17_0.4.0_amd64.deb && \
#    dpkg -i vectors-pg17_0.4.0_amd64.deb && \
#    rm vectors-pg17_0.4.0_amd64.deb
RUN cd /tmp && \
    wget https://github.com/tensorchord/pgvecto.rs/releases/download/v0.3.0/vectors-pg17_0.3.0_amd64_vectors.deb && \
    dpkg -i vectors-pg17_0.3.0_amd64_vectors.deb && \
    rm vectors-pg17_0.3.0_amd64_vectors.deb
COPY ./init/ /docker-entrypoint-initdb.d/
