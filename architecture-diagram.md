# Three-Tier AWS Architecture

## Architecture Overview

The application is split into three main tiers:

- Web tier: Nginx
- Application tier: Node.js
- Database tier: PostgreSQL

The architecture is deployed across two Availability Zones to improve availability.

```text
                              INTERNET
                                  |
                                  v
                    +--------------------------+
                    | Application Load Balancer|
                    |       Public Subnets     |
                    +------------+-------------+
                                 |
                          HTTP :80 / HTTPS :443
                                 |
                +----------------+----------------+
                |                                 |
                v                                 v
        +---------------+                 +---------------+
        |  Web Server 1 |                 |  Web Server 2 |
        |     Nginx     |                 |     Nginx     |
        |    AZ-A       |                 |    AZ-B       |
        | Private Subnet|                 | Private Subnet|
        +-------+-------+                 +-------+-------+
                |                                 |
                | TCP 3000                        | TCP 3000
                v                                 v
        +---------------+                 +---------------+
        |  App Server 1 |                 |  App Server 2 |
        |    Node.js    |                 |    Node.js    |
        |    AZ-A       |                 |    AZ-B       |
        | Private Subnet|                 | Private Subnet|
        +-------+-------+                 +-------+-------+
                \                                 /
                 \                               /
                  \          TCP 5432           /
                   \                           /
                    +-------------------------+
                    |     RDS PostgreSQL      |
                    |       Multi-AZ          |
                    |   Isolated DB Subnets   |
                    +-------------------------+

        Private Web/App Servers
                  |
                  v
            NAT Gateway
                  |
                  v
              INTERNET
        Outbound traffic only