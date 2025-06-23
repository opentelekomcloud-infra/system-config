# Zuul restarter

Sometimes credentials stored in Vault are rotated outside of Zuul. Since Zuul
itself is not capable of reloading its general configration it is better to
simply periodically restart certain parts of it.

This component is implementing K8 ServiceAccount with role and few CronJobs
that restart some Zuul components.
