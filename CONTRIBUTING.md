# Contributing

## Local Development

We use [KinD](https://kind.sigs.k8s.io/docs/user/quick-start/) and [ko](https://ko.build/install/) to aid in local development. Follow their quick start and installation guides for your system.

Afterwards use the [Makefile](Makefile) for common tasks. To get started:

```sh
make kind-up
make deploy
curl localhost/calculator/add/2/33
```
