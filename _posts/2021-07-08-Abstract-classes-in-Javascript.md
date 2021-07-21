---
lang: en
layout: post
title: Abstract classes in Javascript
twitter: '1413030769308704768'
---

Javascript don't have the concept of abstract classes, but it's fairly easy to
implement them: don't allow it :-) Just check if the `constructor` of the
instance we are creating is the own class instead of one of its childrens, and
don't allow it:

```js
class A
{
  constructor()
  {
    if(this.constructor === A) throw new Error('`A` is an abstract class')
  }
}

class B extends A {}


const a = new A  // Uncaught Error: `A` is an abstract class
const b = new B  // success

a               // Uncaught ReferenceError: a is not defined
b instanceof A  // true
b instanceof B  // true
```

Just take in account, that since we are checking the `this` object, in case the
abstract class is extending from another parent base class (like for example
`EventEmitter`), then we need to do the checking **after** calling to the
constructor of the parent base class with the `super()` function.

As a bonus, we can easily notify when a method needs to be implemented in a
child class: similar to how it's done in Python, just throw an `Exception` in
the abstract parent base class:

```js
class NotImplementedError extends Error
{
  constructor()
  {
    super('Method not implemented')
  }
}


function notImplemented()
{
  throw new NotImplementedError()
}


class A
{
  foo()
  {
    notImplemented()
  }
}

class B extends A
{
  foo()
  {
    return 'bar'
  }
}


const a = new A
const b = new B

a.foo()  // Uncaught NotImplementedError: Method not implemented
b.foo()  // 'bar'
```

Now you would be saying, "why don't just set `A.foo = notImplemented` instead of
creating a class method?". Ok, because that would create a property function in
the instance, so although `B` has a `foo()` class method defined, the property
instance `A.foo` will be executed instead because it has a higher priority when
resolving it.
