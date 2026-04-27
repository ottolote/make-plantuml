FROM plantuml/plantuml:latest

RUN apt-get update \
    && apt-get install --no-install-recommends -y bash entr tini make \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY Makefile /opt/Makefile
COPY --chmod=755 scripts/plantuml-tool.sh /usr/local/bin/plantuml-tool

WORKDIR /workspace

ENTRYPOINT ["tini", "--", "/usr/local/bin/plantuml-tool"]
CMD ["render"]
