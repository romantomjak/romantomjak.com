---
title: "Go HTTP Middleware"
date: 2019-06-03T22:22:56+01:00
draft: true
tags: ["http", "middleware"]
categories: ["go"]
summary: How I replaced NGINX with Go's HTTP server for static file serving and then equipped it with access log middleware that writes details about incoming request to the log.
---

I was working on an HTML website for a Go project when I conceived this profane idea. Like always, I started with extending the NGINX image, but then it hit me... what if I replaced NGINX with Go's HTTP server?!

<div style="width:100%;height:0;padding-bottom:43%;position:relative;"><iframe src="https://giphy.com/embed/idKeY3nvmdIsM" width="100%" height="100%" style="position:absolute" frameBorder="0" class="giphy-embed" allowFullScreen></iframe></div>

Immediately I run into an issue where by default you don't get any HTTP logging facilities, but luckily this is very easy to correct using (you guessed it!) HTTP middleware.

What exactly is HTTP middleware in Go-speak? In the most simple form it's a function that wraps and replaces another function. They can be used to inject additional functionality to one or more functions. For instance, an `AccessLog` middleware could log details about the request to the log. Others could validate user's session or perform some sort of caching and so on.

## Middleware type

I'm going to make it plain - I love to rely on compiler for type checking. Coming from a dynamically typed language it is very refreshing! I'm trying to leverage it everywhere I can.

Let's go ahead and define a custom type for our middleware:

```go
type Middleware func(http.Handler) http.Handler
```

## Middleware

Now let's define our `AccessLog` middleware:

```go
func AccessLog(logger *log.Logger) Middleware {
    return func(h http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            logger.Printf("%s - \"%s %s %s\" %q\n", r.RemoteAddr, r.Method, r.URL.Path, r.Proto, r.UserAgent())
            h.ServeHTTP(w, r)
        })
    }
}
```

The `AccessLog` function returns a `Middleware` type - which in fact is just a function that takes and returns an `http.Handler`. When `AccessLog` is called, it will return the wrapped function, but because it's also a closure - it will be able to use injected logger to log details about the request.

## Using the middleware

One critical bit is still missing, how do we actually use our newly created middleware? Once again, the simplest way would be to call the function directly:

```go
logger := log.New(os.Stdout, "", log.LstdFlags)

http.Handle(AccessLog(logger)(indexHandler))
```

But this will quickly get out of hand when you'll want to apply multiple middlewares.

A cleaner approach would be to create (yet another) function that will _chain_ the middlewares together automatically and oooh, what's that! It's the `Middleware` type!

```go
func WithMiddleware(h http.Handler, middlewares ...Middleware) http.Handler {
    for _, middleware := range middlewares {
        h = middleware(h)
    }
    return h
}
```

The function above allows us to do pretty cool stuff:

```go
http.Handle("/", WithMiddleware(indexHandler, CacheTemplate(), CheckSession(db), AccessLog(logger)))
```

Look at that! This bad boy allows chaining multiple middlewares in a row! HURRAY!
