+++
title = "A Tale of Container UIDs"
date = "2025-01-31"
toc = true
+++

## The Question
If a process running inside a container as user ID 1000 creates a file on a shared mount, what user ID will be shown as the file's owner when viewed from outside the container?

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
What will be shown as the owner user ID when running the following command?
```shell
ls -l /tmp/x
```

<!--more-->

## Background
Before discussing the solution to this particular problem, I want to ensure that you have the all the prerequisite knowledge used in the answer.

If you feel like you already understand the subjects discussed in the following sections, you can skip to the [Revisting The Question](#revisting-the-question) Section.

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

This post, as foreshadowed by the [The Question](#the-question), is going to discuss the [User Namespace](#user-namespace).

### User Namespace
> User namespaces isolate security-related identifiers and attributes, in particular, user IDs and group IDs, the root directory, keys, and capabilities.<br>
>
> <cite>- user_namespaces(7) - Linux Man Pages[^3]</cite>

Processes within a user namespace are unaware of the user IDs/group IDs used on the host. What does a user ID/group ID within a user namespace look like to an outside observer?

An important addition is made in the next paragraph:
> A process's user and group IDs can be different inside and outside a user namespace.  In particular, a process can have a normal unprivileged user ID outside a user namespace while at the same time having a user ID of 0 inside the namespace.<br>
>
> <cite>- user_namespaces(7) - Linux Man Pages[^3]</cite>

If user IDs/group IDs inside and outside a user namespace don't have to match, what is the relationship between them?

### uid_map and gid_map
user ID/group ID mapping is the act of mapping user IDs/group IDs within a user namespace to user IDs/group IDS outside of it.

By default, processes within a user namespace use the identity mapping, meaning a user ID/group ID inside the namespace is equivalent to the same user ID/group ID on the host.
| Namespace user ID | Host user ID |
| ------------- | -------- |
| 0             | 0        |
| 1             | 1        |
| 2             | 2        |
| . . .         | . . .    |

In this case, if a process running under a user with user ID 2, using the above <mark>uid_map</mark>, creates a file, a user outside the namespace will see the file as owned by user ID 2.

However, you don't have to use the default mapping. user ID/group ID mappings can be modified through the files <mark>/proc/\<pid\>/uid_map</mark> and <mark>/proc/\<pid\>/gid_map</mark>.

<a name="uid_map"></a>
In these files, each line is of the following format:
```plaintext
<starting-namespace-uid/gid> <starting-host-uid/gid> <count>
```
Each line gives a range of consecutive user IDs/group IDs to map from within the namespace to the host. For example, the following <mark>uid_map</mark>:
```plaintext
0 1000 3
```

Results in the following mapping between user IDs in the namespace to the host:

| Namespace UID | Host UID |
| ------------- | -------- |
| 0             | 1000     |
| 1             | 1001     |
| 2             | 1002     |

In this case, if a process running under a user with user ID 2, using the above <mark>uid_map</mark>, creates a file, a user outside the namespace will see the file as owned by user ID 1002.

Any user ID/group ID not found in the <mark>uid_map</mark>/<mark>gid_map</mark> files, uses the deafult identity mapping. For example, in the same namespace, if a process run by a user with user ID 3 creates a file, then a user outside the namespace will see it is owned by user ID 3, not 1003, since it was not mapped.

#### Permissions
Not every process can modify another process's <mark>uid_map</mark>/<mark>gid_map</mark>, or even its own; several restrictions apply, which are outlined below:

> One of the following two cases applies: <br>
> 1.  Either the writing process has the CAP_SETUID/CAP_SETGID capability in the parent user namespace.<br>
>      *  No further restrictions apply: the process can make mappings to arbitrary user IDs (group IDs) in the parent user namespace.<br>
> 2.  Or otherwise all of the following restrictions apply:<br>
>      *  The data written to <mark>uid_map</mark>/<mark>gid_map</mark> must consist of a single line that maps the writing process's effective user ID/group ID in the parent user namespace to a user ID/group ID in the user namespace.<br>
>      *  The writing process must have the same effective user ID as the process that created the user namespace.<br>
>
> <cite>user_namespaces(7) - Linux Man Pages[^3]</cite>

Let's break it down:

> Either the writing process has the CAP_SETUID/CAP_SETGID capability in the parent user namespace.

CAP_SETUID/CAP_SETGID are capablities[^4] that give a process the ability to modify another process's <mark>uid_map</mark>/<mark>gid_map</mark>. So any process that has the CAP_SETUID/CAP_SETGID capability, can modify any other process's <mark>uid_map</mark>/<mark>gid_map</mark> so long as that other process is within his user namespace.

If the process doesn't have those capabilities, all of the following restrictions must apply:
> The data written to <mark>uid_map</mark>/<mark>gid_map</mark> must consist of a single line that maps the writing process's effective user ID/group ID in the parent user namespace to a user ID/group ID in the user namespace.

```plaintext
<child-namespace-uid> <parent-namespace-uid> 1
```
The above is the only valid value that can be written to a process's <mark>uid_map</mark>. It means that we can only map our current user ID to some user ID inside the namespace, and that's it.

> The writing process must have the same effective user ID as the process that created the user namespace.

If I don't have the required capabilties, I can only modify a process's <mark>uid_map</mark>/<mark>gid_map</mark> with the above values if I was the one that created its namespace.

### subuids and subgids
Due to these heavy restrictions, and the need to avoid vulnerabilities by ensuring that every user ID/group ID in the namespace is mapped to a non-root user ID/group ID, container engines like podman came up with a mechanism called subuids and subgids.

subuids and subgids allow for the system administrator to delegate user ID/group ID ranges to a non-root user. This enables the non-root user to map more than 1 user ID/group ID from the namespace, even though they don't have the CAP_SETUID/CAP_SETGID capabilities.

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

However, if you'll recall, in the [Permissions](#permissions) section, I said that unless we have the CAP_SETUID/CAP_SETGID capabilities, we can only map ourselves into the namespace. We certainly don't have CAP_SETUID/CAP_SETGID, so what gives? How can we suddenly map 65536 users into the namespace?

Well, **we** can't do that, but **container engines** can, due to a little trick called file capabilities.

Container engines utilize 2 binaries called <mark>newuidmap</mark>/<mark>newgidmap</mark>, that  have the CAP_SETUID/CAP_SETGID capabilities. These binaries read <mark>/etc/subuid</mark> and <mark>/etc/subgid</mark>, verify that you have enough user IDs/group IDs to map all of the user IDs/group IDs inside the container, and modify the container process's <mark>uid_map</mark>/<mark>gid_map</mark>.


## Revisting The Question
Now that we covered the background required, we can revisit [The Question](#the-question).
As we've discussed previously, we know that in all possible cases, there is some kind of user ID mapping. Whether it is the identity mapping as is the default when running rootful, or some other mapping configured by the system administrator/container engine.

In order to further illustrate this, we'll try some concrete examples. In all examples we'll use the same image built in the original [Example](#example).
Try and see if you can correctly guess the output of the commands

### Rootful Default Mapping
```shell
[root@fedora ~]$ podman run --volume /tmp:/tmp debian:bookworm-nonroot touch /tmp/x
```
{{<details summary="Output">}}
```shell
[root@fedora ~]$ ls -l /tmp/x
-rw-r--r-- 1 1000 1000 0 Jan 31 23:45 /tmp/x
```
Since by default rootful containers use the identity mapping, it is expected that the user ID will stay the same.
{{</details>}}

### Rootful Custom Mapping
```shell
[root@fedora ~]$ podman run --uidmap=0:100000:65536 -v /tmp:/tmp debian:bookworm-nonroot touch /tmp/x
```
The option <mark>\-\-uidmap</mark> receives the same paramters as [<mark>uid_map</mark>](#uid_map) except delimited by colons and not whitespace.
{{<details summary="Output">}}
```shell
[root@fedora ~]$ ls -l /tmp/x
-rw-r--r-- 1 101000 101000 0 Jan 31 23:45 /tmp/x
```
It is easy to see why the user ID is 101000 if we look at a table representation of the user ID mapping:
| Container UID | Host UID   |
| ------------- | ---------- |
| 0             | 100000     |
| 1             | 100001     |
| 2             | 100002     |
| . . .         | . . .      |
| 1000          | 101000     |
| . . .         | . . .      |
| 65535         | 165535     |

However, why was the group ID 101000? We didn't use any group ID mapping, so it should have been 1000, shouldn't it?
In these kinds of cases, where the user ID/group ID on host don't match our expectations, we should look at the <mark>/proc/\<pid\>/uid_map</mark> and <mark>/proc/\<pid\>/gid_map</mark> files:
```shell
[root@fedora ~]$ podman run --uidmap=0:100000:65536 -d --name rootful debian:bookworm-nonroot sleep infinity
[root@fedora ~]$ cat /proc/$(podman inspect rootful | jq '.[0].State.Pid')/gid_map
0     100000      65536
```
When <mark>\-\-gidmap</mark> isn't specified, podman uses <mark>\-\-uidmap</mark>'s value for it. The opposite is true as well, when <mark>\-\-uidmap</mark> isn't specified, podman uses <mark>\-\-gidmap</mark>'s value for it.
{{</details>}}

### Rootless Default Mapping
```shell
[tomerh@fedora ~]$ cat /etc/subuid
tomerh:100000:65536
[tomerh@fedora ~]$ cat /etc/subgid
tomerh:100000:65536
[tomerh@fedora ~]$ id -u
501
[tomerh@fedora ~]$ podman run -v /tmp:/tmp debian:bookworm-nonroot touch /tmp/x
```

{{<details summary="Output">}}
```shell
[root@fedora ~]$ ls -l /tmp/x
-rw-r--r-- 1 100999 100999 0 Jan 31 23:45 /tmp/x
```
Huh, that's not what I was expecting. Shouldn't it have been 101000?

Let's take a look at <mark>/proc/\<pid\>/uid_map</mark>:
```shell
[tomerh@fedora ~]$ podman run -d --name rootless debian:bookworm-nonroot sleep infinity
[tomerh@fedora ~]$ cat /proc/$(podman inspect rootless | jq '.[0].State.Pid')/uid_map
0        501          1
1     100000      65536
```
Podman maps our user ID to the container's root user ID, and then maps all the other user IDs sequentially, according to our subuids and subgids. So the following mapping was used:
| Container UID | Host UID   |
| ------------- | ---------- |
| 0             | 501        |
| 1             | 100000     |
| 2             | 100001     |
| . . .         | . . .      |
| 1000          | 100999     |
| . . .         | . . .      |
| 65535         | 165534     |

And that's why the command showed 100999 instead of 101000. That still doesn't answer why podman maps our user ID into the container. Taking a look at the documentation, the following section appears relevant:

> If <mark>\-\-userns</mark> is not set, the default value is determined as follows.
> * If <mark>\-\-pod</mark> is set, <mark>\-\-userns</mark> is ignored and the user namespace of the pod is used.
> * If the environment variable PODMAN_USERNS is set its value is used.
> * If userns is specified in containers.conf this value is used.
> * Otherwise, <mark>\-\-userns=host</mark> is assumed.
>
> <cite>userns-mode - Podman Docs[^5]</cite>

And below that there's the following table, including all the possible values of <mark>\-\-userns</mark>, and what mapping they use for the user's user ID:
| Key                     | Host UID | Container UID |
| ----------------------- | -------- | ------------- |
| auto                    | $UID     | nil           |
| host                    | $UID     | 0             |
| keep-id                 | $UID     | $UID          |
| keep-id:uid=200,gid=210 | $UID     | 200           |
| nomap                   | $UID     | nil           |

Since none of the conditions in the list apply to us, <mark>\-\-userns=host</mark> is assumed, which means that our user ID is mapped to the root user ID, as seen in the table. If we want to change this, we'll have to pick another mode.
{{</details>}}

### Rootless Custom Mapping
```shell
[tomerh@fedora ~]$ cat /etc/subuid
tomerh:100000:65536
[tomerh@fedora ~]$ cat /etc/subgid
tomerh:100000:65536
[tomerh@fedora ~]$ id -u
501
[tomerh@fedora ~]$ podman run --uidmap=0:0:65536 -d --name rootless debian:bookworm-nonroot sleep infinity
```
{{<details summary="Output">}}
```shell
[root@fedora ~]$ ls -l /tmp/x
-rw-r--r-- 1 100999 100999 0 Jan 31 23:45 /tmp/x
```
Rather unexpectedly, using <mark>\-\-uidmap</mark> doesn't actually change the mapping podman uses compared to the [Rootless Default Mapping](#rootless-default-mapping), as can be seen in the <mark>uid_map</mark>:
```shell
[tomerh@fedora ~]$ podman run --uidmap=0:0:65536 -d --name rootless debian:bookworm-nonroot sleep infinity
[tomerh@fedora ~]$ cat /proc/$(podman inspect rootless | jq '.[0].State.Pid')/uid_map
0        501          1
0     100000      65535
```
If you have a keen eye, you may have noticed that I used <mark>\-\-uidmap=0:0:65536</mark> and not <mark>\-\-uidmap=0:100000:65536</mark>. This is because in rootless mode, podman seperates the user and group ID mapping into 2 steps, that look like this:

| Container UID | Intermediate UID | Host UID |
| ------------- | ---------------- | -------- |
| 0             | 0                | 501      |
| 1             | 1                | 100000   |
| 2             | 2                | 100001   |
| . . .         | . . .            | . . .    |
| 1000          | 1000             | 100999   |
| . . .         | . . .            | . . .    |
| 65535         | 65535            | 165534   |

And these mapping steps can be controlled independently:
1. <mark>\-\-uidmap</mark>(and <mark>\-\-gidmap</mark>), which can be used to control the mapping between the container user ID and the intermediate user ID. That is the reason we used <mark>0:0:65536</mark> and not <mark>0:100000:65536</mark>, since we want to map the 0th container user ID to the 0th intermediate user ID, etc.
2. <mark>\-\-userns</mark>, which can be used to control the mapping between the intermediate user ID and the host user ID.

As I mentioned in [Rootless Default Mapping](#rootless-default-mapping), <mark>\-\-userns=host</mark> is used by default, which causes this mapping:

| Intermediate UID | Host UID |
| ---------------- | -------- |
| 0                | 501      |

In order to keep that from happening, we must change our <mark>\-\-userns</mark> mode.

The table in the [Rootless Default Mapping](#rootless-default-mapping) points us in the direction of either <mark>\-\-userns=auto</mark> or <mark>\-\-userns=nomap</mark>:
> auto: Automatically create a unique user namespace. The users range from the /etc/subuid and /etc/subgid files will be used.
>
> nomap: Creates a user namespace where the current rootless user’s user ID and group ID are not mapped into the container.
>
> <cite>userns-mode - Podman Docs[^5]</cite>

From their description I'd wager we want to use <mark>auto</mark>, but let's try both and see how they're different:
```shell
[tomerh@fedora ~]$ podman run --userns=auto -d --name rootless debian:bookworm-nonroot sleep infinity
[tomerh@fedora ~]$ cat /proc/$(podman inspect rootless | jq '.[0].State.Pid')/uid_map
0     100000       1024
```
```shell
[tomerh@fedora ~]$ podman run --userns=nomap -d --name rootless debian:bookworm-nonroot sleep infinity
[tomerh@fedora ~]$ cat /proc/$(podman inspect rootless | jq '.[0].State.Pid')/uid_map
0     100000      65536
```
The difference between <mark>\-\-userns=nomap</mark> and <mark>\-\-userns=auto</mark> is the default size of the mapping. While <mark>\-\-userns=nomap</mark> uses all available subuids and subgids, <mark>\-\-userns=auto</mark> tries to use only as much as needed. In addition, while <mark>\-\-userns=nomap</mark> isn't configurable, <mark>\-\-userns=auto</mark> is. Interestingly, in our case they can be made identical by using <mark>\-\-userns=auto:size=65536</mark>.

When checking the result of our [Question](#the-question) with each of the above options, we can see that the results are the same:
```shell
[tomerh@fedora ~]$ podman run --rm -v /tmp:/tmp --userns=auto debian:bookworm-nonroot touch /tmp/auto
[tomerh@fedora ~]$ podman run --rm -v /tmp:/tmp --userns=auto:size=65536 debian:bookworm-nonroot touch /tmp/auto-size
[tomerh@fedora ~]$ podman run --rm -v /tmp:/tmp --userns=nomap debian:bookworm-nonroot touch /tmp/nomap
[tomerh@fedora ~]$ ls -la /tmp/{auto,auto-size,nomap}
-rw-r--r-- 1 101000 101000 0 Feb  7 13:11 /tmp/auto
-rw-r--r-- 1 101000 101000 0 Feb  7 13:11 /tmp/auto-size
-rw-r--r-- 1 101000 101000 0 Feb  7 13:11 /tmp/nomap
```
{{</details>}}

## Conclusion
As can be seen from the numerous examples we've covered, even when knowing the background it is hard to predict what user and group ID will actually be used when creating files inside containers, especially so with rootless containers, due to idiosyncrasies in the various container engines.

Fortunately, it is very easy to check what mapping is used, so if you encounter any issues with user and group IDs of files on the host created by a container not matching what you expect, remember to check the <mark>uid_map</mark>/<mark>gid_map</mark>!

[^1]: https://docs.redhat.com/en/documentation/red_hat_enterprise_linux_atomic_host/7/html/overview_of_containers_in_red_hat_systems/introduction_to_linux_containers#overview
[^2]: https://man7.org/linux/man-pages/man7/namespaces.7.html
[^3]: https://man7.org/linux/man-pages/man7/user_namespaces.7.html
[^4]: https://man7.org/linux/man-pages/man7/capabilities.7.html
[^5]: https://docs.podman.io/en/latest/markdown/podman-run.1.html#userns-mode
