---
title: Beware changing the "related name" of a Django model field
layout: post
category: news
author: David Winterbottom
banner: /assets/img/posts/2015-11-23-tech-jobs.jpg
hex: 0e1720
---

We had an outage on Friday 15th March caused by an innocent-looking change, 
where the "related name" of a Django model field was renamed.

We had wrongly assumed this didn't require any schema changes to our Postgres 9.5
database, but it did: it dropped and recreated the foreign-key constraints on
the table. 

You can reproduce this behaviour by running `sqlmigrate` on a migration created after renaming a
`related_name` attribute:
```bash
$ ./manage.py sqlmigrate $APP_LABEL $MIGRATION_NUMBER
```
which yields something like:
```
BEGIN;
--
-- Alter field foo on bar
--
SET CONSTRAINTS "bar_foo_id_xxx_fk" IMMEDIATE; 
ALTER TABLE "bar" DROP CONSTRAINT "bar_foo_id_xxx_fk";
ALTER TABLE "bar" ADD CONSTRAINT "bar_foo_id_xxx_fk" 
FOREIGN KEY ("foo_id") REFERENCES "foo" ("id") 
DEFERRABLE INITIALLY DEFERRED;
COMMIT;
```

Adding a foreign-key constraint requires an `ACCESS EXCLUSIVE` lock on the table,
blocking `SELECT` queries. For large tables, adding the constraint may take a
while, which can lead to major operational problems as queries queue up. This is
what happened to us.

FYI, this behaviour in Django is inadvertent: there is an open bug in Django 2.1.x and below: [#25253](https://code.djangoproject.com/ticket/25253), 

There isn't an good workaround for this problem. The best approach we know of is to
update an already-applied migration file to reflect the new related name. Since
such a migration is already applied, no SQL will be run against your schema when
this change deploys and Django won't pick up any changes when `makemigrations`
is run.

During our next internal blitzday (where we work on our tooling, dependencies
and general codebase health), we'll see if we can submit a patch to Django to fix this, to
avoid anyone else getting caught out like we did.
