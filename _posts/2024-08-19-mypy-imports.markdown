---
title: Understanding how mypy follows imports
layout: post
category: news
author: David Seddon
hex: 0e1720
---

At Kraken we run the static type checker [mypy](https://mypy.readthedocs.io/) on our very large (~6 million lines of code) Python codebase.
It's the slowest thing in our CI pipeline, and that got me wondering which modules mypy actually ends up analysing when
you ask it to check a particular Python module. This article talks you through what happens, and in particular explains
the [`follow-imports`](https://mypy.readthedocs.io/en/stable/command_line.html#cmdoption-mypy-follow-imports) flag. I'll also look briefly at how type stubs (`.pyi` files) are used. 

We'll learn about mypy's behaviour by following a worked example, so you'll get the most out of this article
by following along on your own computer.

## Assumptions

- You have a decent understanding of Python, including type annotations.
- You can set up Python virtual environments and install packages using pip (or equivalent). 
- You understand what a static type checker is.

## Setting up the project 

Let's begin by setting up a Python project on which we can run mypy.
You can do this however you like, but here's how I did it:

1. Create a folder called `mypy-learning` (`mkdir mypy-learning && cd mypy-learning`).
2. Create a virtual environment, preferably using Python 3.12. (`python -m venv .venv && source .venv/bin/activate`)
2. Install mypy 1.11.1. (`pip install mypy==1.11.1`).

You should now be able to run mypy from the command line:

```
$ mypy --version
mypy 1.11.1 (compiled: yes)
```

## Running mypy on a file with errors

Next, create a module called `red.py` containing the following code:

```python
def get_string() -> str:
    return 1
```

Did you notice the typing error? Let's see if mypy does:

```
$ mypy -m red
red.py:2: error: Incompatible return value type (got "int",
expected "str")  [return-value]
Found 1 error in 1 file (checked 1 source file)
```

Excellent &mdash; our type checker is doing its job. No surprises here yet.

## Running mypy on a downstream file

Create a module called `green.py` containing the following:

```python
import red
```

In a moment, we'll run mypy on `green.py`. Before we run it, think for a moment.
Will it report the error in `red.py`?

Let's find out:

```
$ mypy -m green
red.py:2: error: Incompatible return value type (got "int",
expected "str")  [return-value]
Found 1 error in 1 file (checked 1 source file)
```

It turns out it does! This is interesting &mdash; mypy will type check a module that it's not explicitly being asked to check,
just because it's imported by another module.

This doesn't just happen with direct imports. Let's add another link in the chain, this time with a module called `blue.py`:

```python
import green
```

Now we have a chain of imports, blue to green to red. Let's check blue.

```
$ mypy -m blue
red.py:2: error: Incompatible return value type (got "int",
expected "str")  [return-value]
Found 1 error in 1 file (checked 1 source file)
```

It still checks red! Mypy, according to its documentation, 'doggedly follows imports' &mdash;
so that's what's going on here, even though none of the typing in blue relies on the code in red. 

## Third party packages and the standard library

But how far does this doggedness go? If our code base is using many third party packages, does it really type check all
those packages too? And what about the Python standard library?

Let's fake the installation of a third party package by navigating to our virtual environment's `site-packages` folder
and creating a package in there named `thirdparty`:

```
$ mkdir .venv/lib/python3.12/site-packages/thirdparty
$ touch .venv/lib/python3.12/site-packages/thirdparty/__init__.py
```

Then, in the file we just created, add that same code with the typing mistake:

```python
def get_string() -> str:
    return 1
```

Next, replace the entire contents of `blue.py` with this code:

```python
import thirdparty

some_string = thirdparty.get_string()
```

Let's see what happens when we type check `blue.py`:

```
$ mypy -m blue
blue.py:1: error: Skipping analyzing "thirdparty": module
is installed, but missing library stubs or py.typed marker
[import-untyped]
blue.py:1: note:
See https://mypy.readthedocs.io/en/stable/running_mypy.html#missing-imports
Found 1 error in 1 file (checked 1 source file)
```

Because mypy thinks of this module as a third party package (i.e. installed in your virtualenv's `site-packages`
rather than alongside `blue.py`), we have a new error. This is because mypy won't use the package unless it is
explicitly declared as fit for that purpose. The simplest way to do this is to add an empty file called
`py.typed`, which tells mypy to look at the annotations in that package:

```
$ touch .venv/lib/python3.12/site-packages/thirdparty/py.typed
```

With that in place, let's type check `blue` again:

```
$ mypy -m blue
Success: no issues found in 1 source file
```

So this is interesting. There is an error in the third party library, but mypy is not complaining about it. So if it's
not type checking our third party package, why did it ask us to add that `py.typed` file in the first place?

Let's experiment by adding a slightly different kind of error. In `blue.py`, add a type annotation so that `some_string` is now an `int`:

```python
...
some_string: int = thirdparty.get_string()
```

And run mypy:

```
$ mypy -m blue
blue.py:3: error: Incompatible types in assignment (expression
has type "str", variable has type "int")  [assignment]
Found 1 error in 1 file (checked 1 source file)
```

So, while mypy doesn't check the _internals_ of the third party package, it does check that our local package is
interacting with it correctly. This makes sense: we want mypy to report on bugs in our code, not in third party packages.

The situation with modules in the standard library is the same &mdash; mypy will check that the code is interacting correctly
with types in the standard library, but it won't type check their internals as part of your mypy run. 

So it turns out that the dogged following of imports extends to the *APIs* of third party and standard library packages,
but no deeper.

## The `follow-imports` flag

The behaviour we've seen so far is actually only one of four modes that mypy supports with respect to imports.
These modes, exposed via the `follow-imports` flag, are:

- `normal` (the default)
- `silent`
- `skip`
- `error`

These can be thought of as on a spectrum of how 'dogged' mypy will be about following the imports.

Before we run `mypy` in these different modes, edit `blue.py` so it looks like this:

```python
import copy
import thirdparty
import green

copy.copy()
some_string: int = thirdparty.get_string()
```

### `normal` mode

Now let's run it in the default mode, which is `normal`:

```
$ mypy -m blue
red.py:2: error: Incompatible return value type (got "int",
expected "str")  [return-value]
blue.py:5: error: Missing positional argument "x" in call to
"copy"  [call-arg]
blue.py:6: error: Incompatible types in assignment (expression
has type "str", variable has type "int")  [assignment]
Found 3 errors in 2 files (checked 1 source file)
```

So, we have three different errors here:

1. An error internal to an upstream local module `red.py` (its `get_string` function is annotated to return a string,
   but actually returns an integer).
2. An error calling a standard library module (`copy` expects an argument).
3. An error calling a third party module (we've annotated a value as an `int`, but the third party library says its
   a `str`).

Although we haven't passed an argument, we're seeing mypy run in `normal` mode: the most 'dogged' mode.
As we've already seen, even in this mode we won't see any errors relating to the internals of third party or standard library packages.

### `error` mode

Let's run it in the mode at the opposite end of the spectrum: `error`:

```
$ mypy -m blue --follow-imports=error
blue.py:2: error: Import of "thirdparty" ignored  [misc]
blue.py:2: note: (Using --follow-imports=error, module
not passed on command line)
blue.py:3: error: Import of "green" ignored  [misc]
blue.py:5: error: Missing positional argument "x" in
call to "copy"  [call-arg]
Found 3 errors in 1 file (checked 1 source file)
```

We still have three errors, but this time two of them are simply triggered by the imports themselves.
Notice that mypy is treating the standard library package (`copy`) differently to the third party package &mdash; it's checking
we're interacting correctly with it even though we're passing `error`.

This mode is designed to force callers to explicitly specify all packages for checking, rather than let the imports
be followed implicitly. To get around it, we can tell mypy to check all of the modules by passing all of them like this:

```
$ mypy -m blue -m green -m red -m thirdparty --follow-imports=error
.venv/lib/python3.12/site-packages/thirdparty/__init__.py:2:
error: Incompatible return value type (got "int",
expected "str")  [return-value]
red.py:2: error: Incompatible return value type (got "int",
expected "str")  [return-value]
blue.py:5: error: Missing positional argument "x" in call to
"copy"  [call-arg]
blue.py:6: error: Incompatible types in assignment (expression
has type "str", variable has type "int")  [assignment]
Found 4 errors in 3 files (checked 4 source files)
```

Now we have _four_ errors, not three! This is because we are also now checking the internals of `thirdparty`,
because we are explicitly passing it.

### `skip` mode

So, those are the two extremes. Let's try `skip` mode:

```
$ mypy -m blue --follow-imports=skip
blue.py:5: error: Missing positional argument "x" in call
to "copy"  [call-arg]
Found 1 error in 1 file (checked 1 source file)
```

Just one error! In this mode, we don't follow any imports at all (except the standard library one,
which it will always check). Notice in particular the absence of an error relating to calling `thirdparty.get_string`:
because we're skipping it, mypy is not bothering even to check the type signature of that function. We'd see the same
behaviour if we were interacting incorrectly with a local module: no error!

### `silent` mode

Finally, there is `silent` mode:

```
$ mypy -m blue --follow-imports=silent
blue.py:5: error: Missing positional argument "x" in call
to "copy"  [call-arg]
blue.py:6: error: Incompatible types in assignment (expression
has type "str", variable has type "int")  [assignment]
Found 2 errors in 1 file (checked 1 source file)
```

This mode sits between `normal` and `skip`. What's happening under the hood is that mypy is following the imports, but
it's not reporting on errors outside the modules we explicitly ask to check. This has the effect of treating local
modules (that weren't passed) in the same way as the standard library and third party packages are: internal errors
aren't reported on, but mistakes relating to interacting with those modules *are* reported as errors.

## Observations on the different modes

[The mypy docs](https://mypy.readthedocs.io/en/stable/running_mypy.html#following-imports) recommend using `normal`
or `error` modes, if possible, as it makes sure you're not accidentally skipping any part of the code base. The interesting
thing about `error` mode is it will force you to check the internals of all third party packages, too, which seems
strange to me.

`skip`, the documentation suggests, should be used with caution. I can understand why: detecting
whether a function in an upstream package is called with the correct types is, surely, essential if you're going to bother
running a type checker at all? But perhaps there is some niche use case I haven't thought of.

Finally, there's `silent`. The mypy docs suggest that using this is a compromise, to be used if it is just too
difficult to check the whole code base. But now I understand what this does, I kind of like it. It brings the behaviour
checking local modules in line with the third party / standard library packages, making it a bit easier to remember
what's being checked. I can imagine this might be worth exploring if you wanted to run type checking on different parts of your code base
(did I mention we have a _really_ big code base?) in different commands, and wanted to concentrate on the interactions
between different parts, rather than reporting all the errors in one go. We don't use it at Kraken (yet), but maybe
there are some interesting use cases.

## Type stubs

There's one final thing to mention before I wrap up. Remember this error from earlier?

```
Skipping analyzing "thirdparty": module is installed, but
missing library stubs or py.typed marker  [import-untyped]
```

The way we addressed this earlier was to add a `py.typed` marker so mypy knew we were happy to use the type annotations
in the package. But, as the error message suggests, there is another mechanism we can use: type stubs.

Type stubs allow type annotations to be provided in a separate file from the source code. They have the same name as
the module they concern, but with a `.pyi` extension. They provide all the typing information that is needed, but with
other runtime code replaced with ellipses (`...`). To see how these work, create a file alongside `green.py` named
`green.pyi` containing this code:

```python
def get_int() -> int: ...
```

Here we're defining a new function, but it has no body. Note also that, unlike in `green.py`, we're not importing `red`.

Now, replace all the code in `blue.py` with this:

```python
import green

a: str = green.get_int()
```

And run the type checker on blue (with `follow-imports` in the default `normal` mode):

```
$ mypy -m blue
blue.py:3: error: Incompatible types in assignment (expression
has type "int", variable has type "str")  [assignment]
Found 1 error in 1 file (checked 1 source file)
```

There are two interesting things to note here. The first is that it is erroring based on the return value of the
`get_int` function in `green`. But `green.py` doesn't have a `get_int` function! That's because if mypy finds a
type stub, it will use that instead of the module. Now of course in a real code base we'll want the type stub to
accurately reflect what functions are in the module it describes, but it's a good demonstration of how mypy prefers
to use a type stub over a real module.

The other interesting thing is that, despite being in `follow-imports=normal` mode, there is no error from `red.py`.
This is, again, because mypy isn't looking at `green.py` at all, only at the stub file. If we did import `red` from
the stub file then the error would show up again.

There are more rules around the discovery of stub files that I won't go into here. The key take away is that stub files
allow us to provide alternatives for what mypy looks at &mdash; and, therefore, which modules it views as upstream, when
following imports.

## In summary

When type checking a module, mypy will often encounter an import of a module that it hasn't been explicitly asked to
type check. It does different things depending on the kind of module, the `follow-imports` mode we tell it to run in,
and whether it finds a stub file or not.

- Mypy _always_ checks that we are interacting correctly with the standard library
 (and _never_ checks standard library internals).
- In `normal` mode:
  - Third party packages are checked in the same way as standard library packages.
  - Local modules imported by passed modules are fully checked, as if they were themselves explicitly passed. The same
    goes for local modules imported by those modules, and so on.
- `silent` mode makes imported local packages behave like standard library / third party packages: it won't error
  on their internals, only on the interactions.
- `skip` mode doesn't check interactions with anything except the standard library.
- `error` mode errors if we try to import anything (except the standard library) that isn't explicitly passed.
- If Mypy finds a `.pyi` file that corresponds to a module, it will use that instead. 

You might find it interesting to test your knowledge by introducing errors in different places in the code base we just
created, and see if you can predict which errors will show up in different modes. Happy type checking!

## Further reading

- [Mypy docs on following imports](https://mypy.readthedocs.io/en/latest/running_mypy.html#following-imports)
