# Gruntwork Philosophy

At Gruntwork, we strive to accelerate the deployment of production grade infrastructure by prodiving a library of
stable, reusable, and battle tested infrastructure as code organized into a series of [modules](#what-is-a-module) with
[submodules](#what-is-a-submodule). Each module represents a particular set of infrastructure that is componentized into
smaller pieces represented by the submodules within the module. By doing so, we have built a composable library that can
be combined into building out everything from simple single service deployments to complicated microservice setups so
that your infrastructure can grow with your business needs. Every module we provide is built with the [production grade
infrastruture checklist](#production-grade-infrastructure-checklist) in mind, ensuring that the services you deploy are
resilient, fault tolerant, and scalable.


## What is a Module?

A Module is a reusable, tested, documented, configurable, best-practices definition of a single piece of Infrastructure
(e.g., Docker cluster, VPC, Jenkins, Consul), written using a combination of [Terraform](https://www.terraform.io/), Go,
and Bash. A module contains a set of automated tests, documentation, and examples that have been proven in production,
providing the underlying infrastructure for [Gruntwork's customers](https://www.gruntwork.io/customers).  

Instead of figuring out the details of how to run a piece of infrastructure from scratch, you can reuse existing code
that has been proven in production. And instead of maintaining all that infrastructure code yourself, you can leverage
the work of the community to pick up infrastructure improvements through a version number bump.  


## What is a Submodule?

Each Infrastructure Module consists of one or more orthogonal Submodules that handle some specific aspect of that
Infrastructure Module's functionality. Breaking the code up into multiple submodules makes it easier to reuse and
compose to handle many different use cases. Although Modules are designed to provide an end to end solution to manage
the relevant infrastructure by combining the Submodules defined in the Module, Submodules can be used independently for
specific functionality that you need in your infrastructure code.


## Production Grade Infrastructure Checklist

At Gruntwork, we have learned over the years that it is not enough to just get the services up and running in a publicly
accessible space to call your application "production-ready." There are many more things to consider, and oftentimes
many of these considerations are missing in the deployment plan of applications. These topics come up as afterthoughts,
and are learned the hard way after the fact. That is why we codified all of them into a checklist that can be used as a
reference to help ensure that they are considered before your application goes to production, and conscious decisions
are made to neglect particular components if needed, as opposed to accidentally omitting them from consideration.

<!--
Edit the following table using https://www.tablesgenerator.com/markdown_tables. Start by pasting the table below in the
menu item File > Paste table data.
-->

| Task               | Description                                                                                                                               | Example tools                                            |
|--------------------|-------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------|
| Install            | Install the software binaries and all dependencies.                                                                                       | Bash, Chef, Ansible, Puppet                              |
| Configure          | Configure the software at runtime. Includes port settings, TLS certs, service discovery, leaders, followers, replication, etc.            | Bash, Chef, Ansible, Puppet                              |
| Provision          |  Provision the infrastructure. Includes EC2 instances, load balancers, network topology, security gr oups, IAM permissions, etc.          | Terraform, CloudFormation                                |
| Deploy             | Deploy the service on top of the infrastructure. Roll out updates with no downtime. Includes blue-green, rolling, and canary deployments. | Scripts, Orchestration tools (ECS, k8s, Nomad)           |
| High availability  | Withstand outages of individual processes, EC2 instances, services, Availability Zones, and regions.                                      | Multi AZ, multi-region, replication, ASGs, ELBs          |
| Scalability        | Scale up and down in response to load. Scale horizontally (more servers) and/or vertically (bigger servers).                              | ASGs, replication, sharding, caching, divide and conquer |
| Performance        | Optimize CPU, memory, disk, network, GPU, and usage. Includes query tuning, benchmarking, load testing, and profiling.                    | Dynatrace, valgrind, VisualVM, ab, Jmeter                |
| Networking         | Configure static and dynamic IPs, ports, service discovery, firewalls, DNS, SSH access, and VPN access.                                   | EIPs, ENIs, VPCs, NACLs, SGs, Route 53, OpenVPN          |
| Security           | Encryption in transit (TLS) and on disk, authentication, authorization, secrets management, server hardening.                             | ACM, EBS Volumes, Cognito, Vault, CIS                    |
| Metrics            | Availability metrics, business metrics, app metrics, server metrics, events, observability, tracing, and alerting.                        | CloudWatch, DataDog, New Relic, Honeycomb                |
| Logs               | Rotate logs on disk. Aggregate log data to a central location.                                                                            | CloudWatch logs, ELK, Sumo Logic, Papertrail             |
| Backup and Restore | Make backups of DBs, caches, and other data on a scheduled basis. Replicate to separate region/account.                                   | RDS, ElastiCache, ec2-snapper, Lambda                    |
| Cost optimization  | Pick proper instance types, use spot and reserved instances, use auto scaling, and nuke unused resources.                                 | ASGs, spot instances, reserved instances                 |
| Documentation      | Document your code, architecture, and practices. Create playbooks to respond to incidents.                                                | READMEs, wikis, Slack                                    |
| Tests              | Write automated tests for your infrastructure code. Run tests after every commit and nightly.                                             | Terratest                                                |
