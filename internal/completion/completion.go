package completion

import (
	"fmt"
)

const compInfoMarker = "_info_ "

// AppendCompInfo adds the specified completion information string to the specified array.
// Such strings will be processed by the completion script and will be shown as
// information to the user.
// The array parameter should be the array that will contain the completions.
// This function can be called multiple times before and/or after completions are added to
// the array.  Each time this function is called with the same array, the new
// information line will be shown below the previous ones when completion is triggered.
func AppendCompInfo(compArray []string, info string) []string {
	return append(compArray, fmt.Sprintf("%s%s", compInfoMarker, info))
}
