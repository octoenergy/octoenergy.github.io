---
title: Using formatters and linters to manage a large codebase
layout: post
category: news
author: Frederike Jaeger
banner: /assets/img/posts/2015-11-23-tech-jobs.jpg
hex: 0e1720
---

At Kraken Tech we have a large global development team with over 500 developers, 
the majority of which work on the same monolithic codebase comprising 3 million 
lines of Python code. We release new code over 100 times a day, running hundreds 
of thousands of tests in the process.

So how can we ensure high coding quality in a distributed team, with such 
frequent changes? And how can we make it easier for new joiners to slot right 
in and contribute?

## Formatting

Not long after I joined the company, my first professional job as a programmer, 
we introduced [Black](https://Black.readthedocs.io/en/stable/). There was one 
giant refactor pull request to format the codebase with Black, admittedly 
something that would be much harder to do now that the codebase has grown to 
many times its original size. At the same time, we also introduced 
[isort](https://pycqa.github.io/isort/) (which has now been superseded 
by [Ruff](https://docs.astral.sh/ruff/) in our setup). For me as a brand new 
dev, this was much needed and very helpful.

Before this change, I never really knew what the preferred structure was. 
In code reviews, you might get competing advice regarding “best practice” 
and general feedback on style. Having consistent formatting greatly reduces 
the mental load and decision-making needed when writing new code. Instead, 
you can just concentrate on the task at hand.

Not only that, it’s also much easier to find what you’re looking for. Ordered 
imports mean that you can immediately identify module imports and hence dependencies. 
Having consistent formatting also means it’s much easier to spot function arguments, 
doc strings, and the like.

We run Black and Ruff as part of our CI checks. This means that new code is 
not merged unless it conforms with our formatting standards. As you can 
configure your editor of choice to run formatting against changed files on 
save, this is not an additional hassle for developers. Everyone wins. 

## Linting

Another great tool at our disposal is linting. We use a variety of linters to 
reduce bugs and ensure developers conform to our [conventions](https://github.com/octoenergy/conventions); 
we have many of them and we can hardly expect everyone to know them off by heart!

As the codebase is so large, we run some of our linters on changed files only. 
This allows us to introduce new rules and achieve gradual improvement, rather 
than putting the burden of fixing existing code on a single developer and 
causing a mass of merge conflicts. An alternative is to add ignores to the 
code base in one go and then rely on developers to fix things as they see 
it ([silence-lint-error](https://pypi.org/project/silence-lint-error/) is a 
great package for that). Which approach is best depends on the situation.

### Type checking

For type checking we use [mypy](https://mypy.readthedocs.io/en/stable/). 
Type checking helps in finding bugs before they happen in production and 
hence prevent annoying errors at best, and costly outages at worst. We’ve 
had mypy enabled for many years. However, since Python isn’t traditionally a 
typed language, we had very few type hints in place in our early years and 
hence didn’t gain much value from running mypy.

This only changed when we introduced a custom linter, which forced all 
developers to add at the very least a return type to any function they 
touched. This is as mypy [doesn’t actually type check a function](https://mypy.readthedocs.io/en/stable/common_issues.html#no-errors-reported-for-obviously-wrong-code) 
unless there is at least one type annotation in the function signature; 
using the return type seemed like a good choice as a start. This has now 
been extended to enforce typing on all function arguments for changed functions.

Since that change, we’re actually seeing the benefits. It’s not only 
helpful in preventing bugs but also in simply understanding what the function 
does. Type hints are part of the documentation. We’ve also seen particular 
value when transitioning between legacy and new sytems, as proper typing can 
make it clear which system is supported.

Of course, sometimes wrangling mypy can be a bit of a challenge, and there 
are particularly curious issues due to bugs in django-stubs, but the benefits 
by far outweigh the cons.

We track our missing type annotations and `#type: ignore`s with a dashboard to 
hold ourselves accountable; only that way do we know we’re making progress and 
that our approach is working.

### Making things better, one commit at a time

We also use custom linters within [Fixit](https://fixit.readthedocs.io/en/stable/) 
to enforce some of our other conventions. This could be around readability of 
code, documentation, or good practice around security. Examples are
* ensuring our test module paths mirror that of the module they are testing 
* ensuring we're correctly asserting mocks in tests
* prohibiting the use of deprecated functions
* enforcing naming conventions for certain Django field types

and many more. Whenever we spot a potential issue that can be prevented with a 
simple linter, we just add one. 

As with mypy, we typically only check changed files. This means that each 
developer contributes a little bit to reducing technical debt with every 
pull request that touches non-conforming code. With our 
[pull request conventions](https://tech.octopus.energy/news/2023/06/21/pull-request-conventions.html), 
this usually just means a small clean up commit on a module before introducing a functional change.

We have found this approach really works for us. We don’t overload our devs 
with what some may call boring clean up work. We also have a nice automatic 
way of ensuring the conventions we really care about are adhered to. As the 
linters live in the code, you can always go back to the original pull request 
introducing them to find a helpful discussion on why we introduced it or 
perhaps a link to a ticket or slack post. 


### Application layer linting

One of our developers, David Seddon, developed 
[Import Linter](https://github.com/seddonym/import-linter) which we use for 
ensuring our application conforms to prescribed layering, i.e. module imports 
are only allowed in a certain direction. This is an incredibly helpful tool 
for a large codebase like ours, as it prevents circular imports creeping in 
and ensures a clear separation of responsibilities. For more on this, you can 
read his [blog post](https://blog.europython.eu/kraken-technologies-how-we-organize-our-very-large-pythonmonolith/). 

## Conclusion

I hope you enjoyed this brief overview of some of the tools we use to manage 
to keep our code quality high. These tools are essential for a large team 
working on a single code base as we do at Kraken. We're constantly evolving 
our tools to improve code quality as we grow. If you're interested in helping 
us build better systems, check out our [careers page](https://octopus.energy/careers/).