
# Improvements to `std::future<T>` and Related APIs # future # future

## General # futures.general # futures.general

The extensions proposed here are an evolution of the functionality of
`std::future` and `std::shared_future`. The extensions enable wait free
composition of asynchronous operations.

## 30.6.6 Class template `future` # futures.unique-future # futures.unique-future

To the class declaration found in 30.6.6/3, add the following to the public
functions:

    bool is_ready() const;

    future(future<future<R>>&& rhs) noexcept;

<!-- decay the function, refer to std::async -->
<!-- result_of_t<decay_t<F>(future)> -->

    template<typename F>
    auto then(F&& func) -> future<decltype(func(*this))>;

    template<typename F>
    auto then(executor &ex, F&& func) -> future<decltype(func(*this))>;

    template<typename F>
    auto then(launch policy, F&& func) -> future<decltype(func(*this))>;

    template<typename R2>
    future<R2> unwrap();

Between 30.6.6/8 & 30.6.6/9, add the following:

    future(future<future<R>>&& rhs) noexcept;

*Effects:* Constructs a `future` object by moving the instance referred to by
`rhs` and unwrapping the inner  future (see `unwrap()`).

*Postconditions:*

<!-- revisit: what happens when innner future is invalid? -->

- `valid()` returns the same value as `rhs.valid()` prior to the 
constructor invocation.

- `rhs.valid() == false`.

After 30.6.6/24, add the following:

    template<typename F>
    auto then(F&& func) -> future<decltype(func(*this))>;

    template<typename F>
    auto then(executor &ex, F&& func) -> future<decltype(func(*this))>;

    template<typename F>
    auto then(launch policy, F&& func) -> future<decltype(func(*this))>;

*Notes:*  The three functions differ only by input parameters. The first only
takes a callable object which accepts a `future` object as a parameter. The
second function takes an `executor` as the first parameter and a callable object
as the second parameter. The third function takes a launch policy as the first
parameter and a callable object as the second parameter.  In cases where
`decltype(func(*this))` is `future<R>`, the resulting type is `future<R>`
instead of  `future<future<R>>`.

*Effects:*

<!-- TODO: revisit the behavior of deferred -->

-  The continuation is called when the object's shared state is ready (has a
value or exception  stored).
-  The continuation launches according to the specified launch policy or
executor.
-  When the executor or launch policy is not provided the continuation inherits
the parent’s  launch policy or executor.
-  If the parent was created with `std::promise` or with a `packaged_task` (has
no associated launch  policy), the continuation behaves the same as the third
overload with a policy argument of  `launch::async | launch::deferred` and the
same argument for `func`.
-  If the parent has a policy of `launch::deferred` and the continuation does
not have a specified  launch policy or scheduler, then the parent is filled by
immediately calling `wait()`, and the  policy of the antecedent is
`launch::deferred`

*Returns:* An object of type `future<decltype(func(*this))>` that refers to the
    shared state created by  the continuation.

*Postconditions:*

-  The `future` object is moved to the parameter of the continuation function
-  `valid() == false` on original `future` object immediately after it returns

```
template<typename R2>
future<R2> future<R>::unwrap()
```

*Notes:*

-  `R` is a `future<R2>` or `shared_future<R2>`
-  Removes the outer-most future and returns a proxy to the inner future.
The proxy is a  representation of the inner future and it holds the same value
(or exception) as the inner future.

*Effects:*

-  `future<R2> X = future<future<R2>>.unwrap()`, returns a `future<R2>` that
becomes ready when the shared state of the inner future is ready. When the
inner future is ready, its value (or exception) is moved to the shared
state of the returned future.
-  `future<R2> Y = future<shared_future<R2>>.unwrap()`, returns a `future<R2>`
that becomes ready when the shared state of the inner future is ready. When
the inner `shared_future` is ready, its value (or exception) is copied to the
shared state of the returned future.

<!-- TODO: specify what to do when the inner future is invalid -->

-  If the outer future throws an exception, and `get()` is called on the
returned future, the returned future throws the same exception as the outer
future. This is the case because the inner future didn't exit

*Returns:* A `future` of type `R2`. The result of the inner `future` is moved out
(`shared_future` is copied out) and stored in the shared state of the
returned future when it is ready or the result of the inner future throws
an exception.

*Postcondition:* The returned future has `valid() == true`, regardless of the
*validity of the inner future.

