---
title: Automating Secrets Management with 1Password Connect
layout: post
category: news
author: Maja Cernja
hex: 0e1720
---

Here at Kraken Tech the data platform team is in charge of building out comprehensive analytics platforms for all our clients. This includes setting up ingestion pipelines, orchestration of tasks, dashboarding solutions, custom dbt packages and more. With company growth, it became clear that we needed to do something about the most dreaded task on the team: updating the Kubernetes secrets. Enter 1Password (OP) Connect. 

## Why 1Password Connect

Kubernetes secrets are needed for all our services to run smoothly and safely for each client. And at our scale it became necessary to automate the creation and updating of secrets. We explored other solutions but eventually settled on OP Connect for  a few reasons:

* 1Password was already our default credential manager and the OP Connect Server meant we could rely on 1Password to be the **single source of truth** for credential values 
* We could be confident that whatever is saved in 1Password will be reflected in Kubernetes, i.e. the **updates to credentials in 1Password would be automatically refreshed downstream**
* Significant **reduction in manual steps and thus human error** during credential generation and secret updates

There are of course more parts to the full credential and secret management automation and we will touch on some, but the focus of this post will primarily be on our experience and learnings with the OP Connect implementation.

## Glossary 

In case you are brand new to OP Connect, here are a few key concepts to keep in mind. For a deeper dive, you can explore the official 1Password docs [here](https://developer.1password.com/docs/connect/concepts). 

**1Password Connect Server** – effectively the bridge between vaults in the OP Cloud and your deployment environment. It can sync over the OP credentials into custom `onepassworditem` objects in Kubernetes.

**1Password Kubernetes Operator** – responsible for syncing the `onepassworditem` objects created by the server into Kubernetees secrets. 

**Credentials JSON** – the 1password-credentials.json file generated upon Connect server creation with the OP CLI, a unique blueprint for how to deploy the created Connect server. 

**Connect Token** – enables the Kubernetes Operator to securely authenticate with the server and access the `onepassworditem` objects. 

<img src="/assets/img/posts/2024-08-28-onepassword-connect.png" alt="Diagram of 1Password Connect deployment in a Kubernetes Cluster"/>

## Prerequisites

The Connect servers and Connect tokens need to be granted access to the  relevant vaults, where the credentials you wish to sync into secrets are stored. Hence, for smooth OP Connect implementation, it was crucial to implement **consistent naming conventions for OP Vaults**. 

Another important step was choosing **where to store the Connect token and credentials JSON** needed for each Connect deployment. We spent a good amount of time discussing with our security team how to handle these extra sensitive credentials that unlock access to other secrets. 

Since we chose deployment via Terraform for easier state tracking, we decided to go with AWS Secrets Manager for easiest access that does not involve actually storing the values in Terraform, and with the aim for these two to be the only credentials we’d need to save outside 1Password.

## Key Learnings

**Creating a Connect Server != Deploying Connect Server**
<br>
Creating the Connect server with the OP CLI does not deploy the server, it simply  creates the configuration for the 1Password connect server and the JSON file which contains the blueprint to deploy that Connect server configuration. 

**Credentials JSON needs to be double base64 encoded**
<br>
A little [quirk](https://1password.community/discussion/131378/loadlocalauthv2-failed-to-credentialsdatafrombase64) to be aware of, we ran into this one during debugging one of the first attempts to deploy a Connect server.

**Name your servers well**
<br>
Another issue we ran into during initial deployments was due to a slight mismatch in naming conventions between variables in Terraform and their counterparts in the CLI tools used for the OP-side server creation. Never underrate the importance of naming things consistently. 

**Helm deployment**
<br>
A couple of Connect deployment [settings](https://github.com/1Password/connect-helm-charts/blob/main/charts/connect/values.yaml) worth calling out:
* `pollingInterval` – specifies how frequently the Kubernetes Operator checks in on 1password items, i.e. this is the maximum delay between creating or updating an item and seeing the change be reflected within corresponding secrets, it defaults to 600 seconds (10 minutes).
<br>

* `autoRestart` – determines whether or not to perform a rolling restart on deployments in the relevant namespace when a secret is updated, so that the updated secret is in use as soon as possible, it defaults to false.

**Common Pitfalls**
<br>
Two errors we’ve encountered frequently after the initial setup:

* `401 Auth Error` or `exit code 6` – this usually happens during server creation when the person trying to create the Connect server does not have **full access to the vaults** that the server and Connect token are being granted access to.
<br>

* `Reconciller error` – This one crops up in the Kubernetes logs and indicates that secret syncing isn’t working. One cause we’ve come across was an invalid OP connect token. Another was deleting and recreating the Connect Server with the OP CLI. To resolve this, we performed a **rolling restart on all of the OP Connect Kubernetes deployments** so that the new credentials JSON is picked up and the Kubernetes operator is connecting to the newly created server.

## Conclusion

1Password Connect has become an integral part of a more automated credential and secrets management workflow across the many deployment environments we support, reducing the need for manual involvement and the room for human error. If you decide 1Password Connect is the right tool for you, we hope the learnings shared in the post make the setup process a little smoother. 







