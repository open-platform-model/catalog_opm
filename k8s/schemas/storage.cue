// Kubernetes storage schemas for OPM native resource definitions.
package schemas

// #PersistentVolumeClaimSchema accepts the full Kubernetes PVC spec.
#PersistentVolumeClaimSchema: {
	metadata?: {
		name?:      string
		namespace?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	spec?: {
		accessModes?: [...("ReadWriteOnce" | "ReadOnlyMany" | "ReadWriteMany" | "ReadWriteOncePod")]
		storageClassName?: string
		resources?: {
			requests?: {
				storage?: string
				...
			}
			limits?: {
				storage?: string
				...
			}
			...
		}
		volumeMode?: "Filesystem" | "Block"
		selector?: {
			matchLabels?: {[string]: string}
			...
		}
		...
	}
	...
}

// #PersistentVolumeSchema accepts the full Kubernetes PV spec.
#PersistentVolumeSchema: {
	metadata?: {
		name?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	spec?: {
		accessModes?: [...("ReadWriteOnce" | "ReadOnlyMany" | "ReadWriteMany" | "ReadWriteOncePod")]
		storageClassName?:              string
		persistentVolumeReclaimPolicy?: "Retain" | "Recycle" | "Delete"
		capacity?: {
			storage?: string
			...
		}
		volumeMode?: "Filesystem" | "Block"
		...
	}
	...
}

// #StorageClassSchema accepts the full Kubernetes StorageClass spec.
#StorageClassSchema: {
	metadata?: {
		name?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	provisioner!:          string
	reclaimPolicy?:        "Retain" | "Delete"
	volumeBindingMode?:    "Immediate" | "WaitForFirstConsumer"
	allowVolumeExpansion?: bool
	parameters?: {[string]: string}
	mountOptions?: [...string]
	...
}

// WHY: `metadata.name` is required and rendered verbatim. kubelet registers the
// driver under this name in CSINodeInfo and every StorageClass.provisioner
// references it, so a prefixed or overridden name breaks provisioning silently.

// #CSIDriverSchema accepts the full Kubernetes CSIDriver (storage.k8s.io/v1).
// `metadata.name` is the driver's registered, dotted name (e.g.
// "zfs.csi.openebs.io") and renders exactly as authored.
#CSIDriverSchema: {
	metadata: {
		name!: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	spec: {
		attachRequired?: bool
		podInfoOnMount?: bool
		volumeLifecycleModes?: [...("Persistent" | "Ephemeral")]
		storageCapacity?:   bool
		fsGroupPolicy?:     "ReadWriteOnceWithFSType" | "File" | "None"
		requiresRepublish?: bool
		seLinuxMount?:      bool
		tokenRequests?: [...{audience!: string, expirationSeconds?: int, ...}]
		nodeAllocatableUpdatePeriodSeconds?: int
		preventPodSchedulingIfMissing?:      bool
		serviceAccountTokenInSecrets?:       bool
		...
	}
	...
}

// #VolumeSnapshotClassSchema accepts the full VolumeSnapshotClass
// (snapshot.storage.k8s.io/v1). The rendered name is the component's
// resourceName, so `metadata.resourceName` overrides it like StorageClass.
#VolumeSnapshotClassSchema: {
	metadata?: {
		name?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	driver!:         string
	deletionPolicy!: "Delete" | "Retain"
	parameters?: {[string]: string}
	...
}
