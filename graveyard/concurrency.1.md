# Executors and Schedulers # exec # exec

## General # exec.general # exec.general

This proposal includes two abstract base classes, `executor` and
`scheduled_executor` (the latter of which inherits from the former); several
concrete classes that inherit from `executor` or `scheduled_executor`; and
several utility functions.

Executors library summary

+--------------------------------------------+------------------------------+
| Subclause                                  | Header(s)                    |
+--------------------------------------------+------------------------------+
| V.1 [executors.base]                       | `<executor>`                 |
+--------------------------------------------+------------------------------+
| V.2 [executors.classes]                    |                              |
+--------------------------------------------+------------------------------+
|   V.2.1 [executors.classes.thread_pool]    | `<thread_pool>`              |
+--------------------------------------------+------------------------------+
|   V.2.2 [executors.classes.serial]         | `<serial_executor>`          |
+--------------------------------------------+------------------------------+
|   V.2.3 [executors.classes.loop]           | `<loop_executor>`            |
+--------------------------------------------+------------------------------+
|   V.2.4 [executors.classes.inline]         | `<inline_executor>`          |
+--------------------------------------------+------------------------------+
|   V.2.5 [executors.classes.thread]         | `<thread_executor>`          |
+--------------------------------------------+------------------------------+

## V.1 Executor base classes # executors.base # executors.base

The `<executor>` header defines abstract base classes for executors, as well as
non-member functions that operate at the level of those abstract base classes.

Header `<executor>` synopsis

    class executor;
    class scheduled_executor;

### V.1.1 Class executor # executors.base.executor # executors.base.executor

Class `executor` is an abstract base class defining an abstract interface of
objects that are capable of scheduling and coordinating work submitted by
clients. Work units submitted to an executor may be executed in one or more
separate threads. Implementations are required to avoid data races when work
units are submitted concurrently.

All closures are defined to execute on some thread, but which thread is largely
unspecified. As such accessing a `thread_local` variable is defined behavior,
though it is unspecified which thread's `thread_local` will be accessed.

The initiation of a work unit is not necessarily ordered with respect to other
initiations. [*Note:* Concrete executors may, and often do, provide stronger
initiation order guarantees. Users may, for example, obtain serial execution
guarantees by using the `serial_executor` wrapper.-- *end note*] There is no
defined ordering of the execution or completion of closures added to the
executor. [*Note:* The consequence is that closures should not wait on other
closures executed by that executor. Mutual exclusion for critical sections is
fine, but it can't be used for signalling between closures. Concrete executors
may provide stronger execution order guarantees.-- *end note*]


    class executor {
    public:
        virtual ~executor();
        virtual void add(function<void()> closure) =0;
        virtual size_t uninitiated_task_count() const =0;
    };


    executor::~executor()

*Effects:* Destroys the executor.

*Synchronization:* All closure initiations happen before the completion of the
executor destructor. [*Note:* This means that closure initiations don't leak
past the executor lifetime, and programmers can protect against data races with
the destruction of the environment. There is no guarantee that all closures that
have been added to the executor will execute, only that if a closure executes it
will be initiated before the destructor executes. In some concrete subclasses
the destructor may wait for task completion and in others the destructor may
discard uninitiated tasks. -- *end note*]

*Remark:* If an executor is destroyed inside a closure running on that executor
object, the behavior is undefined. [*Note:* one possible behavior is deadlock.
-- *end note*]

    void executor::add(std::function<void> closure);

*Effects:* The specified function object shall be scheduled for execution by the
executor at some point in the future. May throw exceptions if add cannot
complete (due to shutdown or other conditions).

*Synchronization:* completion of closure on a particular thread happens before
destruction of that thread's thread-duration variables. [*Note:* The consequence
is that closures may use thread-duration variables, but in general such use is
risky. In general executors don't make guarantees about which thread an
individual closure executes in. -- *end note*]

*Error conditions:* The invoked closure should not throw an exception.

    size_t executor::uninitiated_task_count();

