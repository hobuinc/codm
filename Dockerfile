FROM opendronemap/odm:gpu  as build

RUN pip3 install  awscli


COPY entry.sh /

ENTRYPOINT [ "/entry.sh" ]
