FROM google/cloud-sdk:385.0.0
ARG MLFLOW_VERSION="1.26.0"

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

RUN echo "export LC_ALL=$LC_ALL" >> /etc/profile.d/locale.sh
RUN echo "export LANG=$LANG" >> /etc/profile.d/locale.sh

ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

RUN pip3 install --no-cache-dir --ignore-installed google-cloud-storage && \
    pip3 install --no-cache-dir PyMySQL mlflow==$MLFLOW_VERSION pyarrow

COPY start.sh start.sh
RUN chmod +x start.sh


ENTRYPOINT ["/tini", "--", "./start.sh"]