Returns: the number of function objects waiting to be executed. [*Note:* this is
intended for logging/debugging and for coarse load balancing decisions. Other
uses are inherently risky because other threads may be executing or adding
closures.-- *end note*]

### V.1.2 Class `scheduled_executor` # executors.base.scheduled_executor # executors.base.scheduled-executor

Class `scheduled_executor` is an abstract base class that extends the executor
interface by allowing clients to pass in work items that will be executed some
time in the future.

    class scheduled_executor : public executor {
    public:
        virtual void add_at(const chrono::system_clock::time_point& abs_time,
                            function<void()> closure) = 0;
        virtual void add_after(const chrono::system_clock::duration& rel_time,
                               function<void()> closure) = 0;
    };

    void add_at(const chrono::system_clock::time_point& abs_time,
     function<void()> closure);

*Effects:* The specified function object shall be scheduled for execution by the executor at
some point in the future no sooner than the time represented by `abs_time`.

*Synchronization:* completion of closure on a particular thread happens before
destruction of that thread's thread-duration variables.

*Error conditions:* The invoked closure should not throw an exception.

    void add_after(const chrono::system_clock::duration& rel_time, function<void()> closure);

*Effects:* The specified function object shall be scheduled for execution by the
executor at some point in the future no sooner than time `rel_time` from now.

*Synchronization:* completion of closure on a particular thread happens before
destruction of that thread's thread-duration variables.

*Error conditions:* The invoked closure should not throw an exception.

## V.2 Concrete executor classes # executors.classes # executors.classes

This section defines executor classes that encapsulate a variety of closure-
execution policies.

### V.2.1 Class `thread_pool` # executors.classes.thread_pool # executors.classes.thread-pool

Header `<thread_pool>` synopsis

    class thread_pool;

Class `thread_pool` is a simple thread pool class that creates a fixed number of
threads in its constructor and that multiplexes closures onto them.

    class thread_pool : public scheduled_executor {
       public:
       explicit thread_pool(int num_threads);
       ~thread_pool();
       // [executor methods omitted]
    };


    thread_pool::thread_pool(int num_threads)

*Effects:* Creates an executor that runs closures on `num_threads` threads.

*Throws:* `system_error` if the threads can't be created and `started.thread_pool::~thread_pool()`

    thread_pool::~thread_pool()

*Effects:* Waits for closures (if any) to complete, then joins and destroys the threads.

### V.2.2 Class `serial_executor` # executors.classes.serial # executors.classes.serial

Header `<serial_executor>` synopsis

    class serial_executor;


Class `serial_executor` is an adaptor that runs its closures by scheduling them
on another (not necessarily single-threaded) executor. It runs added closures
inside a series of closures added to an underlying executor in such a way so
that the closures execute serially. For any two closures `c1` and `c2` added to
a `serial_executor` `e`, either the completion of `c1` happens before (1.10
[intro.multithread]) the execution of `c2` begins, or vice versa. If `e.add(c1)`
happens before `e.add(c2)`, then `c1` is executed before `c2`.

The number of `add()` calls on the underlying executor is unspecified, and if
the underlying executor guarantees an ordering on its closures, that ordering
won't necessarily extend to closures added through a `serial_executor`. [*Note:*
this is because serial_executor can batch add() calls to the underlying
executor. -- *end note*]

    class serial_executor : public executor {
    public
        explicit serial_executor(executor& underlying_executor);
        virtual ~serial_executor();
        executor& underlying_executor();
        // [executor methods omitted]
    };

    serial_executor::serial_executor(executor& underlying_executor)

*Requires:* `underlying_executor` shall not be null.

*Effects:* Creates a `serial_executor` that executes closures in FIFO order by
passing them to `underlying_executor`. [*Note:* several `serial_executor` objects
may share a single underlying executor. -- *end note*]

    serial_executor::~serial_executor()

*Effects:* Finishes running any currently executing closure, then destroys all remaining
closures and returns. If a `serial_executor` is destroyed inside a closure running on
that `serial_executor` object, the behavior is undefined. [*Note:* one possible behavior
is deadlock. -- *end note*]

    executor& serial_executor::underlying_executor()

