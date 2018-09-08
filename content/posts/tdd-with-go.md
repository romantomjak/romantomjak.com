---
title: "TDD with Go"
date: 2018-09-02T15:20:03+01:00
draft: false
tags: ["go"]
categories: ["tdd"]
summary: Short introduction to TDD with Go. Why I like TDD, what are the benefits of practising TDD and, of course, a small CLI tool that will convert words into military call letters using the Military phonetic spelling alphabet!
aliases: ["/posts/tdd-with-go/"]
---

I often find myself tinkering with Go as it possesses many of the language qualities I like - statically typed, compiled language that in many ways is similar to C, but with memory safety and garbage collection.

{{< figure width="350" src="/media/tdd-circle-of-life.png" class="center" alt="TDD Circle of Life" >}}

Test-driven development (TDD) is a software development technique that relies on very short, repetitive development cycles. Business requirements are turned into very specific test cases, then the software is _improved_ until tests are passing. I specifically used the word improved - not only the tests are passing, but also small refactorings are made along the way. In other words, the goal of TDD is to write clean code that works.

## MilPA

I can already hear you saying _u wot m8?_, but bear with me. This amazing acronym stands for Military Phonetic Alphabet! (_Crowd loses their mind. Cheering and applause follow._)

This CLI tool will convert words and letters into military call letters using the Military Phonetic Spelling Alphabet. I picked this particular example because I often need to spell out something over the phone and I can't remember what each letter stands for. So hopefully this will be useful for both - me, and the person reading this article!

