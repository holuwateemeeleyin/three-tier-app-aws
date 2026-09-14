# Security Design

## 1. How the application is protected

The application is divided into three main tiers:

1. Web tier: Nginx
2. Application tier: Node.js
3. Database tier: PostgreSQL

The main idea is that users should only have access to the entry point of the application. They should not be able to connect directly to the web servers, application servers, or database.

The traffic flow is:

```text
Internet
   |
   | HTTP/HTTPS
   v
ALB
   |
   | Port 80
   v
Nginx
   |
   | Port 3000
   v
Node.js
   |
   | Port 5432
   v
PostgreSQL
```

This means each layer only talks to the layer it needs to talk to.

---

## 2. Security Groups

I used a separate security group for each tier.

### ALB Security Group

The ALB is the only part of the application that is publicly accessible.

It allows:

* Port 80 from the internet
* Port 443 from the internet

This allows users to reach the application through the load balancer.

### Web Security Group

The Nginx servers are in private subnets.

They only allow:

* Port 80 from the ALB security group

The web servers do not accept direct traffic from the internet.

### Application Security Group

The Node.js servers are also in private subnets.

They only allow:

* Port 3000 from the web security group

This means a user cannot directly connect to the Node.js application.

### Database Security Group

The PostgreSQL database only allows:

* Port 5432 from the application security group

The database does not allow connections from the internet or directly from the web tier.

The rules therefore look like this:

```text
Internet
   |
   | 80/443
   v
ALB
   |
   | 80
   v
Web
   |
   | 3000
   v
App
   |
   | 5432
   v
Database
```

---

## 3. Private and Public Subnets

I separated the resources into different subnet types.

The public subnets contain the Application Load Balancer and NAT Gateway.

The web and application servers are in private subnets, so they don't have public IP addresses.

The database is in isolated database subnets.

The database subnets do not have a route to the internet.

This is important because the database does not need to be publicly accessible.

---

## 4. NAT Gateway

The private web and application servers still need internet access for things like installing packages and downloading dependencies.

Instead of giving them public IP addresses, they use the NAT Gateway.

The flow is:

```text
Private EC2
     |
     v
NAT Gateway
     |
     v
Internet
```

The important thing is that this is outbound access.

The NAT Gateway does not make the private EC2 servers directly accessible from the internet.

For this assignment, I used one NAT Gateway to keep the architecture simple and control cost. In a production environment, I would consider having a NAT Gateway in each Availability Zone so that one AZ does not depend on the other for outbound access.

---

## 5. Database Credentials

I did not put the PostgreSQL password directly inside the Terraform files.

Instead, the RDS instance is configured to let AWS manage the master password through Secrets Manager.

This is better than putting something like:

```hcl
password = "mypassword123"
```

inside the Terraform code.

Terraform state can still contain sensitive information, so the state files should not be committed to Git.

---

## 6. Encryption

### Encryption at rest

RDS storage encryption is enabled.

The EC2 root volumes are also encrypted.

This helps protect data stored on the underlying disks.

### Encryption in transit

The current assignment uses HTTP between the ALB and Nginx.

For a real production application, I would configure HTTPS on the ALB using an AWS Certificate Manager certificate and redirect HTTP traffic to HTTPS.

For the database connection, PostgreSQL TLS/SSL should also be used where required.

---

## 7. High Availability

I placed the web and application servers across two Availability Zones.

For example:

```text
Availability Zone A       Availability Zone B

   Web Server 1              Web Server 2
        |                         |
   App Server 1              App Server 2
        \                         /
         \                       /
              RDS Multi-AZ
```

If one web or application server becomes unavailable, the other server can continue serving requests.

The RDS database is also configured with Multi-AZ, so AWS maintains a standby database in another Availability Zone.

---

## 8. Security Summary

The main security decisions I made are:

* Only the ALB is publicly accessible.
* Web servers are in private subnets.
* Application servers are in private subnets.
* The database is in isolated subnets.
* Web servers only accept traffic from the ALB.
* Application servers only accept traffic from the web servers.
* The database only accepts PostgreSQL traffic from the application servers.
* Database credentials are managed by AWS rather than hardcoded.
* RDS storage is encrypted.
* EC2 root volumes are encrypted.
* Private servers use NAT for outbound internet access.
* HTTPS should be enabled before using this architecture for a real production application.

The overall approach is to expose as little as possible and only allow the traffic that each part of the application actually needs.
