# tomerhanochi.com

Source for [tomerhanochi.com](https://tomerhanochi.com). Hugo renders the site, Typst renders the resume PDF and per-page thumbnails. Both are wired into a multi-stage [Containerfile](./Containerfile).

## Layout

- `hugo/` — Hugo source: content, layouts, assets, config
- `typst/` — Typst templates (resume + thumbnails)
- `Containerfile` — `typst` / `hugo` base aliases → `resume-builder`, `content-lister`, `thumbnail-builder` → `project` (assembled workspace) → `site-builder` (runs `hugo build`) → `website` (scratch image)
- `compose.yaml` — local dev server, builds to `project`

## Build the static site

```sh
docker buildx build --target website -f Containerfile -o type=local,dest=./public .
```

The `website` stage is a `scratch` image containing only the rendered output under `/`. `-o type=local` exports it to `./public/` on the host. This is what the GitHub Pages workflow ships.

## Run the dev server

```sh
docker compose up --build
```

Builds to the `project` stage (full Hugo workspace with resume PDF and thumbnails baked in, but pre-`hugo build`) and runs `hugo server --bind 0.0.0.0`. Site at [http://localhost:1313](http://localhost:1313).

For rebuild-on-save:

```sh
docker compose watch
```

`develop.watch` rebuilds on any change outside `.git/`, `public/`, and `.hugo_build.lock`.
