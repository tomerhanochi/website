FROM ghcr.io/typst/typst:v0.13.1 AS typst

WORKDIR /tmp
RUN \
  --mount=type=bind,source=./typst,target=templates,readonly=true \
  --mount=type=bind,source=./hugo/content,target=content,readonly=true \
  --mount=type=bind,source=./hugo/assets/ttf,target=fonts,readonly=true \
  <<EOFRUN
set -eux -o pipefail

mkdir rendered

# Resume
typst compile templates/resume.typ rendered/resume.pdf

# Thumbnails
for index in $(find . -name index.md -or -name _index.md); do
  frontmatter="$( awk '/^---/{if (++n==2) exit; next} n==1' "${index}" )";
  # Extract the title from the frontmatter, by:
  # 1. Finding the line with the title:
  # 2. Removing the 'title: ' prefix and the '"' surrouding the title itself.
  title="$( echo "${frontmatter}" | grep '^title: ' | sed -E 's/^title:\s*"(.*)"/\1/g')";
  output_directory="rendered/$(dirname "${index}")";
  mkdir -p "${output_directory}";
  typst compile --font-path "fonts" --input "title=${title}" templates/thumbnail.typ "${output_directory}/thumbnail.png"
done;
EOFRUN

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
COPY --from=typst --chown=hugo /tmp/rendered/resume.pdf ./assets/pdf/resume.pdf
COPY --from=typst --chown=hugo /tmp/rendered/content/ ./content/

RUN hugo build --gc --minify

FROM scratch AS website

COPY --from=hugo /project/public/ /

CMD ["placeholder"]
