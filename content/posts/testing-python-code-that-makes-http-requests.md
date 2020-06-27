---
title: "Testing Python code that makes HTTP requests"
date: 2019-01-14T19:41:57Z
draft: false
tags: ["unit tests", "design patterns", "dependency injection"]
categories: ["python"]
summary: Dependency is the key problem in software development at all scales. I'm sharing a pattern that I have found useful when testing code that makes HTTP requests.
---

Dependency is the key problem in software development at all scales. If you have Oracle SQL queries scattered throughout the codebase and you decide to switch to PostgreSQL, then you will find out that your code is dependent on Oracle database and you can't change the database without changing the code.

This often occurs when code has been written without any thought of how it will be tested. I can guarantee that it would not have been a problem if only the code was written with testing in mind.

> Unit tests allow you to imagine the perfect interface of how a particular thing should look like even before you have implemented it. It becomes particularly obvious when using Test Driven Development.

I have an article about [TDD with Go]({{<ref "/posts/tdd-with-go">}}) if you're interested to read more about the TDD style of programming, but essentially those pesky SQL queries would have probably ended up in a class of some sort that performs the database queries. The added boundary would allow us to swap it out for something simpler when running tests or even to PostgreSQL without a problem.

## The electricity bill problem

Imagine you are a member of the billing platform team of Green Energy Solutions and you have been tasked with the implementation of electricity bill calculation for customers. The platform consists of various microservices and to obtain meter readings you have to query a REST API.

I think it's fair to say most folks in a situation like this would reach for the [requests](https://requests.readthedocs.io/) python library to grab the readings and then do the required calculations.

```python
import requests

def calculate_electricity_bill(member_id):
    r = requests.get(f"https://api.company.com/readings/{member_id}")
    # some code here that calculates the bill based
    # on the readings returned by the API
    return amount
```

and the accompanying test case:

```python
def test_calculate_members_bill():
    member_id = 123
    assert calculate_electricity_bill(member_id) == 88.2
```

Running the test suite reveals that an HTTP request is made on **every test run**. That is not only wrong from the perspective of unit testing because we have failed to properly isolate the unit under test, but also because it does not even exercise the logic to calculate the bill due to the failed HTTP request. How to setup data for a test like this?

Luckily, software engineering has been around for a while and hundreds of developers have already run into this problem and over time a pattern has emerged to deal with this type of situation - [Dependency Inversion principle](https://en.wikipedia.org/wiki/Dependency_inversion_principle).

## Applying dependency inversion principle

Dependency Inversion Principle stands for the D of [SOLID design principles](https://en.wikipedia.org/wiki/SOLID).  Wikipedia provides a long mumbo-jumbo of how it is defined (which you are more than welcome to read), but essentially it comes down to this:

> - High-level modules should not depend on low-level modules. Both should depend on abstractions (e.g. interfaces).
> - Abstractions should not depend on details. Details (concrete implementations) should depend on abstractions.

Circling back to our earlier example, the `requests` library is the low-level dependency of our high-level functionality that we need to change into an "interface":

```python
def calculate_electricity_bill(member_id):
    r = requests.get(f"https://api.company.com/readings/{member_id}")
    # ...
```

That being said, Python does not have interfaces, so we'll just rely on good ol' polymorphism to achieve the same effect:

```python
def calculate_electricity_bill(fetcher, member_id):
    r = fetcher.get(f"https://api.company.com/readings/{member_id}")
    # ...
```

The class that implements the fetcher "interface" can be injected using [Dependency Injection](https://en.wikipedia.org/wiki/Dependency_injection) or it could just as easily be provided by the caller of the function.

## Creating a stub fetcher

We're going to use a stub to implement the fetcher "interface" that we introduced earlier. Stub is an object that holds predefined data and uses it to answer calls during tests. Michal Lipski has written up an excellent article on [Test Doubles](https://blog.pragmatists.com/test-doubles-fakes-mocks-and-stubs-1a7491dfa3da) if you're interested to read more about stubs.

```python
import json

class StubFetcher:
    def __init__(self, data):
        self.data = data
    
    def get(self, url):
        return json.dumps(self.data)

def test_calculate_members_bill():
    member_id = 123
    readings = {
        {"timestamp": "2020-07-18T08:28:24Z", "kwh": 804},
        {"timestamp": "2020-08-20T17:35:24Z", "kwh": 884},
        # ...
    }
    fetcher = StubFetcher(readings)
    assert calculate_electricity_bill(fetcher, member_id) == 88.2
```

Run the test suite again and you'll notice that no HTTP requests are being made and what is even better - we can control what data is used to calculate the electricity bill! Now you can easily add more tests to see what happens when there are no meter readings or when there are multiple readings in a month and so on.

## Closing thoughts

Dependency Inversion Principle is one of the simplest things you can add to your arsenal to make your code easier to test.

Tests are a safety net. They build confidence. Confidence to add new features or refactor old code without the fear of breaking other things. They highlight problems before the code hits production.

Maintain your tests just as well as you maintain any other code.