[*Example:*

    future<int> work1(int value);
    int work(int value) {
        future<future<int>> f1 = std::async([=] {return work1(value); }); 
        future<int> f2 = f1.unwrap();
        return f2.get();
    }

-- *end example*]


    bool is_ready() const;

*Returns:* `true` if the shared state is ready, `false` if it isn't.

## 30.6.7 Class template `shared_future` # futures.shared_future # futures.shared-future

To the class declaration found in 30.6.7/3, add the following to the public functions:

    bool is_ready() const;

    template<typename F>
    auto then(F&& func) -> future<decltype(func(*this))>;

    template<typename F>
    auto then(executor &ex, F&& func) -> future<decltype(func(*this))>;

    template<typename F>
    auto then(launch policy, F&& func) -> future<decltype(func(*this))>;

	template<typename R2>
	future<R2> unwrap();

After 30.6.7/26, add the following:

    template<typename F>
    auto shared_future::then(F&& func) -> future<decltype(func(*this))>;

    template<typename F>
    auto shared_future::then(executor &ex, F&& func) -> future<decltype(func(*this))>;

    template<typename F>
    auto shared_future::then(launch policy, F&& func) -> future<decltype(func(*this))>;

*Notes:* The three functions differ only by input parameters. The first
only takes a callable object which  accepts a `shared_future` object as a
parameter. The second function takes an `executor` as the first  parameter and a
callable object as the second parameter. The third function takes a launch
policy as the  first parameter and a callable object as the second parameter.

In cases where `decltype(func(*this))` is `future<R>`, the resulting type is
`future<R>` instead of  `future<future<R>>`.

*Effects:*

- The continuation is called when the object's shared state is ready (has a
value or exception stored).
- The continuation launches according to the specified policy or executor. 
- When the scheduler or launch policy is not provided the continuation
inherits the parent's launch policy or executor.
-  If the parent was created with `std::promise` (has no associated launch
policy), the continuation behaves the same as the third function with a policy
argument of `launch::async | launch::deferred` and the same argument for `func`.
-  If the parent has a policy of `launch::deferred` and the continuation does not
have a specified  launch policy or scheduler, then the parent is filled by
immediately calling `wait`, and the  policy of the antecedent is
`launch::deferred`

*Returns:* An object of type `future<decltype(func(*this))>` that refers to
the shared state created by the  continuation.

*Postcondition:* The `shared_future` passed to the continuation function is
a copy of the original `shared_future`

-  `valid() == true` on the original `shared_future` object

```
template<typename R2>
future<R2> shared_future<R>::unwrap();
```

*Requires:* `R` is a `future<R2>` or `shared_future<R2>`

*Notes:* Removes the outer-most `shared_future` and returns a proxy to the
inner future. The proxy is a representation of the inner future and it holds
the same value (or exception) as the inner future.

*Effects:*

-  `future<R2> X = shared_future<future<R2>>.unwrap()`, returns a `future<R2>`
that becomes  ready when the shared state of the inner future is ready. When the
inner future is ready, its  value (or exception) is moved to the shared state of
the returned future.

-  `future<R2> Y = shared_future<shared_future<R2>>.unwrap()`, returns a
`future<R2>` that  becomes ready when the shared state of the inner future is
ready. When the inner  `shared_future` is ready, its value (or exception) is
copied to the shared state of the returned  future.

-  If the outer future throws an exception, and `get()` is called on the returned
future, the  returned future throws the same exception as the outer future. This
is the case because the  inner future didn't exit.

*Returns:* A future of type `R2`. The result of the inner future is moved
out (`shared_future` is copied out)  and stored in the shared state of the
returned future when it is ready or the result of the inner future  throws an
exception.

*Postcondition:* The returned future has `valid() == true`, regardless of
the validity of the inner future.

    bool is_ready() const;

*Returns:* `true` if the shared state is ready, `false` if it isn't.

## 30.6.X Function template `when_all` # futures.when-all # futures.when-all

`template <class InputIterator>` \newline
_see below_ `when_all(InputIterator first, InputIterator last);`


`template <typename... T>` \newline
_see below_ `when_all(T&&... futures);`

*Requires:* `T` is of type `future<R>` or `shared_future<R>`.

*Notes:*

-  There are two variations of `when_all`. The first version takes a pair of
`InputIterators`. The  second takes any arbitrary number of `future<R0>` and
`shared_future<R1>` objects, where `R0`  and `R1` need not be the same type.

-  Calling the first signature of `when_all` where `InputIterator` first
equals last,  returns a future with an empty vector that is immediately
ready.

