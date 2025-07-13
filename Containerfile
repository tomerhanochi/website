FROM ghcr.io/typst/typst:v0.13.1 AS typst

WORKDIR /tmp
COPY typst/ .

RUN typst compile ./resume.typ ./resume.pdf

FROM ghcr.io/gohugoio/hugo:v0.148.1 AS hugo

ARG BASE_URL

USER hugo

COPY --chown=hugo:hugo hugo/ .
COPY --from=typst --chown=hugo:hugo /tmp/resume.pdf ./public/resume.pdf

RUN hugo --gc --minify --baseURL ${BASE_URL}
