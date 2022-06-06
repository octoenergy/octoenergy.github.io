---
title: Patterns of flakey Python tests
layout: post
category: news
author: David Winterbottom
banner: /assets/img/posts/2015-11-23-tech-jobs.jpg
hex: 0e1720
---

<!-- INTRO -->

<!-- What is a flakey test? -->

Flakey tests fail intermittently causing confusion, frustration for developers
and delays in your deployment pipeline.

Flakey tests affect all large codebases; the large Python codebases of Kraken
Technologies are no exception.

<!-- What this post is -->

This post details several patterns that cause flakey Python tests. Being aware
of these common causes can help when investigating your own flakey
tests.

Some advice on fixing flakey tests and general mitigation is also included.

---

Contents:

- [Patterns](#patterns)

  - [Anti-pattern 1: Tight coupling to current time](#anti-pattern-1-tight-coupling-to-current-time)
  - [Anti-pattern 2: Calling the system clock at compile time](#anti-pattern-2-calling-the-system-clock-at-compile-time)
  - [Anti-pattern 3: Implicit ordering](#anti-pattern-3-implicit-ordering)
  - [Anti-pattern 4: Randomly generated inputs and fixtures](#anti-pattern-4-randomly-generated-inputs-or-fixtures)
  - [Anti-pattern 5: Test pollution](#anti-pattern-5-test-pollution)

- [Fixing flakey tests](#fixing-flakey-tests)

- [Summary](#summary)

---

## Patterns

Here are the common causes of flakey tests we've encountered:

### Anti-pattern 1: Tight coupling to current time

Some flakey tests only fail when run at a particular point in time, or at a
particular time each day.

This can happen if the application code makes flawed assumptions about datetime
arithmetic (e.g. assuming the date doesn't change when a small delta is added to
the current time, or when the current datetime is in a daylight saving time
transition period).

In our experience, flawed assumptions about datetime arithmetic are the most
common cause of flakey tests.

#### Example: ambiguous datetime form values

Consider this Django form:

```py
from django import forms

class SomeForm(forms.Form):
    due_at = forms.DateTimeField(
        input_formats="%Y-%m-%d %H:%M"
    )
```

and related test:

```py
from somewhere import forms
from django.utils import timezone

def test_valid_payload():
    due_at = timezone.now()
    form = forms.SomeForm(data={
        "due_at": due_at.strftime("%Y-%m-%d %H:%M")
    })
    assert form.is_valid()
```

This test will pass for most of the year but fail in the UK Daylight Savings
Time transition period where local time moves forward against UTC in October.
For example, the value `2021-10-31 01:00:00` is ambiguous when the configured
timezone is `Europe/London`.

This isn't an application bug _per se_. It's reasonable for users to assume
datetime values are in their local timezone but not sensible to extend the form
widget to handle ambiguous datetimes that only occur for one hour per year in
the middle of the night.

<!-- How to fix -->

The appropriate fix for the test is not to use the system clock to generate the
input data but to explicitly specify a fixed datetime:

```py
from somewhere import forms
from django.utils import timezone
import time_machine

def test_valid_payload():
    # Use a fixed point in time.
    due_at = timezone.make_aware(datetime.datetime(2020, 3, 4, 14 30))
    form = forms.SomeForm(data={
        "due_at": due_at.strftime("%Y-%m-%d %H:%M")
    })
    assert form.is_valid()
```

There will be cases where the system clock call is in the application code
rather than the test. In such cases, tests should control system clock calls via
a library like [`time_machine`][time_machine].

[time_machine]: https://github.com/adamchainz/time-machine

```py
import time_machine

@time_machine.travel("2020-03-04T14:30Z")
def test_some_use_case():
    ...
```

### Anti-pattern 3: Implicit ordering

Flakiness can occur in tests making equality assertions on lists where the order
of the items isn't explicitly specified.

For example, a test may fetch a list of results from a database and assert that
the results match an expected list. But if the database query doesn't include an
explicit `ORDER BY` clause, it's possible the order of the results can vary
between test runs.

#### Example: Django `QuerySet`s

Consider this test which doesn't specify a sort order for the
`pizza.toppings.all()` `QuerySet`:

```py
# Factory functions
def _create_pizza(**kwargs):
   ...
def _create_topping(**kwargs):
   ...

def test_creates_toppings_correctly():
    # Create a pizza with some toppings.
    pizza = _create_pizza()
    for topping_name in ("ham", "pineapple"):
        _create_topping(
            pizza=pizza,
            topping_name=topping_name,
        )

    # Fetch all toppings associated with the pizza.
    toppings = pizza.toppings.all()

    assert toppings[0].topping_name == "ham"
    assert toppings[1].topping_name == "pineapple"
```

At some point, one of your colleagues will have their afternoon ruined when the
first assertion finds `toppings[0].topping_name` is `pineapple`.

<!-- How to fix? -->

Fix by chaining an explicit `order_by` call to the `QuerySet`:

```py
# Factory functions
def _create_pizza(**kwargs):
   ...
def _create_topping(**kwargs):
   ...

def test_creates_toppings_correctly():
    # Create a pizza with some toppings.
    pizza = _create_pizza()
    for topping_name in ("ham", "pineapple"):
        _create_topping(
            pizza=pizza,
            topping_name=topping_name,
        )

    # Fetch all toppings associated with the pizza. We now explicitly sort
    # the QuerySet to avoid future flakiness.
    toppings = pizza.toppings.all().order_by("topping_name")
    assert toppings[0].topping_name == "ham"
    assert toppings[1].topping_name == "pineapple"
```

<!-- When does this happen? -->

Flakiness of this form will happen randomly and can be difficult to recreate
locally.

### Anti-pattern 2: Calling the system clock at compile time

If the system clock is called at compile time, tests can fail when the test
suite is started just before midnight (in the timezone that your test suite
uses). In such circumstances, the current date can change during the test run,
exposing flawed assumptions about dates and datetimes, ultimately leading to
flakey tests.

If you observe test flakiness at a particular time each day, this might be the
cause; especially if the test fails due to something related to dates.

#### Example: factories

Watch out for this anti-pattern when declaring field values in test factories.
Here's an example using [FactoryBoy](https://factoryboy.readthedocs.io/en/stable/):

```py
import factory
from django.utils import timezone

class SomeFactory(factory.Factory):
    available_from = timezone.now()
```

Here the value of `SomeFactory.available_from` will be computed when the test is
_collected_ (i.e. import time); but tests that use this factory may not run
until several minutes later.

Prefer to use [`factory.LazyFunction`][lazy_function] to defer the system clock
call until runtime:

[lazy_function]: https://factoryboy.readthedocs.io/en/stable/reference.html#lazyfunction

```py
import factory
from django.utils import timezone

class SomeFactory(factory.Factory):
    available_from = factory.LazyFunction(timezone.now)
```

#### Example: default values for function arguments

Similarly, avoid making system clock calls to provide default argument values:

```py
from datetime import datetime
from django.utils import timezone

def get_active_things(active_at: datetime = timezone.now()):
    ...
```

In production code, the value of `active_at` here would correspond to the time
the module is imported, which will commonly be when the Python process starts
up. This is unlikely to be a relevant value for your application's logic, and could
lead to flakey tests.

Here we factor out the problem by either forcing clients to explicitly pass the
argument value:

```py
from datetime import datetime

def get_active_things(active_at: datetime):
    ...
```

or by using a sentinel value (like `None`) and adding a guard condition to
compute the value if it hasn't been passed in:

```py
from datetime import datetime
from typing import Optional
from django.utils import timezone

def get_active_things(active_at: Optional[datetime] = None):
    if active_at is None:
        active_at = timezone.now()
    ...
```

### Anti-pattern 4: Randomly generated inputs or fixtures

Tests that use randomly generated input or fixture data can fail intermittently
when the generated value exposes a bug in the test or application code.

Of course such ["fuzz testing"][fuzz_testing] can be useful for building robust
code. However intermittent failures of this form are only useful when they fail
for someone _working on the code in question_. When they fail in an unrelated
pull request or in your deploy pipeline workflow, they generally cause frustration.

[fuzz_testing]: https://en.wikipedia.org/wiki/Fuzzing

In such circumstances, the affected person or team is not motivated to fix the root
problem as they are likely not familiar with the domain. Instead the path of
least resistance is to rerun the test workflow in the hope that the failure
doesn't reappear.

This problem is more pertinent to large codebases, where different teams are
responsible for separate domain areas.

#### Example: randomised names

Consider this test for search functionality that uses [faker][faker] to randomly
generate fixture data:

[faker]: https://faker.readthedocs.io/en/master/

```py
import factory
from faker import Faker
from myapp import models
from testclients import graphql_client

# Define a factory for generating user objects with randomly 
# generated names.
class User(factory.DjangoModelFactory):
    first_name = Faker().first_name()
    last_name = Faker().last_name()

    class Meta:
        model = models.User


def test_graphql_query_finds_matching_users():
    # This is the search query we will use.
    query = "Kat"

    # Create two users who will match the search query...
    User(first_name="Kate", last_name="Smith")
    User(first_name="Barry", last_name="Katton")

    # ...and two users who won't.
    User(first_name="Catherine", last_name="Parr")
    User(first_name="Anne", last_name="Boleyn")

    # Make requests as an authenticated user (with randomly 
    # chosen name...).
    graphql_client.as_logged_in_user(User())

    # Perform GraphQL query to find matching users.
    query = """query Run($query: String!) {
        users(searchString: $query) {
            edges {
                node {
                    firstName
                    lastName
                }
            }
        }
    }"""
    response = graphql_api_client.post(query, variables={"query": q})

    # Check we get two results.
    assert len(response["data"]["supportUsers"]["edges"]) == 2
```

This is flakey as the randomly generated name for the requesting user can
inadvertently match the search query and give three matching results instead of
the expected two.

<!-- How to fix -->

The fix here is to remove the randomness by explicitly specifying the name of
the requesting user. So instead of:

```py
graphql_client.as_logged_in_user(User())
```

use:

```py
graphql_client.as_logged_in_user(
    User(first_name="Thomas", last_name="Cromwell")
)
```

As a general rule, you want the tests that run on pull requests and your deploy
pipeline to be _as deterministic as possible_. Hence it's best to avoid using 
randomly generated input or fixture data for these scenarios.

### Anti-pattern 5: Test pollution

Some flakey tests pass when run individually but fail intermittently when run as
part of a larger group. This can happen when tests are coupled in some way and
the group or execution order changes causing one test to "pollute" another,
leading to failure.

This is perhaps more prevalent when splitting up the test suite to run
concurrently (using say [`pytest-xdist`][xdist]) as new tests may alter the
way the test suite is divided.

Common sources of pollution include caches, environment variables, databases,
the file system and stateful Python objects. Anything that isn't explicitly
restored to its original state after each test is a possible source of
pollution.

Moreover, beware that changing the order that the test suite is run can expose
flakiness of this form. It advisable to keep the order of tests deterministic
(i.e. don't shuffle the order each time).

[xdist]: https://pypi.org/project/pytest-xdist/

#### Example: Django's cache

Caches often couple tests together and cause this pattern of flakiness. For
example, Django's cache [is not cleared after each test][django_cache] which can
lead to intermittent failure if tests assume they start with an empty cache.

[django_cache]: https://docs.djangoproject.com/en/latest/topics/testing/overview/#other-test-conditions

This can be worked around with an auto-applied Pytest fixture:

```py
from django.conf import settings
from django.core.cache import cache
import pytest

@pytest.fixture(autouse=True)
def clear_django_cache():
    # Run the test...
    yield

    # ...then clear the cache.
    cache.clear()
```

Similarly, be careful with `functools.lru_cache` as this will need explicitly
clearing between tests. A similar Pytest fixture can do this:

```py
import pytest

# We have to explicitly import any relevant functions that are wrapped with the
# LRU cache decorator.
from somemodule import cached_function

@pytest.fixture(autouse=True):
def clear_lru_cache():
    # Execute the test...
    yield

    # ...then clear the cache.
    cached_function.cache_clear()
```

Alternatively there's a [`pytest-antilru`][lru] Pytest plugin that aims to do the same thing.

[lru]: https://pypi.org/project/pytest-antilru/


## Fixing flakey tests

The above anti-patterns provide heuristics for your investigations. When
examining a flakey test, ask yourself these questions:

#### Has the test started failing consistently since some point in time?

If so, look for a hard-coded date or datetime in the test or application code.

#### Could the failure be explained by bad assumptions around date arithmetic? 

This might manifest itself in failure messages that refer to dates or
objects associated with dates.

Does the test consistently fail at the same time each day? If so, examine
closely the time when the failing test ran and any date logic in the code being
executed. 

#### Can you recreate the failure locally?

Try using `time_machine` to pin the system clock to the exact time when the
flakey failure occurred. If this recreates it, rejoice! You can verify that
your fix works, which isn't always possible when working on flakey tests.

#### Could the failure be explained by randomly generated inputs or fixtures? 

Examine the test set-up phase for anything non-deterministic and see if that can
explain the failure.

#### Could the failure be explained by the order of things changing?

This can be harder to spot but look carefully at the error message to see if
it's related to the order of some iterable.

#### Does the test or application code share a resource with other tests?

Check if the application code uses a cache (especially `functools.lru_cache`),
stateful object or temporarily file and ensure these resources are explicitly
restored or removed after each test.

## Summary

Knowing the common causes of flakey tests is a huge advantage in mitigating and
fixing them.

But they can still be elusive. 

We recommend having a policy of immediately skipping flakey tests when they
occur and starting an investigation so they can be rapidly fixed and restored to
the test suite. This will avoid blocking your deploy pipeline, causing delays
and frustration. 

This can be done using Pytest's [`pytest.mark.skip`][skip] decorator:

[skip]: https://docs.pytest.org/en/7.1.x/how-to/skipping.html#skipping-test-functions

```py
import pytest

@pytest.mark.skip(
    "Test skipped due to flakey failures in primary branch - see "
    "https://some-ci-vendor/jobs/123 "
    "https://some-ci-vendor/jobs/456"
)
def test_something():
    ...
```

Include links to failing test runs to help recreate and fix the flakey test.

Finally, a theme underlying many flakey tests is a reliance on a
non-deterministic factor like system clock calls or randomly generated data.
Consequently, to minimise test flakiness, strive to make tests as deterministic
as possible. 

---

<small>
Thanks to David Seddon and Frederike Jaeger for improving early versions of this
post.</small>
