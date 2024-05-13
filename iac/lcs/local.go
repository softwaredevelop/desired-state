//revive:disable:package-comments,exported
package main

import (
	"context"
	"log"
	"os"
	"path/filepath"

	"github.com/pulumi/pulumi/sdk/v3/go/auto"
	"github.com/pulumi/pulumi/sdk/v3/go/auto/debug"
	"github.com/pulumi/pulumi/sdk/v3/go/auto/optpreview"
	"github.com/pulumi/pulumi/sdk/v3/go/auto/optup"
)

func main() {
	ctx := context.Background()

	org := os.Getenv("PULUMI_ORG_NAME")
	project := "gitlab-mirror"

	stackStr1 := "dev-desired-state"
	stackName1 := auto.FullyQualifiedStackName(org, project, stackStr1)
	workDir1 := filepath.Join("localproject_1")

	stack1, err := auto.NewStackLocalSource(ctx, stackName1, workDir1)
	if err != nil && auto.IsCreateStack409Error(err) {
		log.Println("stack " + stackName1 + " already exists")
	}
	if err != nil && !auto.IsCreateStack409Error(err) {
		panic(err)
	}

	pat := os.Getenv("PULUMI_ACCESS_TOKEN")
	err = stack1.Workspace().SetEnvVars(map[string]string{
		"PULUMI_SKIP_UPDATE_CHECK": "true",
		"PULUMI_CONFIG_PASSPHRASE": "",
		"PULUMI_ACCESS_TOKEN":      pat,
	})
	if err != nil {
		panic(err)
	}

	ght := os.Getenv("GITHUB_TOKEN")
	gho := os.Getenv("GITHUB_OWNER")
	err = stack1.SetAllConfig(ctx, auto.ConfigMap{
		"github:token": auto.ConfigValue{
			Value:  ght,
			Secret: true,
		},
		"github:owner": auto.ConfigValue{
			Value:  gho,
			Secret: true,
		},
	})
	if err != nil {
		panic(err)
	}

	refr, err := stack1.Refresh(ctx)
	if err != nil {
		panic(err)
	}
	log.Println(refr.StdOut)

	prev, err := stack1.Preview(ctx, optpreview.DebugLogging(debug.LoggingOptions{
		Debug: true,
	}))
	if err != nil {
		panic(err)
	}
	log.Println(prev.StdOut)

	up, err := stack1.Up(ctx, optup.DebugLogging(debug.LoggingOptions{
		Debug: true,
	}))
	if err != nil {
		panic(err)
	}
	log.Println(up.StdOut)
}