-  Calling the second signature of `when_any` with no arguments returns a
`future<tuple<>>` that is  immediately ready.

*Effects:*

-  Each `future` and `shared_future` is waited upon and then copied into the
collection of the  output (returned) future, maintaining the order of the
futures in the input collection.

-  The future returned by `when_all` will not throw an exception, but the
futures held in the output  collection may.

*Returns:*

-  `future<tuple<>>` if `when_all` is called with zero arguments. 

-  `future<vector<future<R>>>` if the input cardinality is unknown at compile
and the iterator pair  yields `future<R>`. `R` may be `void`. The order of the
futures in the output vector will be the same  as given by the input iterator.

-  `future<vector<shared_future<R>>>` if the input cardinality is unknown at
compile time and  the iterator pair yields `shared_future<R>`. `R` may be
`void`. The order of the futures in the output  vector will be the same as given
by the input iterator.

-  `future<tuple<future<R0>, future<R1>, future<R2>...>>` if inputs are fixed in
number. The  inputs can be any arbitrary number of `future` and `shared_future`
objects. The type of the  element at each position of the tuple corresponds to
the type of the argument at the same  position. Any of `R0`, `R1`, `R2`, etc.
may be `void`.

*Postconditions:*

-  All input `future<T>`s `valid() == false`
-  All output `shared_future<T>` `valid() == true`

## 30.6.X Function template `when_any` # futures.when_any # futures.when-any

`template <class InputIterator>` \newline
_see below_ `when_any(InputIterator first, InputIterator last);`


`template <typename... T>` \newline
_see below_ `when_any(T&&... futures);`

*Requires:* `T` is of type `future<R>` or `shared_future<R>`.

*Notes:*

-  There are two variations of `when_any`. The first version takes a pair of
`InputIterators`. The  second takes any arbitrary number of `future<R>` and
`shared_future<R>` objects, where `R` need  not be the same type.

-  Calling the first signature of `when_any` where `InputIterator` first
equals last,  returns a future with an empty vector that is immediately
ready.

-  Calling the second signature of `when_any` with no arguments returns a
`future<tuple<>>` that is  immediately ready.

*Effects:*

-  Each `future` and `shared_future` is waited upon. When at least one is ready,
all the futures are  copied into the collection of the output (returned) future,
maintaining the order of the futures  in the input collection.

-  The future returned by `when_any` will not throw an exception, but the
futures held in the  output collection may.

*Returns:*

-  `future<tuple<>>` if `when_any` is called with zero arguments. 

-  `future<vector<future<R>>>` if the input cardinality is unknown at compile
time and the  iterator pair yields `future<R>`. `R` may be void. The order of
the futures in the output vector will  be the same as given by the input
iterator.

-  `future<vector<shared_future<R>>>` if the input cardinality is unknown at
compile time and  the iterator pair yields `shared_future<R>`. `R` may be
`void`. The order of the futures in the output  vector will be the same as given
by the input iterator.

-  `future<tuple<future<R0>, future<R1>, future<R2>...>>` if inputs are fixed in
number. The  inputs can be any arbitrary number of `future` and `shared_future`
objects. The type of the  element at each position of the tuple corresponds to
the type of the argument at the same  position. Any of `R0`, `R1`, `R2`, etc.
maybe `void`.

*Postconditions:*

-  All input `future<T>`s `valid() == false`

-  All input `shared_future<T> valid() == true`

## 30.6.X Function template `when_any_swapped` # futures.when_any_swapped # futures.when-any-swapped

`template <class InputIterator>` \newline
_see below_ `when_any_swapped(InputIterator first, InputIterator last);`

*Requires:* `InputIterator`'s value type shall be convertible to `future<R>`
or `shared_future<R>`. All `R` types  must be the same.

*Notes:*

-  The function `when_any_swapped` takes a pair of `InputIterators`.

-  Calling `when_any_swapped` where `InputIterator` first equals
last, returns a `future` with an empty vector that is immediately ready.

*Effects:*

-  Each `future` and `shared_future` is waited upon. When at least one is ready,
all the futures are  copied into the collection of the output (returned)
`future`.

-  After the copy, the `future` or `shared_future` that was first detected as
being ready swaps its  position with that of the last element of the result
collection, so that the ready `future` or `shared_future` may be identified in
constant time. Only one `future` or `shared_future` is thus  moved.

-  The `future` returned by `when_any_swapped` will not throw an exception, but
the futures held in  the output collection may.

*Returns:*

