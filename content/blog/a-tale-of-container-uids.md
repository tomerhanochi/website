+++
title = "A Tale of Container UIDs"
date = "2025-01-31"
description = "A deep dive into what decides the UID of a file on the host created by a container."
toc = true
+++

## Problem
If a process running inside a container as UID 1000 creates a file, what UID will be shown as the file's owner when viewed from outside the container?

### Example
Assume we have the following Containerfile:
```docker
FROM debian:bookworm

RUN useradd --uid 1000 nonroot

USER nonroot
```
And then I run the following commands:
```shell
podman build . -t debian:bookworm-nonroot
podman run --volume /tmp:/tmp debian:bookworm-nonroot touch /tmp/x
```
What will be shown as the owner UID when running the following command?
```shell
ls -la /tmp/x
```

## Background
Before discussing the solution to this particular problem, I want to ensure that you have the all the prerequisite knowledge used in the answer.

If you feel like you already understand the subjects discussed in the following sections, you can skip to the [Solution](#solution).

### Containers
> Linux Containers have emerged as a key open source application packaging and delivery technology, combining lightweight application isolation with the flexibility of image-based deployment methods.
>
> Several components are needed for Linux Containers to function correctly, most of them are provided by the Linux kernel. Kernel namespaces ensure process isolation and cgroups are employed to control the system resources.
>
> <cite>- Overview of Containers in Red Hat Systems: Chapter 1. Introduction to Linux Containers[^1]</cite>

This is a high level overview of containers. For our purposes, we need to treat containers a little bit differently.

In our eyes, containers are simply processes. These processes are then isolated from each other, and from the host, using linux namespaces

### Linux Namespaces
> A namespace wraps a global system resource in an abstraction that makes it appear to the processes within the namespace that they have their own isolated instance of the global resource.
> 
> <cite>- namespaces(7) - Linux Man Pages[^2]</cite>

Linux namespaces are isolation mechanisms used to isolate processes from certain resources accessible through the linux kernel.

There are a several namespace types, but of particualr importance to containers are:
* PID namespaces
* Mount namespaces
* Network namespaces
* User namespaces

This post, as foreshadowed by the [Problem](#problem), is going to discuss the [User Namespace](#user-namespace).

### User Namespace
> User namespaces isolate security-related identifiers and attributes, in particular, user IDs and group IDs, the root directory, keys, and capabilities.<br>
> 
> <cite>- user_namespaces(7) - Linux Man Pages[^3]</cite>

Processes within a user namespace are unaware of the <mark>UID</mark>s/<mark>GID</mark>s used on the host. What does a <mark>UID</mark>/<mark>GID</mark> within a user namespace look like to an outside observer?

An important addition is made in the next paragraph:
> A process's user and group IDs can be different inside and outside a user namespace.  In particular, a process can have a normal unprivileged user ID outside a user namespace while at the same time having a user ID of 0 inside the namespace.<br>
> 
> <cite>- user_namespaces(7) - Linux Man Pages[^3]</cite>

If <mark>UID</mark>s/<mark>GID</mark>s inside and outside a user namespace don't have to match, what is the relationship between them?

### UID and GID Mapping
<mark>UID</mark>/<mark>GID</mark> mapping is the act of mapping <mark>UID</mark>s/<mark>GID</mark>s within a user namespace to UIDs/GIDS outside of it.

By default, processes within a user namespace use the identity mapping, meaning a <mark>UID</mark>/<mark>GID</mark> inside the namespace is equivalent to the same <mark>UID</mark>/<mark>GID</mark> on the host.
| Namespace UID | Host UID |
| ------------- | -------- |
| 0             | 0        |
| 1             | 1        |
| 2             | 2        |
| . . .         | . . .    |

In this case, if a process running under a user with UID 2, using the above <mark>uid_map</mark>, creates a file, a user outside the namespace will see the file as owned by UID 2.

However, you don't have to use the default mapping. <mark>UID</mark>/<mark>GID</mark> mappings can be modified through the files <mark>/proc/\<pid\>/uid_map</mark> and <mark>/proc/\<pid\>/gid_map</mark>.

In these files, each line is of the following format:
```plaintext
<starting-namespace-uid/gid> <starting-host-uid/gid> <count>
```
Each line gives a range of consecutive <mark>UID</mark>s/<mark>GID</mark>s to map from within the namespace to the host. For example, the following <mark>uid_map</mark>:
```plaintext
0 1000 3
```

Results in the following mapping between UIDs in the namespace to the host:

| Namespace UID | Host UID |
| ------------- | -------- |
| 0             | 1000     |
| 1             | 1001     |
| 2             | 1002     |

In this case, if a process running under a user with UID 2, using the above <mark>uid_map</mark>, creates a file, a user outside the namespace will see the file as owned by UID 1002.

Any <mark>UID</mark>/<mark>GID</mark> not found in the <mark>uid_map</mark>/<mark>gid_map</mark> files, uses the deafult identity mapping. For example, in the same namespace, if a process run by a user with UID 3 creates a file, then a user outside the namespace will see it is owned by UID 3, not 1003, since it was not mapped.

#### Permissions
Not every process can modify another process's <mark>uid_map</mark>/<mark>gid_map</mark>, or even its own; several restrictions apply, which are outlined below:

> One of the following two cases applies: <br>
> 1.  Either the writing process has the <mark>CAP_SETUID</mark>/<mark>CAP_SETUID</mark> capability in the parent user namespace.<br>
>      *  No further restrictions apply: the process can make mappings to arbitrary user IDs (group IDs) in the parent user namespace.<br>
> 2.  Or otherwise all of the following restrictions apply:<br>
>      *  The data written to <mark>uid_map</mark>/<mark>gid_map</mark> must consist of a single line that maps the writing process's effective <mark>UID</mark>/<mark>GID</mark> in the parent user namespace to a <mark>UID</mark>/<mark>GID</mark> in the user namespace.<br>
>      *  The writing process must have the same effective UID as the process that created the user namespace.<br>
> 
> <cite>user_namespaces(7) - Linux Man Pages[^3]</cite>

Let's break it down:

> Either the writing process has the <mark>CAP_SETUID</mark>/<mark>CAP_SETGID</mark> capability in the parent user namespace.

<mark>CAP_SETUID</mark>/<mark>CAP_SETGID</mark> are capablities[^4] that give a process the ability to modify another process's <mark>uid_map</mark>/<mark>gid_map</mark>. So any process that has the <mark>CAP_SETUID</mark>/<mark>CAP_SETGID</mark> capability, can modify any other process's <mark>uid_map</mark>/<mark>gid_map</mark> so long as that other process is within his user namespace.

If the process doesn't have those capabilities, all of the following restrictions must apply:
> The data written to <mark>uid_map</mark>/<mark>gid_map</mark> must consist of a single line that maps the writing process's effective <mark>UID</mark>/<mark>GID</mark> in the parent user namespace to a <mark>UID</mark>/<mark>GID</mark> in the user namespace.

```plaintext
<child-namespace-uid> <parent-namespace-uid> 1
```
The above is the only valid value that can be written to a process's <mark>uid_map</mark>. It means that we can only map our current UID to some UID inside the namespace, and that's it.

> The writing process must have the same effective UID as the process that created the user namespace.

If I don't have the required capabilties, I can only modify a process's <mark>uid_map</mark>/<mark>gid_map</mark> with the above values if I was the one that created its namespace.

### SubUIDs and SubGIDs
Due to these heavy restrictions, and the need to avoid vulnerabilities by ensuring that every <mark>UID</mark>/<mark>GID</mark> in the namespace is mapped to a non-root <mark>UID</mark>/<mark>GID</mark>, container engines like podman came up with a mechanism called <mark>SubUID</mark>s/<mark>SubGID</mark>s.

<mark>SubUID</mark>s/<mark>SubGID</mark>s allow for the system administrator to delegate <mark>UID</mark>/<mark>GID</mark> ranges to a non-root user. This enables the non-root user to map more than 1 <mark>UID</mark>/<mark>GID</mark> from the namespace, even though they don't have the <mark>CAP_SETUID</mark>/<mark>CAP_SETGID</mark> capabilities.

These are configured using the files <mark>/etc/subuid</mark> and <mark>/etc/subgid</mark>, in which each line has the following format:
```plaintext
<username>:<starting-uid/gid>:<count>
```
This allows <mark>\<username\></mark> to create a container process with the following <mark>uid_map</mark>/<mark>gid_map</mark>.
```plaintext
0 <starting-uid/gid> <count>
```

For example, the following /etc/subuid:
```plaintext
tomerh:100000:65536
```
Allows <mark>tomerh</mark> to create a container process with the following <mark>uid_map</mark>:
```plaintext
0 100000 65536
```

However, if you'll recall, in the [Permissions](#permissions) section, I said that unless we have the <mark>CAP_SETUID</mark>/<mark>CAP_SETGID</mark> capabilities, we can only map ourselves into the namespace. We certainly don't have <mark>CAP_SETUID</mark>/<mark>CAP_SETGID</mark>, so what gives? How can we suddenly map 65536 users into the namespace?

Well, **we** can't do that, but **container engines** can, due to a little trick called file capabilities.

Container engines utilize 2 binaries called <mark>newuidmap</mark>/<mark>newgidmap</mark>, that  have the <mark>CAP_SETUID</mark>/<mark>CAP_SETGID</mark> capabilities. These binaries read <mark>/etc/subuid</mark> and <mark>/etc/subgid</mark>, verify that you have enough <mark>UID</mark>s/<mark>GID</mark>s to map all of the <mark>UID</mark>s/<mark>GID</mark>s inside the container, and modify the container process's <mark>uid_map</mark>/<mark>gid_map</mark>.


## Solution
Now that we covered the background required, we can dive into the solution. Similar to the [Permissions](#permissions) section, the solution is split into 2.

### Rootful Containers
For rootful containers(containers started by the root user), since the root user possesses all capabilities, including <mark>CAP_SETUID</mark>/<mark>CAP_SETGID</mark>, they can configure any <mark>UID</mark>/<mark>GID</mark> mapping they please, including the default identity mapping.

The solution depends on the options specified when starting the container. By default, the identity mapping is used, meaning the <mark>UID</mark>/<mark>GID</mark> inside the container matches the <mark>UID</mark>/<mark>GID</mark> outside. However, since you are root and have full control, you can configure any other mapping as wanted.

### Rootless Containers
For rootless containers(containers run by a non-root user) the solution is a bit more involved since we don't have the <mark>CAP_SETUID</mark>/<mark>CAP_SETGID</mark>.

The solution depends on the options specified when starting the container, and the <mark>SubUID</mark>s/<mark>SubGID</mark>s configured by the system administrator for the user. By default, a one to one mapping is used, where the first <mark>UID</mark>/<mark>GID</mark> inside the container corresponds to the first <mark>SubUID</mark>/<mark>SubGID</mark>, and so on. However, you can configure any mapping you prefer, as long as each <mark>UID</mark>/<mark>GID</mark> inside the container is mapped to some <mark>SubUID</mark>/<mark>SubGID</mark>.

[^1]: https://docs.redhat.com/en/documentation/red_hat_enterprise_linux_atomic_host/7/html/overview_of_containers_in_red_hat_systems/introduction_to_linux_containers#overview
[^2]: https://man7.org/linux/man-pages/man7/namespaces.7.html
[^3]: https://man7.org/linux/man-pages/man7/user_namespaces.7.html
[^4]: https://man7.org/linux/man-pages/man7/capabilities.7.html
