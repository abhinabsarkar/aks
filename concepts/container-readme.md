# Container
## What is the definition of a container?

Container is a packaged software (which includes code, runtime, system tools, system libraries and settings) created using OS-level virtualization. OS-level virtualization refers to an operating system paradigm in which the kernel allows the existence of multiple isolated user space instances.

This packaging makes containers isolated & independent of host operating system. 

Containers are built on namespaces, control groups & union-capable file systems (UCFS), which makes it act like an Operating System with its own user-space but no kernel-space. Rather it uses the kernel of the host OS. Namespaces control what a process can see i.e. Process Isolation, while control groups (Cgroups) regulate what they can use i.e. Resource Management. 

These are explained in this video & blog
https://www.youtube.com/watch?v=el7768BNUPw
https://jvns.ca/blog/2016/10/10/what-even-is-a-container/


