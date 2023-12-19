# Kraken Technologies blog

This repo provides a [Jekyll][jekyll] site for the <https://tech.octopus.energy>
site. The site is published using [Github Pages][github_pages].

[jekyll]: https://jekyllrb.com/
[github_pages]:
  https://docs.github.com/en/free-pro-team@latest/github/working-with-github-pages/setting-up-a-github-pages-site-with-jekyll

## Installation

Ensure you have [`asdf`](https://asdf-vm.com/) installed then install Ruby
2.7.8:

```sh
> asdf plugin add ruby
> asdf install ruby 2.7.8
> ruby --version  # verify
ruby 2.7.8p225 (2023-03-30 revision 1f4d455848) [arm64-darwin23]
```

Install the `github-pages` gem:

```sh
> bundle install
```

## Adding new blog posts

Add new posts by creating a markdown file in `_posts/` with filename format
`YYYY-MM-DD-article-slug.md` (e.g. `2019-02-20-some-article-description.md`).

Preview the appearance by running the local development server with:

    make server

which will serve the site at <http://localhost:4000>.

When the post is ready, submit a pull request and request review from the
[`@octoenergy/publicity`][publicity_team] team.

[publicity_team]: https://github.com/orgs/octoenergy/teams/publicity/

Once approved, publish by merging your pull-request to `master`.

## Working on site appearance

The `css/main.scss` SASS file is compiled by Jekyll and served as `css/main.css`
in the static site.

You can work on site appearance by editing the SASS files in `_sass/` and using
the live reload to preview changes.
