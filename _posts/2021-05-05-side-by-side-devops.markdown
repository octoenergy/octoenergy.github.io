---
title: Design infrastructure for side-by-side upgrades
layout: post
category: news
author: David Winterbottom, Federico Marani
banner: /assets/img/posts/2015-11-23-tech-jobs.jpg
hex: 0e1720
---

<!-- explain how this approach makes sense for application deployments -->

A common deployment pattern for a HTTP service is to run the old and new
versions side-by-side and use a load balancer to migrate traffic from one to the
other.

We design our applications to make this easy by:

- Using immutable infrastructure where servers/containers are replaced rather than updated.

- Ensuring application servers/containers are stateless; we ship logs to an
  aggregation service and uses database and remote storage for data and files.

<!-- explain how this approach ALSO makes sense for infrastructure deployments -->

Something we've learnt at Octopus over the years is that the same principles
apply for infrastructure. It's beneficial to design infrastructure for
side-by-side deployments where two versions run simultaneously for some period.

Here's a few examples:

<!-- DNS example -->

## Internal service DNS records


> Versioned domain names is one way of doing this — having a canonical domain name like cache.octoenergy.internal implies there will only ever be one of these running at a time which isn't true.


<!-- Terraform module example -->

## Terraform modules

> Another place where this applies in Terraform module size. It was definitely a mistake to create large Terraform modules (like the database and cache modules) that manage several things in the same category/AWS-domain. That makes it harder to do side-by-side upgrades of just one resource as you can't just install the same module twice in the same workspace. In retrospect, we should have used more fine-grained modules (e.g. one for each cache cluster) so it would be easy to install the same module twice when upgrading. This is really just the Single-Responsibility-Problem applied to Terraform


<!-- Summary -->
