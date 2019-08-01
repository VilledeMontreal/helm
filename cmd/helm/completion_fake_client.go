// +build completion_fake_client

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

package main // import "helm.sh/helm/cmd/helm"

import (
	"io/ioutil"
	"os"
	"strconv"
	"time"

	"helm.sh/helm/pkg/action"
	"helm.sh/helm/pkg/chart"
	"helm.sh/helm/pkg/chartutil"
	kubefake "helm.sh/helm/pkg/kube/fake"
	"helm.sh/helm/pkg/release"
	"helm.sh/helm/pkg/storage"
	"helm.sh/helm/pkg/storage/driver"
)

const (
	completionNumTestReleases   = 300
	completionSampleTimeSeconds = int64(46966690)
)

func main() {
	initKubeLogs()

	actionConfig := &action.Configuration{
		Releases:     createFakeStore(),
		KubeClient:   &kubefake.PrintingKubeClient{Out: ioutil.Discard},
		Capabilities: chartutil.DefaultCapabilities,
		Log:          func(format string, v ...interface{}) {},
	}

	cmd := newRootCmd(actionConfig, os.Stdout, os.Args[1:])

	if err := cmd.Execute(); err != nil {
		logf("%+v", err)
		os.Exit(1)
	}
}

func createFakeStore() *storage.Storage {
	store := storage.Init(driver.NewMemory())

	for i := 0; i < completionNumTestReleases; i++ {
		store.Create(&release.Release{
			Name:      "rel" + strconv.Itoa(i),
			Version:   i,
			Namespace: "default",
			Info: &release.Info{
				LastDeployed: time.Unix(completionSampleTimeSeconds+int64(100000*i), 0).UTC(),
				Status:       release.StatusDeployed,
			},
			Chart: &chart.Chart{
				Metadata: &chart.Metadata{
					Name:    "chickadee" + strconv.Itoa(i),
					Version: "1.0.0",
				},
			},
		})
	}

	return store
}