Github repo for the unpatient peeps: [https://github.com/romantomjak/milpa](https://github.com/romantomjak/milpa)

## Writing a failing test

Let's start by creating `milpa_test.go` and defining our test:

```golang
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
$ go test
./milpa_test.go:10:15: undefined: LetterToCode
```

Yep!

Let's fix this test by creating a `milpa.go` with the following content:

```golang
package main

func LetterToCode(letter string) string {
    return "Romeo"
}
```

Run our tests again and.. BOOM! Our first successful test! Right now this function is not really useful since we've hardcoded the result, but it made our test pass and that is all that matters for now.

## The cycle repeats - more broken tests!

Making sure we correctly map single letter `R` is not really useful, so let's make sure we test for all mappings. In `milpa_test.go` add the following:

```golang
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

```golang
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

Surely, another dict with mappings would be useful, but it's not [DRY](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself)... Let's not worry about that now and go ahead and define it in `milpa.go`, right after the `package` statement:

```golang
package main

var CODES = map[string]string{
    ...
}
```

I did not include the whole dictionary, but it's the same we have in `milpa_test.go`.

Now modify the `LetterToCode` to use our newly defined mappings:

```golang
func LetterToCode(letter string) string {
    return CODES[letter]
}
```

run the tests and... BOOM! Tests pass again! The joy!

## Refactoring

We're at the _Refactoring_ stage of the TDD lifecycle now and we definitely have things to refactor. I hear you yell _DRY!_ and you're right. We've defined the exact same call letter mappings in two separate files. The horror! Let's re-use the mappings from the `milpa.go`.

In `milpa_test.go` delete the `TEST_CODES` mapping and change the test to use `CODES` defined in `milpa.go`:

```golang
func Test_Maps_Letters_To_Codes(t *testing.T) {
    for letter, code := range CODES {
        ...
    }
}
```

That's better! We're no longer duplicating code and actually using mappings from production code.

## Time to improve

Let's continue _improving_ our application by making sure that we don't modify symbols we're not aware of. In `milpa_test.go` add the following lines:

```golang
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

```golang
func LetterToCode(letter string) string {
    if val, ok := CODES[letter]; ok {
        return val
    }
    return letter
}
```

run the tests again and... BOOM! All green! I'm starting to like this!

## More broken tests and answers to questions

What else can we improve? What happens when I call the function with lower case letters? I don't know! But let's test that! :)))

```golang
import (
    "strings"
    ...
)

...

func Test_Ignores_Case(t *testing.T) {
    for letter, code := range CODES {
        lcLetter := strings.ToLower(letter)
        result := LetterToCode(lcLetter)
        if code != result {
            t.Errorf("Expected '%s' to be a '%s' but got '%s'", lcLetter, code, result)
        }
    }
}
```

... annnnd it didn't work. But that's okay. Let's fix that!

Simplest thing to do would be to check if the letter is in lower case and convert it to upper case. That sounds sensible! Let's try:

```golang
import (
    "strings"
)

...

func LetterToCode(letter string) string {
    code := letter
    if strings.ToLower(letter) == letter {
        code = strings.ToUpper(letter)
    }
    if val, ok := CODES[code]; ok {
        return val
    }
    return code
}
```

Great success!

## Converting whole words to call codes

Almost there! The last bit that I'm curious about is to see what happens when I have a bunch of words that I want to convert. Sounds like I would need another function for this... Let's start by speccing out the interface we would like to use:

```golang
func Test_Maps_Word_To_Codes(t *testing.T) {
    word := "Foo"
    want := "Foxtrot Oscar Oscar"
    got := WordToCode(word)
    if got != want {
        t.Errorf("Expected '%s' to be a '%s' but got '%s'", word, want, got)
    }
}
```

ah, but of course! We haven't defined `WordToCode`, but you already knew that, didn't you? :)))

Quick clickity-clacking leads to this:

```golang
func WordToCode(word string) string {
    return "Foxtrot Oscar Oscar"
}
```

Brilliant!

## Speccing out a new function through a failing unit test

Right. Let's modify our test to assert for different outcomes:

```golang
func Test_Maps_Word_To_Codes(t *testing.T) {
    testCases := []struct {
        words string
        want  string
    }{
        {"Foo", "Foxtrot Oscar Oscar"},
        {"Foo Bar", "Foxtrot Oscar Oscar Bravo Alpha Romeo"},
    }
    for _, tc := range testCases {
        if got := WordToCode(tc.words); got != tc.want {
            t.Errorf("Expected '%s' to be a '%s' but got '%s'", tc.words, tc.want, got)
        }
    }
}
```

So... how do we imagine our function to work? I assume we will have some sort of buffer where we will append our call codes to and then just return the whole string. Sounds good? Let's try it!

```golang
import (
    "bytes"
    "strings"
)

...

func WordToCode(word string) string {
    var buffer bytes.Buffer
    for index, character := range word {
        letter := string(character)
        if letter == " " {  // don't process spaces
            continue
        }
        code := LetterToCode(letter)
        space := " "
        if index+1 == len(word) {  // skip trailing space
            space = ""
        }
        buffer.WriteString(code + space)
    }
    return buffer.String()
}
```

Ahhh... yes!

## Building an executable

Now that our code is fully tested we can add a simple main method and finally compile it to a binary and run a e2e test :)

```golang
import (
    "bytes"
    "fmt"
    "os"
    "strings"
)

...

func main() {
    if len(os.Args) < 2 {
        fmt.Printf("usage: %s hello world\n", os.Args[0])
        os.Exit(1)
    }

    for i := 1; i < len(os.Args); i++ {
        word := os.Args[i]
        fmt.Println(WordToCode(word))
    }
}
```

Let's build that now:

```sh
$ go build
```

... and now for the moment of truth:

```sh
$ ./milpa hello world
Hotel Echo Lima Lima Oscar
Whiskey Oscar Romeo Lima Delta
```

BOOM! How 'bout that!

## Conclusion

I had great fun writing this article and hope you enjoyed reading it! Hopefully I managed to explain one of the benefits of practising TDD clear enough - we were making sure the system actually meets our requirements!

Did you notice how I asked questions about our system that I did not have answer to? What did I do? Created a test to confirm or reject the idea! I find it very liberating that I can back my thoughts with a unit test.

I also believe TDD allows to write cleaner code because we first try to understand how it will interact with other parts of the system which leads to better decision making and more maintainable code.

Did I already mention refactoring? Refactoring with thoroughly tested code base is a breeze!