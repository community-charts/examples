# LivenessProbe and ReadinessProbe Example

This example simulates the liveness probe and readiness probe usage. Please review the [values.yaml](values.yaml) file.

> **Warning**
> If you increase the initial delay time like this example, and if you use some tools like Terraform to deploy your Helm chart, you can experience some timeouts from your deployment with Terraform. Because default timeout is 5 minutes for it and Helm will wait until to start to get ready state from the deployment. This can only happen if you increase delay time too much. And the solution could be increasing your timeout. On the other hand, most of the time, you should not experience this problem.
