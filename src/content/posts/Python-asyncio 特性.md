---
title: 「Python」asyncio 特性
published: 2026-09-02
updated: 2026-09-02
description: 'asyncio 特性笔记'
image: ''
tags: [Python, 开发, 笔记]
category: '技术'
draft: false
lang: 'zh_CN'
---

## 简介

asyncio 正如其名，是 python 用于**异步编程**的库，比较适合用于处理耗时的 I/O 操作，最典型的就是网络通讯、文件读写等。

在传统的同步编程中，当程序遇到 I/O 操作时，线程会阻塞等待结果返回，这段时间 CPU 处于空闲状态。

asyncio 的核心价值在于**在单线程内实现并发**，让程序在等待 I/O 时去执行其他任务，从而大幅提升 I/O 操作较密集的应用的效率。

注意：asyncio 代码本质上还是**单进程单线程**程序，它并不能提升你的运算速度，去同时执行不同任务的若干语句，而是在处理一些需要等待的任务时，利用这个等待的时间去做其它的任务，实现相对并发的效果。

## 举例

以下是一个示例 python 程序，这个程序中，编写了网页抓取、文件读取的两个模拟操作，其中手动设置了延迟，模拟了实际操作中产生的等待。

```py
import time

def fetch_URL(url):
    print(f"Fetching {url}...")
    time.sleep(1) # Simulate a network delay
    print(f"Done fetching {url}")

def read_data(path):
    print(f"Reading {path}...")
    time.sleep(2) # Simulate a file read delay
    print(f"Done reading {path}")

def main():
    print(f"Start at {time.strftime('%X')}")
    fetch_URL("example.com")
    read_data("./example.txt")
    print(f"End at {time.strftime('%X')}")

if __name__ == "__main__":
    main()

"""
运行这个程序会返回这样的结果：
Start at 00:03:34
Fetching example.com...
Done fetching example.com
Reading ./example.txt...
Done reading ./example.txt
End at 00:03:37
"""

```

可以看到，运行该程序，时间过去了 3 秒钟，这是符合预期的，但是显然这样的程序不够优秀，在处理大量此类任务时，如果我们都需要一个一个去等，让 CPU 挂在那没事干，那就太浪费了。

下面是一种更好的实现方式：

```py
import time
import asyncio

async def fetch_URL(url):
    print(f"Fetching {url}...")
    await asyncio.sleep(1) # Simulate a network delay
    print(f"Done fetching {url}")

async def read_data(path):
    print(f"Reading {path}...")
    await asyncio.sleep(2) # Simulate a file read delay
    print(f"Done reading {path}")

async def main():
    print(f"Start at {time.strftime('%X')}")
    tasks = [
        fetch_URL("example.com"),
        read_data("./example.txt"),
    ]
    await asyncio.gather(*tasks)
    print(f"End at {time.strftime('%X')}")

if __name__ == "__main__":
    asyncio.run(main())

"""
运行这个程序会返回这样的结果：
Start at 00:04:12
Fetching example.com...
Done fetching example.com
Reading ./example.txt...
Done reading ./example.txt
End at 00:04:14
"""
```

这样，程序仅运行了两秒就完成了任务。实际上，类似“长板效应”，在处理多个这样的任务时，使用 asyncio 来处理所花的时间与耗时最久的任务时间相近。这样就大大节约了时间，相较之前效率有了质的提升。

## 概念与原理

想要理解 asyncio，则必须要理解几个概念。

### 1. 协程（Coroutine）

协程是 asyncio 的基本执行单元，一般使用 async def 定义。

```py
import asyncio
async def hello():
    print("Hello")
    await asyncio.sleep(1)  # 模拟异步等待
    print("World")

coro = hello() # 这里只是创建了一个协程对象，不会打印任何内容
```

像这样用 async def 定义的函数就是一个**协程函数（Coroutine Function）**。

与一般函数不同的是，当我们调用一个函数时，其会先执行函数中的语句，然后返回该函数的返回值。但**协程函数**的不一样，它并不会运行函数中的程序，而是只会返回一个**协程对象（Coroutine Object）**。像上面的程序就不会真的输出 `Hello World`。

如果我们想要执行一个协程函数，就需要进入到异步模式，我们用一个入口函数即可实现，叫做 asyncio.run，其参数是一个**协程对象**。例如在上面的代码中补充 `asyncio.run(coro)` 即可正常执行。

### 2. 事件循环（Event Loop）

**事件循环**是 asyncio 的核心，负责调度协程的执行、管理回调、处理 I/O 事件等。

简单来说，它会依次接受很多不同的**任务**，然后决定此刻该执行哪段代码。它通过不断轮询“哪些任务已就绪可以执行、哪些 I/O 可以等待”来进行调度，当目前执行的任务挂起时，则会切换到另一个可执行的任务上，让代码在等待网络或磁盘时不浪费 CPU。

在上面 `asyncio.run(coro)` 中，其就完成了一次**事件循环**的自动创建、运行、关闭。

### 3. Task（任务）

