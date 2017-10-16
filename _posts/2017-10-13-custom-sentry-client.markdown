---
title: Using a custom Sentry client
layout: post
category: news
author: David Winterbottom
banner: /assets/img/posts/2015-11-23-tech-jobs.jpg
hex: 0e1720
---

We use
[Sentry](https://sentry.io/welcome/) to monitor errors within our Django applications. It's an
excellent tool: you should use it. 

Regrettable however, we sometimes need to SSH into a server within our platform
and use Django's shell to explore or adjust data. However, by default,
exceptions from these sessions are captured up Sentry and appear in the
dashboard. 

This isn't helpful as such errors are not application problems _per se_ and
just add noise.  We want Sentry to ignore these exceptions.

To prevent these errors being captured, the solution is to use a custom Sentry
client class with an overridden `should_capture` method that ignores errors
triggered from a shell session.

Here's an example:

{% highlight python %}
import sys

from raven.contrib.django import DjangoClient


class CustomSentryClient(DjangoClient):

    def should_capture(self, exc_info):
        # Check if this exception was triggered from a shell session. We don't care about these
        # as they are normally human typos and of no further interest.
        if len(sys.argv) >= 2:
            if sys.argv[1] in ("shell", "shell_plus", "dbshell"):
                return False

        return super().should_capture(exc_info)

{% endhighlight %}

Plumb this in by adding a `SENTRY_CLIENT` setting specifying the module path to
this class:

{% highlight python %}
# settings.py

SENTRY_CLIENT = 'path.to.module.CustomSentryClient'

{% endhighlight %}

Problem solved.



