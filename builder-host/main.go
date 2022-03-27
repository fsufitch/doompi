package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"
)

type EnvironmentConfiguration struct {
	vmName              string
	imageFile           string
	kernelFile          string
	dtbFile             string
	guestBuilderBinFile string
}

func readEnvironment() EnvironmentConfiguration {
	return EnvironmentConfiguration{
		vmName:              os.Getenv("VM_NAME"),
		imageFile:           os.Getenv("IMAGE"),
		kernelFile:          os.Getenv("KERNEL"),
		dtbFile:             os.Getenv("DTB"),
		guestBuilderBinFile: os.Getenv("GUEST_BUILDER_BIN"),
	}
}

func main() {
	env := readEnvironment()
	ctx, cancel := context.WithCancel(context.Background())
	doneChan := make(chan int, 1)

	mgr := HostManager{
		context:  ctx,
		doneChan: doneChan,
		env:      env,
	}

	go mgr.Run()

	signalChan := make(chan os.Signal, 1)
	signal.Notify(signalChan, os.Interrupt)

	select {
	case sig := <-doneChan:
		fmt.Printf("Host manager finished with signal %d\n", sig)
		os.Exit(sig)
	case <-signalChan:
		fmt.Println("Received interrupt, exiting...")
		cancel()
		os.Exit(1)
	}
}
