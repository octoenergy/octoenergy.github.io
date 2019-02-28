# Octopus Energy tech blog

This repo provides a simple Jekyll site for the https://tech.octopus.energy site.

## Installation

You'll need a modern Ruby (>2.0) and bundler (`gem install bundler`) installed. For macOS, it's generally
easiest to use [rvm](https://rvm.io/).

We use Pygments for syntax highlighting. This seems to need Python 2.7 as the default Python. If you're using pyenv, then
run:

    $ pyenv install 2.7.8
    $ pyenv local 2.7.8

to set the local Python version to 2.7.8 (or 2.7.x).

Once those are in place, simply check out the repo and run:

    $ bundle install

to install all Ruby dependencies. 

If you have problems installing charlock_holmes, refer to [this Github issues
page](https://github.com/brianmario/charlock_holmes/issues/117) for work-arounds.

## Local development

Run the local development server with:

    $ bundle exec jekyll server

or just:

    $ make run

Create new posts by creating a markdown file in `_posts/` with filename format
like `2019-02-20-some-article-description.md`.