-  `future<vector<future<R>>>` if the input cardinality is unknown at compile
time and the  iterator pair yields `future<R>`. `R` may be `void`.
-  `future<vector<shared_future<R>>>` if the input cardinality is unknown at
compile time and  the iterator pair yields `shared_future<R>`. `R` may be
`void`.

*Postconditions:*

-  All input `future<T>`s `valid() == false`
-  All input `shared_future<T> valid() == true`

## 30.6.X Function template `make_ready_future` # futures.make_ready_future # futures.make-ready-future

<!-- TODO: make it work with references -->

    template <typename T>
    future<typename decay<T>::type> make_ready_future(T&& value);

    future<void> make_ready_future();

*Effects:* The value that is passed in to the function is moved to the shared state of the returned future if it 
is an rvalue. Otherwise the value is copied to the shared state of the returned future.

*Returns:*

-  `future<T>`, if function is given a value of type `T`

-  `future<void>`, if the function is not given any inputs. 

*Postcondition:*

-  Returned `future<T>, valid() == true`

-  Returned `future<T>, is_ready() == true`

## 30.6.8 Function template `async` # futures.async # futures.async

Change 30.6.8/1 as follows:

The function template `async` provides a mechanism to launch a function
potentially in a new thread  and provides the result of the function in a future
object with which it shares a shared state.

    template <class F, class... Args>
    future<typename result_of<typename decay<F>::type(typename decay<Args>::type...)>::type>
    async(F&& f, Args&&... args);

    template <class F, class... Args>
    future<typename result_of<typename decay<F>::type(typename decay<Args>::type...)>::type>
    async(launch policy, F&& f, Args&&... args);

    template<class F, class... Args>
    future<typename result_of<typename decay<F>::type(typename decay<Args>::type...)>::type>
    async(executor& ex, F&& f, Args&&... args);


Change 30.6.8/3 as follows:

*Effects:* The first function behaves the same as a call to the second
function with a policy argument of  `launch::async | launch::deferred` and the
same arguments for `F` and `Args`. The second and third functions creates a
shared state that is associated with the returned future object. The further
behavior of the second  function depends on the policy argument as follows (if
more than one of these conditions applies, the  implementation may choose any of
the corresponding policies):

-  if `policy & launch::async` is non-zero - calls
`INVOKE (DECAY_COPY (std::forward<F>(f))`, `DECAY_COPY (std::forward<Args>(args))...)`
(20.8.2, 30.3.1.2) as if in a new thread of execution  represented by a thread object
with the calls to `DECAY_COPY ()` being evaluated in the thread  that called
`async`. Any return value is stored as the result in the shared state. Any
exception  propagated from the execution of 
`INVOKE (DECAY_COPY (std::forward<F>(f)), DECAY_COPY (std::forward<Args>(args))...)`
is stored as the exceptional result in the shared state. The thread object is stored in the
shared state and affects the behavior of any asynchronous return objects  that
reference that state.

-  if `policy & launch::deferred` is non-zero - Stores `DECAY_COPY(std::forward<F>(f))`
and `DECAY_COPY  (std::forward<Args>(args))...` in the
shared state. These copies of `f` and `args` constitute a deferred  function.
Invocation of the deferred function evaluates 
`INVOKE std::move(g), std::move(xyz))` where `g` is  the stored value of 
`DECAY_COPY (std::forward<F>(f))` and `xyz` is the stored copy of 
`DECAY_COPY (std::forward<Args>(args))...`. The shared state is not made ready until the
function has completed. The  first call to a non-timed waiting function (30.6.4)
on an asynchronous return object referring to this  shared state shall invoke
the deferred function in the thread that called the waiting function. Once
evaluation of `INVOKE (std::move(g), std::move(xyz))` begins, the function is no
longer considered  deferred. [*Note:* If this policy is specified together with
other policies, such as when using a policy value  of 
`launch::async | launch::deferred`, implementations should defer invocation or the selection of
the  policy when no more concurrency can be effectively exploited. -- *end
note*]

The further behavior of the third function is as follows:

The `executor::add()` function is given a `function<void ()>` which calls
`INVOKE (DECAY_COPY  (std::forward<F>(f)) DECAY_COPY
(std::forward<Args>(args))...)`. The implementation of the executor  is decided
by the programmer.

Change 30.6.8/8 as follows:

*Remarks:* The first signature shall not participate in overload resolution
if `decay<F>::type` is `std::launch` or is derived from `std::executor`.

\newpage
