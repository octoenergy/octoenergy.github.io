---
title: Tentaclio -- handling streams and db connections with ease.
layout: post
category: news
author: Javier Asensio-Cubero 
banner: /assets/img/posts/2015-11-23-tech-jobs.jpg
hex: 0e1720
---

In the data team here at [Octopus Energy](https://octopus.energy/) we spend a big
chunk of our time handling, well..., data. Sometimes our work is a mere glorification
of _copy this file here, clean it a bit, insert it in a database, and have some dashboard to show it_.
Solving this kind of problem can be restricted to _where_ to get data from, _where_ to put it, 
_which_ schema to use, etc.

Authenticated resources is another important issue that we deal with. We source data from different FTP (🙄), SFTP, 
HTTP servers, S3 buckets, and store them in databases of different nature. Credentials management, and specifically distribution, 
becomes a bit of an ordeal. We need to store them securely but make it also easily accessible for the data analysts, 
kubernetes jobs, and airflow.

In order to try to fix both problems at once we have created [tentaclio](https://github.com/octoenergy/tentaclio), 
a library that tries to simplify the access to authenticated stream/database resources. 

# Stream management

*Tentaclio* is designed around URLs as they serve the purpose of giving access to different resource
types, while allowing to easily authenticate those resources. 

This is a minimal example of how it works.
```python
import tentaclio as tio
contents = "👋 🐙"

with tio.open(
    "ftp://localhost:2021/upload/file.txt", 
    mode="w") as writer: 
    writer.write(contents)

with tio.open("/tmp/file.txt", mode="w") as writer: 
    writer.write(contents)

# Using boto3 authentication under the hood.
bucket = "s3://my-bucket/octopus/hello.txt"
with tio.open(bucket) as reader:
    print(reader.read())
```

We've tried to simplify the definition of _where_ and _how_ we access the data as much as possible. 
The only difference in your code if you want to save the data to a bucket, FTP, or local drive
is just the URL. 
We also tried to be as pythonic as possible by mimicking the built-in `open` behaviour.

# Authenticating resources

Of course you can use authenticated URLs in `tio.open` as well, i.e  `sftp://constantine:tentacl3@sftp.octoenergy.com/`, it will
just work. But we have included a simple credentials injection system in *tentaclio* in order to make authentication more straightforward.



```python
import os                                                                            
                                                                                     
import tentaclio as tio
                                                                                     
print(
    "env ftp credentials", 
    os.getenv("TENTACLIO__CONN__OCTOENERGY_FTP"))              
# This prints `sftp://constantine:tentacl3@sftp.octoenergy.com/`                     
                                                                                     
# Credentials get automatically injected.                                            
with tio.open(
    "sftp://sftp.octoenergy.com/uploads/data.csv") as reader:        
    print(reader.read())     
```

The user name and password will be automatically added to the URL when calling `open`. 
This is done via matching the known environment variables starting with `TENTACLIO__CONN__` 
to the actual URL passed for accessing the resource. This decouples the resources form the credentials
that usually are bound together.

The design of *tentaclio*'s credentials injection strategy is driven by our particular needs but we believe that they might be fairly common.  
We use a distributed system where the data source might be defined in one part of the system (namely our airflow server), but consumed in some
container running in a kubernetes cluster. We also have different credentials for different environments, such as prod and test. 

In any case our motivation comes from avoiding passing around credentials in plain text, and making the credentials more manageable than
using a heap of environmental variables. That's why a collection of secrets can also be passed to *tentaclio* in a configuration file, so they could be easily managed as 
a kubernetes or docker secret. 

```yaml
secrets:
    db_1: postgresql://user1:pass1@myhost.com/database_1
    db_2: postgresql://user2:pass2@otherhost.com/database_2
    ftp_server: ftp://fuser:fpass@ftp.myhost.com
```
This file is accessible to *tentaclio* via the environmental variable `TENTACLIO__SECRETS_FILE`.
The actual name of each URL is for traceability and has no effect in the functionality. 

# Database connections 

```python
import tentaclio as tio

with tio.db("postgresql://hostname/my_data_base") as client:
    client.query("select 1")
```

Note that `hostname` in the URL to be authenticated is a wildcard that will match any hostname. So `authenticate("http://hostname/file.txt")` will be injected to `http://user:pass@octo.co/file.txt` if the credentials for `http://user:pass@octo.co/` exist.

For databases we rely on [sqlalquemy](https://www.sqlalchemy.org/) in order to interact with databases, adding the authentication layer and some tailored functionality to control transactions.

---
*Tentaclio* is in an alpha state at the moment but we use it quite widely across many data oriented projects as we find it pretty useful and stable. 
If you think it might make your life easy, please feel free to try it out and give us some feedback.

🐙 and ❤️ .
