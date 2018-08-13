This GitHub repository contains a demo implementing vCPE functionality. This is implemented with Ansible Tower.

# Introduction

The virtual CPE (Customer Premises Equipment) is a NFV use case where functionality is moved away from the customer end and moved into the virtualized infrastructure of the network operator.  This allows more flexible deployments, services and lower costs by eliminating any changes in the customer end. 

What once has been several function-specific hardware devices located in the customer location requiring a complex network deployment becomes a simple CPE in the customer end, with a simple network deployment and the required functionalities implemented in a virtualized infrastructure, centralized for all customers in the Central Office of the operator. 

![git-repository_slide1](https://github.com/f5devcentral/f5-vcpe-demo/blob/master/images/git-repository_slide1.png)

# VNFs offered by F5 and service composition

In general VNFs that F5 can offer include:

* Enterprise Grade L4 Firewall. 
* Advanced L7 WAF. 
* Anti-Fraud Protection. 
* Anti-DoS and Anti-DDoS. 
* IP intelligence. 
* CG-NAT. 
* Traffic shapping. 
* Access Policy Manager & SSO. 
* Secure Web Gateway. 
* DNS caching and anti-DNS tunneling. 
* DPI with L7 classification including traffic SSL/TLS traffic. Application Visibility. 

These VNFs' can be composed, shared between customers or configured independently for each customer. This is exhibit in the next picture:

![git-repository_slide2](https://github.com/f5devcentral/f5-vcpe-demo/blob/master/images/git-repository_slide2.png)

To facilitate this F5 allows packaging customers’ services in templates. These are called iApps in F5 BIG-IP. F5 brings a built-in Service Catalog of iApps which can be augmented by the tenant. iApps follow the deploy -> modify -> undeploy life-cycle of services in NFV and eases operations teams identifying customer’s specific configuration and statistics. 

Please also note that this service composition and iApp configuration sharing happens at the same time that the data-planes of both customers are isolated. 

The Ansible playbooks contained in this repository implement the following VNFs:

* Bandwidth control
* URL and SSL/TLS filtering using WebSense DB 
* Anti-DNS tunneling
* Outbound NAT
* High speed logging (common for all customers)

# VNF consolidation

VNF consolidation dramatically increases the overall performance of the solution. We can clearly see the benefits of this consolidation by comparing the two options side-by-side: 

![git-repository_slide3](https://github.com/f5devcentral/f5-vcpe-demo/blob/master/images/git-repository_slide3.png)

The above figure exhibits the following overheads in the decomposed solution: 

* Overhead of the OS of the multiple VMs. 
* Overhead of the vSwitch  moving the same traffic over the multiple VMs 
* Overhead of the physical infrastructure potentially moving the same traffic over multiple hypervisors. 
* CPU Overhead of the multiple VM and process context switches. 
* Memory bandwidth overhead copying the same data across multiple VMs. 

By using a consolidated solution all these overheads are eliminated, additionally orchestration is simplified and ultimately TCO reduced. 

# Overview of the Ansible Tower templates

Adding or removing BIG-IPs from the cluster:
* bigip-cluster-add-members.yml
* bigip-cluster-del-members.yml

Adding or removing customers:
* create-customer.yml
* delete-customer.yml

Test points:
* attach-testpoint.yml: Attaches an existing VM to a customer's access network to perform traffic tests.

Utility templates:
* bigip-cluster-initial-load-distribution.yml: to modify how the customers are distributed amongs the cluster
* bigip-cluster-move-traffic-group.yml: to move a specific traffic-group to a specific BIG-IP

# Overview of the how the configuration is deployed

The demo only assumes BIG-IPs have been booted, have their management port ocnfigured and have been licensed. This previous configuration could be added as well if desired but it was not part of the goal of this demo.

All configurations, including BIG-IP's base configuration are deployed in iApps. These iApps have been implemented with tmsh2iapp which produce iApps and Ansible playbooks/roles using a modified tmsh config as input.

If we use an abstract view of the configuration and how ansible deploys this configuration, we differentiate in the following:

* base config: it contains L1/L2/L3 configuration that will be used by all customers. This is BIG-IP specific.
* customer-X-network: it contains L2/L3 configuration specific of each customers. This is BIG-IP specific. There are as many instances of these as customers.
* customer-X-service: it contains the services configurations of each customers. Typically there are as many instances as customers with the exceptions of shared configs across customers. 

This is exhibit in the next picture:

![git-repository_slide4](https://github.com/f5devcentral/f5-vcpe-demo/blob/master/images/git-repository_slide4.png)

The next picture shows the same configuration but seen when it is deployed in a cluster. 

It is very important to see that both the base configs and customer-X-network configs are BIG-IP specific. Thanks to tmsh2iapp it is possible to deploy iApps that contain the parameters of all the BIG-IPs in the cluster. At instantiation time the iApps that generate the base configs and the customer-X-network configs will generate the appropiate config for each BIG-IP. This greatly simplifies the ansible playbooks and the management of the configuration.

![git-repository_slide5](https://github.com/f5devcentral/f5-vcpe-demo/blob/master/images/git-repository_slide5.png)

# Details of how the configuration is deployed

Creating services for a new customer. The following Ansible roles are run in sequence:

* add-customer-networks (creates L2/L3 config in all BIG-IPs with same IP and parameteers that is specific of each customer/BIG-IP)
* add-customer-services (creates services configuration, initially deployed in single BIG-IP then config-sync'ed)
* sync-to-group (syncs add-customer-services config)

When a new BIG-IP is added to the cluster the following Ansible roles are run in sequence:

* base-network-config (creates basic L1/L2/L3 config corresponding to the new BIG-IP)
* ha-config (attaches the BIG-IP to the cluster)
* common-networks (creates L1/L2/L3 networking that will be shared amongst customers/BIG-IP)
* add-all-customers-networks (creates L2/L3 config that is specific of each customer/BIG-IP)
* add-all-customers-services (creates services of each customer/service)

Therefore once bigip-cluster-add-members.yml is run the new BIG-IP contains all customer's configurations. bigip-cluster-del-members.yml is basically the reverse.

Notice adding a BIG-IP to the cluster runs add-all-customers-networks instead of add-customers-networks and add-all-customers-services instead of add-customers-services. The -all- Ansible roles basically loops over the Ansible roles for a single customer.

In order to know which customers have been deployed all BIG-IPs in the cluster have an Ansible facts file stored in /config/facts.d/customers.fact which contain the customers/services deployed.

Although in this README file the focus is in the BIG-IP configuration the Ansible plabooks in this repository also deploy the necessary Openstack/Neutron configuration.

# Possible improvements

When these playbooks were developed there were no ansible modules for creating clusters in the BIG-IP. The commands in the ha-config role could be replaced with the ansible modules to add/remove BIG-IPs from the cluster management. 

# License

The contents of this repository are released to the community under the Apache v2 license. It is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

# Contact

If you have any question or comment about this repository or the playbooks, please contact me thorugh this e-mail:

![email](https://github.com/f5devcentral/f5-vcpe-demo/blob/master/images/email.png)

