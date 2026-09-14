package schemas

import ( "strings"

	/////////////////////////////////////////////////////////////////
	//// Common Schemas
	/////////////////////////////////////////////////////////////////
)

// DNS label name type (RFC 1123). Max 63 characters.
// Mirrors core.#NameType for use in the schemas package (which cannot import core).
#NameType: string & =~"^[a-z0-9]([a-z0-9-]*[a-z0-9])?$" & strings.MinRunes(1) & strings.MaxRunes(63)

// Labels and annotations schema
#LabelsAnnotationsSchema: [string]: string | int | bool | [string | int | bool]

// Semantic version schema
#VersionSchema: string & =~"^\\d+\\.\\d+\\.\\d+(-[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?(\\+[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?$"

// Five whitespace-separated cron fields: minute, hour, day-of-month, month,
// day-of-week. Engine shorthands ("@daily", "@daily-random") are deliberately
// not admitted at a contract; an adapter may accept its own where it renders
// its own schedules.
#CronSchema: string & =~"^(\\S+\\s+){4}\\S+$"
