# Kraken Technologies blog

This repo provides a [Jekyll][jekyll] site for the <https://tech.octopus.energy>
site. The site is published using [Github Pages][github_pages].

[jekyll]: https://jekyllrb.com/
[github_pages]:
  https://docs.github.com/en/free-pro-team@latest/github/working-with-github-pages/setting-up-a-github-pages-site-with-jekyll

## Installation

### System prerequisites

You should have Ruby 3.2.3 installed and available on the command line:

```sh
> ruby --version
ruby 3.2.3 (2024-01-18 revision 52bb2ac0a6) [arm64-darwin23]
```

#### If you don't have the correct version of Ruby

There are a few different ways to manage Ruby versions on your computer locally.
If you're not sure what to do, try the following:

1. Install [`asdf`](https://asdf-vm.com/):
  - `brew install asdf`
  - Add the correct line to your `.bashrc` / `.zshrc` etc, as per [these instructions](https://asdf-vm.com/guide/getting-started.html#_3-install-asdf). 
  - Open a new terminal and navigate to this folder.
2. `asdf plugin add ruby`
3. `asdf install ruby 3.2.3`
4. `asdf local ruby 3.2.3`

Now check you're on Ruby 3.2.3:

```sh
> ruby --version
ruby 3.2.3 (2024-01-18 revision 52bb2ac0a6) [arm64-darwin23]
```

### Installing the dependencies

```sh
> bundle config set --local path .bundle
> bundle install
```

(This will install the Ruby libraries listed in `Gemfile.lock`.)

### Verify the server starts

```sh
> make server
```

## Adding new blog posts

Add new posts by creating a markdown file in `_posts/` with filename format
`YYYY-MM-DD-article-slug.md` (e.g. `2019-02-20-some-article-description.md`). You should also add a header containing 
the title and author of the article, amongst other items. For a blog post to appear, the `category` must be set to `news`. Check existing posts for examples.


Ensure your details are in the `_data/members.yml` file.

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
