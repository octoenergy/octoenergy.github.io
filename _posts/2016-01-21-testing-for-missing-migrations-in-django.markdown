---
title: Testing for missing migrations in Django
layout: post
category: news
author: David Winterbottom
banner: /assets/img/posts/2016-01-21-testing-for-missing-migrations-in-django.jpg
hex: 3d354a
---

Since version 1.7, Django creates migrations for more than just changes to
your model fields. It's easy to forget to create a migration after changing,
say, the `verbose_name_plural` of a model class - I've done this many times.
This can lead to a mess down the line when multiple developers all end up
creating the same migration in separate branches.

You can avoid this situation by checking for missing migrations in your test
suite:

{% highlight python %}
from StringIO import StringIO
from django.core.management import call_command
import pytest

def test_for_missing_migrations():
    output = StringIO()
    try:
        call_command(
            'makemigrations', interactive=False, dry_run=True, exit_code=True,
            stdout=output)
    except SystemExit as e:
        # The exit code will be 1 when there are no missing migrations
        assert unicode(e) == '1'
    else:
        pytest.fail("There are missing migrations:\n %s" % output.getvalue())
{% endhighlight %}

Here we call the `makemigrations` command in "dry-run" mode and test the
exit code to determine if there are any missing migrations. If there are missing
migrations, the test will fail and print the captured output from the
`makemigrations` command.

Note that if you are using a custom `MIGRATION_MODULES` setting to [avoid
applying migrations during
tests](https://docs.djangoproject.com/en/1.9/ref/settings/#migration-modules), you need to restore its default value for
the above command to work:

{% highlight python %}
from StringIO import StringIO
from django.core.management import call_command
from django.test import override_settings
import pytest

@override_settings(MIGRATION_MODULES={})
def test_for_missing_migrations():
    output = StringIO()
    try:
        call_command(
            'makemigrations', interactive=False, dry_run=True, exit_code=True,
            stdout=output)
    except SystemExit as e:
        # The exit code will be 1 when there are no missing migrations
        assert unicode(e) == '1'
    else:
        pytest.fail("There are missing migrations:\n %s" % output.getvalue())
{% endhighlight %}

Credit for this implementation belongs to Mozilla's Ed Morley, who [committed a
similar fix](https://github.com/mozilla/treeherder/commit/dd539147716125bb4d2798cdaf613e294c363fb2)
for their [treeherder](https://github.com/mozilla/treeherder/) project. The above snippets are
slightly extended versions of his original.

Related reading:

- Here's [another approach](http://tech.yunojuno.com/keeping-on-top-of-django-migrations) by YunoJuno that achieves the same effect.
