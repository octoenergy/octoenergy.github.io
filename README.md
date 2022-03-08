# Octopus Energy tech blog

This repo provides a [Jekyll][jekyll] site for the <https://tech.octopus.energy>
site. The site is published using [Github Pages][github_pages].

[jekyll]: https://jekyllrb.com/
[github_pages]:
  https://docs.github.com/en/free-pro-team@latest/github/working-with-github-pages/setting-up-a-github-pages-site-with-jekyll

## Installation

Ensure you have `docker` running locally.

## Adding new blog posts

Add new posts by creating a markdown file in `_posts/` with filename format
`YYYY-MM-DD-article-slug` (e.g. `2019-02-20-some-article-description.md`).

Preview the appearance by running the local development server with:

    make server

which will serve the site at <http://localhost:4000>.

When the post is ready, submit a pull request and request review from the
[`#octoenergy/publicity`][publicity_team] team.

[publicity_team]: https://github.com/orgs/octoenergy/teams/publicity/

Once approved, publish by merging your pull-request to `master`.

## Maintenance

To upgrade Ruby dependencies, run:

    make upgrade
