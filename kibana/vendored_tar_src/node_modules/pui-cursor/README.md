# PUI Cursor
[![npm version](https://badge.fury.io/js/pui-cursor.svg)](https://badge.fury.io/js/pui-cursor)
[![Build Status](https://travis-ci.org/pivotal-cf/pui-cursor.svg)](https://travis-ci.org/pivotal-cf/pui-cursor)
[![Dependencies](https://david-dm.org/pivotal-cf/pui-cursor.svg)](https://david-dm.org/pivotal-cf/pui-cursor)

Utility designed for immutable data in a React flux architecture.

## Table of Contents

* [Overview](#cursors)
* [Timing](#timing)
* [API](#api)
    * [get()](#get)
    * [set()](#set)
    * [refine()](#refine)
    * [merge()](#merge)
    * [push()](#push)
    * [apply()](#apply)
    * [remove()](#remove)
    * [splice()](#splice)
    * [unshift()](#unshift)

##Cursors

PUI Cursors are simplified versions of [Om Cursors](https://github.com/omcljs/om/wiki/Cursors) designed for use with a
React Flux architecture. It enables targeted, immutable updates to data; these updates are particularly useful for updating a store in
React.

A cursor takes in data and a callback. The callback is used to propagate data into an app and create a new cursor with
the updated data.

A minimal example of cursor setup is below:

```js
const Cursor = require('pui-cursor');
const React = require('react');
const Zoo = require('./zoo');

class Application extends React.Component {
  constructor(props, context) {
    super(props, context);
    this.state.store = {animals: {lion: 'Larry', seal: 'Sebastian'}};
  }

  render() {
    const $store = new Cursor(this.state.store, updatedStore => this.setState({store: updatedStore}));

    return <Zoo animals={this.state.store.animals} $store={$store}/>;
  }
}
```

Our convention is to prefix Cursor instances with `$`, like `$store` in the above example. This convention
differentiates the cursor from the data it contains.

For example in this setup, if the `Zoo` component calls `this.props.$store.merge({visitors: ['Charles', 'Adam', 'Elena']});`,
the application store will now have `visitors` in addition to `animals`.

##Timing

When the cursor is updated, the callback is called asynchronously (inside of a `setImmediate()` under the hood). This is
to handle multiple synchronous updates to the cursor. The updates are batched together into a single callback.

### Synchronous Mode

If you want to use synchronous callbacks, you can enable synchronous mode by setting

```js
Cursor.async = false;
```

In synchronous mode, synchronous updates to the cursor are no longer batched. This can lead to many
more callbacks and a reduction in performance. **We recommend using synchronous mode only for unit tests**.

### Common Asynchronous Mistakes

#### Accessing the store before it updates

Using asynchronous callbacks can lead to unexpected behavior when accessing the store.

For example:

```js
var store = [1,2];
const $store = new Cursor(store, callback);
```

If you update the cursor and try to access the store synchronously,

```js
$store.push(3);
console.log($store.get());
```

you might expect the console to print `[1,2,3]`. Instead the console will print `[1,2]` because the callback has not
fired yet.

You can use the React lifecycle methods such as `componentWillReceiveProps` or `componentDidUpdate` to work
around this. For example, if you add the following function to a component that has the store as a prop,

```js
componentWillReceiveProps(nextProps) {
  if (nextProps.store !== this.props.store) {
    console.log(nextProps.store);
  }
}
```

the console will print `[1,2,3]`.

#### Stale Cursors

Another, more subtle, problem might arise from storing the cursor as a variable. If you are in a component with `$store`
on props, you might want to write code like the following:

```js
var $store = this.props.$store;
doSomethingAsync().then(function(something) {
  $store.push(something);
});
```

This code will work in isolation, but it has a race condition. If some other code updates the cursor (i.e.
`$store.push("otherThing")`) while you are waiting for `doSomethingAsync` to resolve, the active cursor has updated to
include "otherThing". When `doSomethingAsync` resolves, the handler attached to it will update the old cursor (that does
not include "otherThing"). The callback will be called with the old store, which does not have `"otherThing"`.

This bug can be hard to diagnose, so cursors will print a "You are updating a stale cursor" warning in the console when
a stale cursor is being updated.

The safer version of the code is:

```js
doSomethingAsync().then((function(something){
  this.props.$store.push(something);
}).bind(this));
```

This ensures that the component uses the most recent version of the store when updating.

##API

PUI Cursor provides wrappers for the [React immutability helpers](https://facebook.github.io/react/docs/update.html).
These wrappers allow you to transform the data in your cursor; the transformation you specify is applied and the new result
is used to update the cursor value.

###`get()`

Returns your current node

```js
var store = {animals: {lion: 'Larry', seal: 'Sebastian'}};
const $store = new Cursor(store, callback);
```

The cursor never updates its own data structure, so `get` is prone to returning stale data.

If you execute `$store.refine('animals', 'lion').set('Scar').get();`, it will return 'Larry' instead of 'Scar'

In general, we recommend that you not use `get` and instead access the store directly with props.
If you want to use `get`, ensure that you are using the newest version of your Cursor.

###`set()`

Sets the data for your current node. If you call `set at the top of the data tree, it sets the data for every node.

```js
var store = {animals: {lion: 'Larry', seal: 'Sebastian'}};
const $store = new Cursor(store, callback);
```


If you execute `$store.refine('animals').set({lion: 'Simba', warthog: 'Pumba'});`,
the callback will be called with `{animals: {lion: 'Simba', warthog: 'Pumba'}}`.

###`refine()`

Changes where you are in the data tree. You can provide `refine` with multiple arguments to take you deeper into the tree.

If the data node that you're on is an **object**, refine expects a string that corresponds to a key in the object.

```js
var store = {animals: {lion: 'Larry', seal: 'Sebastian'}};
const $store = new Cursor(store, callback);
```

For example, `$store.refine('animals', 'seal').get();`,  will return 'Sebastian'.

If the data node that you're on is an **array of objects**, refine expects an index or an element of the array.

```js
var hey = {greeting: 'hey'};
var hi = {greeting: 'hi'};
var hello = {greeting: 'hello'};
var store = {greetings: [hey, hi, hello]};
const $store = new Cursor(store, callback);
```

then `$store.refine('greetings', 1, 'greeting').get();` will return 'hi'. If you have the element of an array but not the index,
`$store.refine('greetings', hi, 'greeting').get();` will also return 'hi'.

###`merge()`

Merges data onto the object at your current node

```js
$store.refine('animals').merge({squirrel: 'Stumpy'});
```

The callback will be called with `{animals: {lion: 'Larry', seal: 'Sebastian', squirrel: 'Stumpy'}}`.

###`push()`

Pushes to the array at your current node

```js
var hey = {greeting: 'hey'};
var hi = {greeting: 'hi'};
var hello = {greeting: 'hello'};
var yo = {grettings: 'yo'};
var store = {greetings: [hey, hi, hello]};
const $store = new Cursor(store, callback);
```

If you execute `$store.refine('greetings').push({greeting: 'yo'});`, the callback will be called with `{greetings: [hey, hi, hello, yo]}`.

###`apply()`

If the simpler functions like `set`, `merge`, or `push` cannot describe the update you need,
you can always call `apply` to specify an arbitrary transformation.

Example:

```js
var currentData = {foo: 'bar'};
var cursor = new Cursor(currentData, function(newData){ this.setState({data: newData}); });
cursor.apply(function(shallowCloneOfOldData) {
  shallowCloneOfOldData.foo += 'bar';
  return shallowCloneOfOldData;
});
```

__Warning:__ The callback for `apply` is given a shallow clone of your data
(this is the behavior of the apply function in the React immutability helpers).
This can cause unintended side effects, illustrated in the following example:

```js
var currentData = {animals: {mammals: {felines: 'tiger'}}};
var cursor = new Cursor(currentData, function(newData){ this.setState({data: newData}); });

cursor.apply(function(shallowCloneOfOldData) {
  shallowCloneOfOldData.animals.mammals.felines = 'lion';
  return shallowCloneOfOldData;
});
```

Since the data passed into the callback is a shallow clone of the old data, values that are nested more than one level
deep are not copied, so `shallowCloneOfOldData.animals.mammals` will refer to the exact same object in memory as `currentData.animals.mammals`.

The above version of `apply` will mutate the previous data in the cursor (`currentData`) in addition to updating the cursor.
As a side effect, `shallow compare` will not detect any changes in the data when it compares previous props and new props.
To safely use `apply` on nested data, you need to use the React immutability helpers directly:

```js
var reactUpdate = require('react/lib/update');

cursor.apply(function(shallowCloneOfOldData) {
  return reactUpdate.apply(shallowCloneOfOldData, {
    animals: {
      mammals: {
        felines: {$set: 'lion'}
      }
    }
  });
});
```

###`remove()`

Removes your current node

If the current node is an object and you call remove(key), remove deletes the key-value.

```js
var store = {animals: {lion: 'Larry', seal: 'Sebastian'}};
const $store = new Cursor(store, callback);
```

If you execute `$store.refine('animals', 'seal').remove();`, the callback will be called with `{animals: {lion: 'Larry'}}`.

If the current node is an array:

```js
var hey = {greeting: 'hey'};
var hi = {greeting: 'hi'};
var hello = {greeting: 'hello'};
var store = {greetings: [hey, hi, hello]};
const $store = new Cursor(store, callback);
```

If you execute `$store.refine('greetings').remove(hello)`, the callback will be called with `{greetings: [hey, hi]}`.

###`splice()`

Splices an array in a very similar way to `array.splice`. It expects an array of 3 elements as an argument.
The first element is the starting index, the second is how many elements from the start you want to replace, and the
third is what you will replace those elements with.

```js
var hey = {greeting: 'hey'};
var hi = {greeting: 'hi'};
var hello = {greeting: 'hello'};
var yo = {greeting: 'yo'};
var store = {greetings: [hey, hi, hello]};
const $store = new Cursor(store, callback);
```

If you execute `$store.refine('greetings').splice([2, 1, yo]);`, the callback will be called with `{greetings: [hey, hi, yo]}`.

###`unshift()`

Adds an element to the start of the array at the current node.

```js
var hey = {greeting: 'hey'};
var hi = {greeting: 'hi'};
var hello = {greeting: 'hello'};
var yo = {greeting: 'yo'};
var store = {greetings: [hey, hi, hello]};
const $store = new Cursor(store, callback);
```

If you execute `$store.refine('greetings').unshift(yo);`, the callback will be called with `{greetings: [yo, hey, hi, hello]}`

---

(c) Copyright 2016 Pivotal Software, Inc. All Rights Reserved.
