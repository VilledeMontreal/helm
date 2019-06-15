// +build fake_client

/*
Copyright The Helm Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package main // import "k8s.io/helm/cmd/helm"

import (
	"k8s.io/helm/pkg/helm"
	"github.com/golang/protobuf/ptypes/timestamp"
	"k8s.io/helm/pkg/proto/hapi/release"
)

func main() {
	var date = timestamp.Timestamp{Seconds: 109236000, Nanos: 0}
	client := &helm.FakeClient{
	    Rels: []*release.Release{
	        &release.Release{
	            Name: "flummoxed-chickadee",
	            Info: &release.Info{
	                FirstDeployed: &date,
	                LastDeployed:  &date,
	                Status: &release.Status{
	                    Code: release.Status_DEPLOYED,
	                },
	            },
            },
        },
    }

    helmMain(client)
}
