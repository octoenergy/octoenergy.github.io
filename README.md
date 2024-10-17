# Engineering Blog redirects

This repo previously provided a [Jekyll][jekyll] site for the Kraken Engineering Blog, when it was hosted at <https://tech.octopus.energy>. Having since moved to <https://engineering.kraken.tech> with a new repo to boot, this repo now serves only to redirect traffic to the equivalent page on the new site. The site - like the maintained blog - is published using [Github Pages][github_pages].

[jekyll]: https://jekyllrb.com/
[github_pages]:
  https://docs.github.com/en/free-pro-team@latest/github/working-with-github-pages/setting-up-a-github-pages-site-with-jekyll


> [!WARNING]
> Do not contribute new posts to this repo, they will not be published. Contribute to the new repo at <https://github.com/octoenergy/kraken-tech-blog>, which is published at <https://engineering.kraken.tech>. Posts only exist here to ensure legacy URLs are redirected to the new site.

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

## Working on site appearance

The `css/main.scss` SASS file is compiled by Jekyll and served as `css/main.css`
in the static site.

You can work on site appearance by editing the SASS files in `_sass/` and using
the live reload to preview changes.
