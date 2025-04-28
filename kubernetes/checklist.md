### Application development

#### Health checks

- [ ] Containers have Readiness probes
- [ ] Containers crash when there's a fatal error
- [ ] Configure a passive Liveness probe
- [ ] Liveness probes values aren't the same as the Readiness

#### Apps are independent

- [ ] The Readiness probes are independent
- [ ] The app retries connecting to dependent services

#### Graceful shutdown

- [ ] The app doesn't shut down on SIGTERM, but it gracefully terminates connections
- [ ] The app still processes incoming requests in the grace period
- [ ] The CMD in the Dockerfile forwards the SIGTERM to the process
- [ ] Close all idle keep-alive sockets

#### Fault tolerance

- [ ] Run more than on replica for your Development
- [ ] Avoid Pods being placed into a single node
- [ ] Set Pod disruption budgets

#### Resource utilisation

- [ ] Set memory limits and requests for all containers
- [ ] Set CPU request to 1 CPU or below
- [ ] Disable CPU limits -- unless you have a good use case
- [ ] The namespace has a LimitRange
- [ ] Set an appropriate Quality of Service (QoS) for Pods

#### Tagging resources

- [ ] Resources have technical labels defined
- [ ] Resources have business labels defined
- [ ] Resources have security labels defined

#### Logging

- [ ] The application logs to stdout and stderr
- [ ] Avoid sidecars for logging (if you can)

...https://learnk8s.io/production-best-practices