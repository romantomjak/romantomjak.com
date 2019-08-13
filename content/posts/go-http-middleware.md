---
title: "Go HTTP Middleware"
date: 2019-08-11T19:06:57+01:00
draft: false
tags: ["http", "middleware"]
categories: ["go"]
summary: How I replaced NGINX with Go's HTTP server for static file serving and then equipped it with access log middleware that writes details about incoming requests to the log.
---

I was working on an HTML website for a Go project and like always, I started by extending the NGINX image, but then it hit me... what if I replaced NGINX with Go's HTTP server?!

<div style="width:100%;height:0;padding-bottom:43%;position:relative;"><iframe src="https://giphy.com/embed/idKeY3nvmdIsM" width="100%" height="100%" style="position:absolute" frameBorder="0" class="giphy-embed" allowFullScreen></iframe></div>

Immediately after trying out this profane idea I run into an issue where by default you don't get any HTTP logging facilities, but luckily this is very easy to correct using (you guessed it!) HTTP middleware.

## The Middleware type

Middleware can be used to inject additional functionality to one or more functions. Common middleware examples include database middleware, session middleware, rate limiting middleware, and so on. Most often it’s just a function that wraps and replaces another function. We’re going to define a `Middleware` type to describe a function that takes and returns an `http.Handler`:

```go
type Middleware func(http.Handler) http.Handler
```

I'd like to make a point here: coming from dynamically typed languages, it is very refreshing to be able to define and use your own custom types to express an idiom!

## Access Log Middleware

Access log is simply a location (usually a file) were HTTP server logs details about incoming requests. It's useful for monitoring nefarious behavior, User Agents used to access the site, approximate geographical location of the users and so on. Most commonly the HTTP method, Path, User Agent and IP address are recorded.

Here's an adapted example from Mat Ryer's article about [go middleware](https://medium.com/@matryer/writing-middleware-in-golang-and-how-go-makes-it-so-much-fun-4375c1246e81):

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

The most interesting bit here, of course, is the _Printf_ statement that we injected just before calling the real handler. In fact, it is quite possible to create a middleware that refuses to serve requests altogether. Like when an HTTP header is missing or rate limit was exceeded, etc.

We also see our good 'ol `Middleware` type at work - when `AccessLog` is called, it will return the wrapped function (our Middleware), but because it also happens to be a closure - it will be able to use injected logger to log details about the request.

## How to use it

Now, we could, of course, manually wrap each function, but that would quickly get out of hand. Instead, let's create (yet another) function that will _chain_ the middlewares together automatically:

```go
func WithMiddleware(h http.Handler, middlewares ...Middleware) http.Handler {
    for _, middleware := range middlewares {
        h = middleware(h)
    }
    return h
}
```

This allows us to do some pretty cool stuff like chaining multiple middlewares:

```go
http.Handle("/", WithMiddleware(indexHandler, CheckSession(db), AccessLog(logger)))
```

## Testing the middleware

Our new middleware can also be very easily tested because we didn’t break the `http.Handler` interface:

```go
func TestMiddleware_AccessLog(t *testing.T) {
    req, _ := http.NewRequest("GET", "/", nil)
    resp := httptest.NewRecorder()

    buf := new(bytes.Buffer)
    logger := log.New(buf, "", log.LstdFlags)
    WithMiddleware(indexHandler(), AccessLog(logger)).ServeHTTP(resp, req)

    haystack := buf.String()
    needle := "GET / HTTP/1.1"
    if !strings.Contains(haystack, needle) {
        t.Errorf("expected %+v to contain %q but it didnt", haystack, needle)
    }
}
```

This means we can apply our middleware wherever the `http.Handler` interface is used! How cool is that?
