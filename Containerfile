FROM ghcr.io/typst/typst:v0.13.1 AS typst

WORKDIR /tmp
COPY typst/ .

RUN typst compile ./resume.typ ./resume.pdf

FROM ghcr.io/gohugoio/hugo:v0.148.1 AS hugofs

# The hugo docker image defines a VOLUME directive, and even with --renew-anon-volumes
# docker compose doens't change the anonymous volume.
# Since this is a new image, it loses the VOLUME directive, unfortunately along with
# every other directive. So we manually specify USER/WORKDIR and copy the entire root
# filesystem.
# If this is ever fixed, or if docker adds a cli flag to ignore volume directives,
# these two lines can be removed, and the above FROM can be renamed to hugo.
FROM scratch AS hugo
COPY --from=hugofs / /

USER hugo

WORKDIR /project

COPY --chown=hugo hugo/ .
COPY --from=typst --chown=hugo /tmp/resume.pdf ./assets/pdf/resume.pdf

RUN hugo build --gc --minify

FROM scratch AS website

COPY --from=hugo /project/public /public
