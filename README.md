# Octopus Energy tech blog

This repo provides a simple Jekyll site for the https://tech.octopus.energy
site, which is hosted with [Github pages](https://docs.github.com/en/free-pro-team@latest/github/working-with-github-pages/setting-up-a-github-pages-site-with-jekyll).

## Installation

Ensure you have `docker` running locally.

## Local development

Run the local development server with:

    $ make server

Create new posts by creating a markdown file in `_posts/` with filename format
`YYYY-MM-DD-article-slug` (e.g. `2019-02-20-some-article-description.md`).

Publish by merging your pull-request to `master`.

To upgrade Ruby dependencies, run:

    $ make upgrade
