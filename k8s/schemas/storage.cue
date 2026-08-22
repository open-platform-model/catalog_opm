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