**Task** 是对协程的封装，用于将协程并发地放入**事件循环**执行。

之前提到过，协程函数本身不能执行，要执行一个协程函数，需要把其变成一个 **Task**，然后丢到**事件循环**中去排队执行。

后面会具体地讲如何把一个协程变成 Task，以及怎么去执行 Task。

### 4. await 关键字

await 关键字是 asyncio 中非常重要的关键字，可以用于**挂起当前协程**，等待一个**可等待对象**完成。例如：

```py
async def fetch_URL(url):
    print(f"Fetching {url}...")
    await asyncio.sleep(1) # 模拟网络延迟，需要等待 1 秒，等待时挂起该协程
    print(f"Done fetching {url}")

async def main():
    print(f"Start at {time.strftime('%X')}")
    await fetch_URL("example.com") # 等待 fetch_URL 时挂起，其完成后才能继续
    print(f"End at {time.strftime('%X')}")

if __name__ == "__main__":
    asyncio.run(main())
```

具体来说，当一个协程函数中执行到 await，它会

1. 挂起当前协程；
2. 执行该可等待对象；
3. 获取可等待对象的返回结果（所以你也可以使用如 `reslut = await some_coro()` 的形式接收返回值）；
4. 将当前协程设置为可执行状态，让事件循环调度。

**可等待对象**包括：
- 另一个协程（`await some_coro()`）
- asyncio.Task 对象
- asyncio.Future 对象

当 await 的可等待对象是一个**协程**时，会自动将这个协程**包装成 Task** 然后让事件循环进行调度。当然如果其已经是一个 Task 了就不需要包装了。

另外需要注意的是，await 只能出现在协程函数中。

## 组建异步程序

### 基本流程

一个 asyncio 程序，其流程基本都是：构建**协程**函数 → 将协程**转化为 Task** → 将 Task **丢进事件循环**中执行。

除了之前提到的可以用 await 直接将协程转化为 Task，还有一种更直接的语法 `asyncio.create_task(some_coro())`，例如：

```py
async def fetch_URL(url):
    print(f"Fetching {url}...")
    await asyncio.sleep(1) # Simulate a network delay
    print(f"Done fetching {url}")
    return "url_content"

async def read_data(path):
    print(f"Reading {path}...")
    await asyncio.sleep(2) # Simulate a file read delay
    print(f"Done reading {path}")
    return "data_content"

async def main():
    task1 = asyncio.create_task(fetch_URL("example.com"))
    task2 = asyncio.create_task(read_data("./example.txt"))
    fetch_result = await task1
    read_result = await task2

if __name__ == "__main__":
    asyncio.run(main())
```

如果运行上面的程序并计时，可以发现用两秒就完成了，说明这已经使用 asyncio 组建了一个基本的异步程序了。

这里要注意一个坑点，可能有些人会想，既然 await 可以直接接收协程，那我们可以将 main 重写为这样：

```py
async def main():
    fetch_result = await fetch_URL("example.com")
    read_result = await read_data("./example.txt")
```

但实际上，如果你运行并计时，发现其会用三秒，和同步程序没有区别了。

这是因为，当使用 create_task 时，其协程被转化为 Task 时就已经开始执行了，即我们接连创建了 task1 和 task2，它们都会被放进了事件循环中开始接受调度，所以是并行，只需要两秒。这里 await 的作用只是等其执行完，接收返回结果即可。

可如果用后者的写法，那么它先会执行 `await fetch_URL("example.com")`，将 `fetch_URL` 转化为 Task，然后等其执行完，接收到返回结果后，才会再执行 `await read_data("./example.txt")`。所以这本质上是一个串行的过程，才需要三秒钟。

### 批量运行

刚刚我们用 `create_task` 手动创建任务，但如果有大批的协程函数需要执行，这个时候一个个手动创建就显得臃肿，所幸我们有专门的函数来处理这种情况，这里介绍两种，分别是 `asyncio.gather()` 和 `asyncio.as_completed()`

它们的用法比较相似，可以这样使用：

```py
async def coroutine1():
    ...
async def coroutine2():
    ...
async def coroutine3():
    ...

async def main():
    # gather
    results = await asyncio.gather(coroutine1(), coroutine2(), coroutine3())
    # as_completed
    results = await asyncio.as_completed(coroutine1(), coroutine2(), coroutine3())
```

这两个函数都可以接收若干个**协程**、**Task**，然后放入**事件循环**中接受调度。

区别在于，gather 的返回结果是一个列表，记录每个协程的返回值，其返回值顺序与填入的顺序一致。

而 as_completed 返回的是一个迭代器，会按**协程完成的顺序**依次生成已完成的协程，使用 await 即可获取已完成协程的返回值，如：

```py
async def main():
    results = await asyncio.as_completed(coroutine1(), coroutine2(), coroutine3())
    for result in results:
        print(await result)
```

as_completed 的特点是，它不会等所有协程都运行完才返回，而是**一有协程运行完就先返回一个结果**。而 gather 则必须**等待所有协程完成**后才统一返回结果。