*Returns:* The underlying executor that was passed to the constructor.

## V.2.3 Class loop_executor # executors.classes.loop # executors.classes.loop

Header `<loop_executor>` synopsis

    class loop_executor;

Class `loop_executor` is a single-threaded executor that executes closures by
taking control of a host thread. Closures are executed via one of three closure-
executing methods: `loop()`, `run_queued_closures()`, and
`try_run_one_closure()`. Closures are executed in FIFO order. Closure-executing
methods may not be called concurrently with each other, but may be called
concurrently with other member functions.

    class loop_executor : public executor {
    public:
        loop_executor();
        virtual ~loop_executor();
        void loop();
        void run_queued_closures();
        bool try_run_one_closure();
        void make_loop_exit();
        // [executor methods omitted]
    };

    loop_executor::loop_executor()

*Effects:* Creates a `loop_executor` object. Does not spawn any threads.

    loop_executor::~loop_executor()

*Effects:* Destroys the `loop_executor` object. Any closures that haven't been
executed by a closure-executing method when the destructor runs will never be
executed. 

*Synchronization:* Must not be called concurrently with any of the
closure-executing methods.

    void loop_executor::loop()

*Effects:* Runs closures on the current thread until `make_loop_exit()` is called.

*Requires:* No closure-executing method is currently running.

    void loop_executor::run_queued_closures()

*Effects:* Runs closures that were already queued for execution when this
function was called, returning either when all of them have been executed or
when `make_loop_exit()` is called. Does not execute any additional closures that
have been added after this function is called. Invoking `make_loop_exit()` from
within a closure run by `run_queued_closures()` does not affect the behavior of
subsequent closure-executing methods.
    [*Note:* this requirement disallows an implementation like

        void run_queued_closures() {
            add([](){make_loop_exit();});
            loop(); 
        }

because that would cause early exit from a subsequent invocation of `loop()`. --
*end note*]

*Requires:* No closure-executing method is currently running.

*Remarks:* This function is primarily intended for testing.

    bool loop_executor::try_run_one_closure()

*Effects:* If at least one closure is queued, this method executes the next
closure and returns.

*Returns:* `true` if a closure was run, otherwise `false`.

*Requires:* No closure-executing method is currently running.

*Remarks:* This function is primarily intended for testing.

    void loop_executor::make_loop_exit()

*Effects:* Causes `loop()` or `run_queued_closures()` to finish executing
closures and return as soon as the current closure has finished. There is no
effect if `loop()` or `run_queued_closures()` isn't currently executing.
[*Note:* `make_loop_exit()` is typically called from a closure. After a closure-
executing method has returned, it is legal to call another closure-executing
function. -- *end note*]

## V.2.4 Class inline_executor # executors.classes.inline # executors.classes.inline

Header `<inline_executor>` synopsis

    class inline_executor;

Class `inline_executor` is a simple executor which intrinsically only provides the `add()`
interface as it provides no queuing and instead immediately executes work on the calling thread.
This is effectively an adapter over the executor interface but keeps everything on the caller's
context.

    class inline_executor : public executor {
    public
        explicit inline_executor();
        // [executor methods omitted]
    };

    inline_executor::inline_executor()

*Effects:* Creates a dummy executor object which only responds to the `add()`
call by immediately executing the provided function in the caller's thread.

## V.2.5 Class thread_executor # executors.classes.thread # executors.classes.thread

Header `<thread_executor>` synopsis

    class thread_executor;

Class `thread_executor` is a simple executor that executes each task (closure)
on its own `std::thread` instance.

    class thread_executor : public executor {
    public:
        explicit thread_executor();
        ~thread_executor();
        // [executor methods omitted]
    };


    thread_executor::thread_executor()

*Effects:* Creates an executor that runs each closure on a separate thread.

    thread_executor::~thread_executor()

*Effects:* Waits for all added closures (if any) to complete, then joins and
destroys the threads.


\newpage
