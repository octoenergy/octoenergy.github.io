---
title: Python interfaces a la Golang
layout: post
category: news
author: Javier Asensio-Cubero 
banner: /assets/img/posts/2015-11-23-tech-jobs.jpg
hex: 0e1720
---

For the last four years I have been jumping back and forth from Python and Go. The majority of the work I carry out as a Machine Learning Engineer at [Octopus Energy](https://octopus.energy/) is mostly focused on Python and the typical data science stack. We are working on medium/big scale data processing projects using all the usual suspects: keras, scikit-learn, pandas, airflow... namely I'm not doing any Go. 

There are two major things that I miss from Go when working on a Python project, static typing, and go interfaces. At octopus energy we try to enforce type hinting as much as possible in order to avoid silly mistakes (the ones I do more often) with great results, regardless its the intrinsic limitations. 

While dealing with data streams and specially with the `io` package in Python, it becomes a burden trying to keep a flexible interface while reusing elements of the standard library. Let's see the following example:

```python
import pandas as pd


def transform(input_file: str) -> pd.DataFrame:
    df = pd.read_csv(input_file, index="index")
    transformed_df = _transform(df)
    return transformed_df
```

This implementation has some drawbacks, passing a string with a file path for pandas to load a csv file makes testing difficult as you would need to create an actual csv. Also, we restrict ourselves to local files for applying our data transform, you might want to load the stream from other sources, such as http connections or a S3 bucket. 

You might be tempted to rewrite this function using `io` classes. 

```python
import pandas as pd
import io


def transform(input_io: io.TextIO) -> pd.DataFrame:
    df = pd.read_csv(input_io, index="index")
    transformed_df = _transform(df)
    return transformed_df
```

This sounds sensible, you're using a class offered by the standard library and `pandas`will like it as it uses an intrinsic reading _protocol_ (more on this soon). this means that as long as what you send down `pd.read_csv` has method/function called `read`, pandas will be able to load the data. But the definition `io` package makes a burden to extend the behaviour of any of its classes. Many `ftp` or `S3` readers out there won't inherit from these classes as typing is not really big in the python ecosystem. Also, building _fake_ io subclasses to test is an ordeal as you need to create a bunch of empty stubs to extend them.

##  Python protocols

Let's focus on the concept of _protocol_ in python. This not something new, you might know that calling `len()` in any object that contains the method `__len__` will just work. `__getitem__` , and the pickling protocol are more examples. Python, being loosely typed, will check programmatically that `__len__` exists before calling it in runtime. 

If you've written any go code, this will sound familiar, but of course you would enforce your protocol into an actual interface. In go, there's no concept of classes or inheritance, just _structs_. Structs can have some functions attached to them called _methods_ (sorry the nomenclature makes the comparison a bit messy). You define interfaces as contracts that your struct needs to meet, just like protocols! But being strictly typed, this is enforced during compilation time. 

Relying on type hinting to play along with protocols is known as [structural subtyping](https://www.python.org/dev/peps/pep-0544/) in python.

You might be wondering how this is different from inheritance. Let's have a look to the following example where we will create a useful function to print the length of different objects.

```python
class LenMixin:                                        
    def __len__(self) -> int:                          
        raise NotImplementedError()                    
                                                       
                                                       
class OneLengther(LenMixin):                           
    def __len__(self) -> int:                          
        return 1                                       
                                                       
                                                       
def print_with_len(has_len: LenMixin):                 
    print(len(has_len))                                
                                                       
                                                       
print_with_len(OneLengther())  # yay                   
print_with_len(list([1, 2, 3]))  # ney! type error     
```

Mypy will complain at line 14 in the previous example. The reason being the `list` object is not a subclass of `LenMixin`. That's unfortunate as the list class actually offers all the functionality we need. Of course, we could create a `MyList` class that inherits from both list and `LenMixin` but it adds tons of boilerplate code.

The package `typing_extensions` allows us to use protocols in a strictly typed fashion. A `Protocol` defines a set of functions that a class needs to _have_ in order to be used as an argument to another function. 
```python
from typing_extensions import Protocol                                                                        
                                                                                                              
                                                                                                              
class Sizable(Protocol):                                                                                      
    """A custom definition of https://mypy.readthedocs.io/en/latest/protocols.html#sized """                  
                                                                                                              
    def __len__(self) -> int:                                                                                 
        pass                                                                                                  
                                                                                                              
                                                                                                              
class MySizable:  # No superclass                                                                             
    def __len__(self) -> int:                                                                                 
        return 1                                                                                              
                                                                                                              
                                                                                                              
def print_sizable(sizable: Sizable):                                                                          
    print(len(sizable))                                                                                       
                                                                                                              
                                                                                                              
print_sizable(MySizable())  # yay                                                                             
print_sizable(list([1, 2, 3]))  # yaaaay!                                                                     
```

In this way we just need to have the `__len__` method in our class (or function in our module) in order to fulfill the `print_sizable` requirements. 

The whole concept of dependency injection in Go revolves around the idea of having interfaces as a contract. Your python _object_ or your go _struct_ needs to fulfill this contract in order to be used as a parameter to a function. This [blog post](https://appliedgo.net/di/) by Christoph Berger explains it way better, and [this video](https://www.youtube.com/watch%3Fv%3DifBUfIb7kdo) by the great Francesc Campoy will give you a deep insight of the concept.

Coming back to the reader example, here we define a protocol that allows reading streams.
```python
from abc import abstractmethod
from typing_extensions import Protocol
from typing import Any

class Reader(Protocol):
    """Reader protocol sets the contract to read streams."""
    @abstractmethod
    def __iter__(self):
        """Make the reader an iterable."""
        pass
    
    @abstractmethod
    def read(self, size: int = -1) -> Any:
        """Read the given amount of bytes."""
        pass
```

The reason why our reader needs to be iterable comes from [panda's file objects](https://github.com/pandas-dev/pandas/blob/master/pandas/core/dtypes/inference.py%23L194).

Now we can rewrite our `tranform_cvs` function to use this protocol as an input.

```python
import pandas as pd
from abc import abstractmethod
from typing_extensions import Protocol
from typing import Any

class Reader(Protocol):
    """Reader protocol sets the contract to read streams."""
    @abstractmethod
    def __iter__(self):
        """Make the reader an iterable."""
        pass
    
    @abstractmethod
    def read(self, size: int = -1) -> Any:
        """Read the given amount of bytes."""
        pass


def transform(input_reader: Reader) -> pd.DataFrame:
    df = pd.read_csv(input_reader, index="index")
    transformed_df = _transform(df)
    return transformed_df

```
From this implementation we obtain function that accepts not only any _file\_like\_object_, such as files, `io.StringIO` or `io.BytesIO`, but also any other third party libraries to stream S3 buckets, ftp, sftp, http, as long as they are iterables and have a `read(i:int=-1)` method. No inheritance needed, no extra glue code to make this work with third party libraries or testing fakes.

Protocols and structural subtyping make injecting dependencies and creating fake objects for testing easy and elegant.
