---
title: Moving to black and isort
layout: post
category: news
author: David Winterbottom
banner: /assets/img/posts/2015-11-23-tech-jobs.jpg
hex: 0e1720
---

We recently converted a large repository to require all code to be formatted
with Black and isort. If you're considering doing the same thing, here are some
notes:

The below instructions are for a repository that deploys from the `master`
branch and has a policy of rebasing pull-request branches.

## Avoiding conflicts

If you have many in-flight pull-requests, use this three-stage process to
minimise conflicts:

1. Freeze your `master` branch, as in don't allow any more merges until after
   the black/isort switch, and have everyone
   rebase their pull-request branches off `master`. Make a note of the HEAD
   commit SHA on `master`.

2. Create and merge a pull-request that reformats the repository using black and
   isort, and adds checks to your CI pipeline to enforce these formatting
   conventions (see below for how to do this). 

3. Once `master` has been converted, each developer should rebase their branches
   off master _again_. Since the only new changes in `master` are from
   re-formatting, this means any merge conflicts can be resolved easily by
   accepting the changes from the pull-request branch and re-applying black and
   isort. 
   
   When fixing a conflict during an interactive rebase, use this form of command
   to accept your changes:

   ```bash
   $ git checkout --theirs $filepath
   ```

   Further, here's a script that you can run:

   ```bash
   #!/usr/bin/env bash

   echo
   echo Fixing conflicts
   echo

   # Resolve any conflicts using the PR branch's changes
   git status -s | grep "^UU" | cut -d" " -f2 | while read filepath; 
   do 
       echo "Resolving conflict in $filepath"
       git checkout --theirs $filepath 2> /dev/null 
       git add "$filepath"; 
   done

   # Delete any files deleted in the PR branch's changes
   git status -s | grep "^UD" | cut -d" " -f2 | while read filepath; 
   do 
       echo "Removing $filepath"
       rm "$filepath"
       git add "$filepath"
   done

   # Re-run black and isort on changed python files
   git status -s | awk '/^M.*\.py/ {print $2}' | while read filepath; 
   do
       echo "Reformatting $filepath"
       black "$filepath" 2> /dev/null
       isort "$filepath" 2> /dev/null
       git add "$filepath"
   done

   # Continue the rebase
   git rebase --continue
```


