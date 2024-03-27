# Insurance Application Group Default EKS Setup

IAG, like many modern corporations, makes heavy use of containers and kubernetes in our infrastructure, particularly EKS.
Our default EKS setup is fairly basic but includes several features, including EBS and EFS support out of the box, as well
as support for creating ELBs on demand.  To that end, we have made a copy of our Terraform setup scripts available under an
MIT license.

## Requirements

You will need to install

- OpenTofu
- AWS CLI
- Kubectl

in order to use these scripts

## Running

First init the provider with `tofu init`.  Once initialized, make any necessary customizations to the top level `variables.tf`
file.  Once ready, `tofu apply`.

> Note: It is necessary to maintain one directory per cluster.

## Contributing

This repository does not accept contributions.

## Authors

* **Ethan McGee** - *Initial work* - [ethantmcgee](https://github.com/ethantmcgee)

See also the list of [contributors](https://github.com/iagtech/dep-check/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.md](https://github.com/iagtech/dep-check/blob/main/LICENSE.md) file for details.
