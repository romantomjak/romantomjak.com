---
title: "TDD with Go"
date: 2018-09-02T15:20:03+01:00
draft: true
tags: ["go"]
categories: ["tdd"]
summary: Short introduction to TDD with Go. We will be creating a CLI tool that converts words into military call letters using the Military phonetic spelling alphabet.
---

### TODO

- Add closing thoughts
- Link github repo - https://github.com/romantomjak/milpa
- Proofread, spell check

---

I often find myself tinkering with Go as it possesses many of the language qualities I like - statically typed, compiled language that in many ways is similiar to C, but with memory safety and garbage collection.

{{< figure width="350" src="/media/tdd-circle-of-life.png" class="center" alt="TDD Circle of Life" >}}

Test-driven development (TDD) is a software development technique that relies on very short, repetitive, development cycles. Business requirements are turned into very specific test cases, then the software is _improved_ until tests are passing. I specifically used the word improved, which I think serves a very important point here - not only the tests are passing, but also small refactorings are made along the way. In other words, the goal of TDD is to write clean code that works.

## MilPA

I can already hear you saying _u wot m8?_, but bear with me. This amazing acronym stands for Military Phonetic Alphabet! (_Crowd loses their mind. Cheering and applause follow._)

This CLI tool will convert words and letters into military call letters using the Military Phonetic Spelling Alphabet. I picked this particular example because I often need to spell out something over the phone and I can't remember what each letter stands for. So hopefully this will be useful for both, person reading the article, and me!

## Writing a failing test

Let's start by creating `milpa_test.go` and defining our test:

```go
package main

import (
    "testing"
)

func Test_Maps_Letter_To_Code(t *testing.T) {
    letter := "R"
    code := "Romeo"
    result := LetterToCode(letter)
    if code != result {
        t.Errorf("Expected '%s' to be '%s', but got '%s'", letter, code, result)
    }
}
```

and, of course, you will correct me that I haven't defined `LetterToCode`, but that's okay for now.

## Making the test pass

Now, if we run our test suite it will obviously complain about `LetterToCode` being undefined and that's fair. Let's confirm our assumptions by running the test:

```sh
go test
```

Yep!

Let's fix this test by creating a `milpa.go` with the following content:

```go
package main

func LetterToCode(letter string) string {
    return "Romeo"
}
```

Run our tests again and.. our test passes! Right now this function is not really useful since we've hardcoded the result, but it made our test pass and that is all that matters for now.

## The cycle repeats - more broken tests!

Making sure we correctly map single letter `R` is not really useful, so let's make sure we test for all mappings. In `milpa_test.go` add the following:

```go
var TEST_CODES = map[string]string{
    "A": "Alpha",
    "B": "Bravo",
    "C": "Charlie",
    "D": "Delta",
    "E": "Echo",
    "F": "Foxtrot",
    "G": "Golf",
    "H": "Hotel",
    "I": "India",
    "J": "Juliett",
    "K": "Kilo",
    "L": "Lima",
    "M": "Mike",
    "N": "November",
    "O": "Oscar",
    "P": "Papa",
    "Q": "Quebec",
    "R": "Romeo",
    "S": "Sierra",
    "T": "Tango",
    "U": "Uniform",
    "V": "Victor",
    "W": "Whiskey",
    "X": "X-ray",
    "Y": "Yankee",
    "Z": "Zulu",
}
```

Refactor our test method slightly to make use of our newly defined mappings:

```go
func Test_Maps_Letters_To_Codes(t *testing.T) {
    for letter, code := range TEST_CODES {
        result := LetterToCode(letter)
        if code != result {
            t.Errorf("Expected '%s' to be a '%s' but got '%s'", letter, code, result)
        }
    }
}
```

run our test suite and... we have a gazillion of broken tests. Great.

## Fixing 1 000 000 broken tests

Now our tests are calling the `LetterToCode` with all alphabet letters, but we're only returning result for the letter `R`...

Surely, another dict with mappings would be useful, but it's not [DRY](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself)... Let's worry about that later and go ahead and define it in `milpa.go`, right after the `package` statement:

```go
package main

var CODES = map[string]string{
    ...
}
```

I did not include the whole dictionary, but it's the same we have in `milpa_test.go`.

Now modify the `LetterToCode` to use our newly defined mappings:

```go
func LetterToCode(letter string) string {
    return CODES[letter]
}
```

run the tests and... BOOM! Tests pass again! The joy!

## Refactoring

We're at the _Refactoring_ stage of the TDD lifecycle now and we definitelly have things to refactor. I hear you yell _DRY!_ and you're right. We've defined the exact same call letter mappings in two seperate files. The horror! Let's re-use the mappings from the `milpa.go`.

In `milpa_test.go` change `TEST_CODES` to `CODES`:

```go
func Test_Maps_Letters_To_Codes(t *testing.T) {
    for letter, code := range CODES {
        ...
    }
}
```

That's better!

## Time to improve

Let's continue _improving_ our application by making sure that we don't modify symbols we're not aware of. In `milpa_test.go` add the following lines:

```go
func Test_Ignores_Unknown_Symbols(t *testing.T) {
    symbols := []string{" ", ",", ";", "!"}
    for _, symbol := range symbols {
        result := LetterToCode(symbol)
        if symbol != result {
            t.Errorf("Expected '%s' to be the same, but got '%s'", symbol, result)
        }
    }
}
```

run the tests and... we've got work to do.

Let's modify the `LetterToCode` function slightly and see if that makes the test pass:

```go
func LetterToCode(letter string) string {
    if val, ok := CODES[letter]; ok {
        return val
    }
    return letter
}
```

run the tests again and... BOOM! All green! I'm starting to like this!
