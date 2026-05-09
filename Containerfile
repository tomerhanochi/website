#----- IMAGES -----#
FROM ghcr.io/typst/typst:v0.14.2@sha256:b756590c0713ca5707654f3035e345c1d25dece2051817c11cc5591ae89992d4 AS typst
WORKDIR /tmp

FROM ghcr.io/gohugoio/hugo:v0.161.1@sha256:cef5b132b220dd5a661787d410124afe807b0ed3a79829604bdf0c3eefb85488 AS hugo
WORKDIR /tmp

#----- BUILD STEPS -----#
FROM typst AS resume-builder
RUN \
  --mount=type=bind,source=./typst,target=templates,readonly=true \
  --mount=type=bind,source=./hugo/assets/ttf,target=fonts,readonly=true \
  <<EOFRUN
set -eux -o pipefail

mkdir -p rendered

# Resume
typst compile --font-path "fonts" templates/resume.typ rendered/resume.pdf
EOFRUN

FROM hugo AS content-lister
RUN \
  --mount=type=bind,source=./hugo,target=/src,readonly=true \
  hugo list published -s /src --noBuildLock > content.csv

FROM typst AS thumbnail-builder
RUN \
  --mount=type=bind,source=./typst,target=templates,readonly=true \
  --mount=type=bind,source=./hugo/assets/ttf,target=fonts,readonly=true \
  --mount=type=bind,from=content-lister,source=/tmp/content.csv,target=/tmp/content.csv \
  <<EOFRUN
set -eux -o pipefail

# Render one thumbnail per published content item, using titles from `hugo list published`
{
  read -r _header
  while IFS=, read -r path slug title rest; do
    output_directory="rendered/$(dirname "${path}")"
    mkdir -p "${output_directory}"
    typst compile --font-path "fonts" --input "title=${title}" templates/thumbnail.typ "${output_directory}/thumbnail.png"
  done
} < /tmp/content.csv
EOFRUN

FROM hugo AS project

COPY --chown=hugo hugo/ .
COPY --chown=hugo --from=resume-builder /tmp/rendered/resume.pdf ./assets/pdf/resume.pdf
COPY --chown=hugo --from=thumbnail-builder /tmp/rendered/content/ ./content/

FROM project AS site-builder

RUN hugo build --gc --minify

FROM scratch AS website

COPY --from=site-builder /tmp/public/ /

CMD ["placeholder"]
