---
title: Duration database transactions in Django
layout: post
category: news
author: David Winterbottom
banner: /assets/img/posts/2015-11-23-tech-jobs.jpg
hex: 0e1720
---

[David Seddon](https://twitter.com/seddonym), a senior developer in our team,
recently published an interested blog post on ["The trouble with
`transaction.atomic`"](https://seddonym.me/2020/11/19/trouble-atomic/) drawing
on internal discussions within our tech team.

This was picked up by the core Django team and a new `durable` flag has already
been added to the `django.db.transaction.atomic` function — see the [development
branch docs](https://docs.djangoproject.com/en/dev/topics/db/transactions/#django.db.transaction.atomic).

We can look forward to this feature in Django 3.2.
