# minIO

Module for managing minIO instances.
The module is structured in a way to support rolling out the same configuration across multiple minIO instances.

Currently a bucket for restic backups as well as a bucket for Tofu states is created, including users for fine-grained access.

## State bucket

The state bucket is supposed to have a prefix per Tofu Project and then for each module in that project another subprefix.
For example this module is in the home-lab tofu project, so the state should reside in `<minio-instance>/home-lab/minio/`.

### Cyclic setup problem

There's currently a caveat with the setup in that this module uses ac bucket for state storage, that is at the same time managed by it.
The result of that is that moving from one minIO instance to another is a little tricky.
This is because in order to create the required buckets and permissions on the new instance, we need to modell that state and roll it out.
That will create a state bucket in the new instance, but store this state in the old instance.

A process to work around that, looks like the following:

- Add Tofu configuration to set up the new instance
- Roll out the changes
- Use the global read user on the new instance to synchronize the content from the old instance (using, e.g. rclone)
- Verify everything is fine on the new instance
- Update the top level `secrets.json` to contain the credentials for the new instance. Update all Tofu backend configurations to look manage state on the new instance
- Verify everything is fine
- Decommission the old instance
