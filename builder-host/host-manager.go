package main

import (
	"context"
	"fmt"
	"io"
	"os"
	"os/exec"
	"time"
)

const qemuCommand = "qemu-system-arm"

type HostManager struct {
	context  context.Context
	env      EnvironmentConfiguration
	doneChan chan int
}

func (mgr HostManager) Run() {
	cmd := exec.CommandContext(mgr.context, qemuCommand,
		"-name", mgr.env.vmName,
		"-machine", "versatilepb",
		"-cpu", "arm1176",
		"-m", "256",
		"-drive", fmt.Sprintf("file=%s,format=raw", mgr.env.imageFile),
		"-append", "root=/dev/sda2 console=ttyAMA0,115200 rootfstype=ext4 rw",
		"-kernel", mgr.env.kernelFile,
		"-dtb", mgr.env.dtbFile,
		"-nographic", "-monitor", "none",
		"-serial", "stdio",
		"-no-reboot",
	)

	stdinPipeR, stdinPipeW := io.Pipe()
	cmd.Stdin = stdinPipeR
	stdinWriter := stdinPipeW

	stdoutPipeR, stdoutPipeW := io.Pipe()
	cmd.Stdout = io.MultiWriter(os.Stdout, stdoutPipeW)
	stdoutReader := stdoutPipeR

	stderrPipeR, stderrPipeW := io.Pipe()
	cmd.Stderr = io.MultiWriter(os.Stderr, stderrPipeW)
	stderrReader := stderrPipeR

	if err := cmd.Start(); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to start VM: %v\n", err)
		return
	}

	doneStatus := 0

	if err := interactGuestLogin(stdinWriter, stdoutReader, stderrReader); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to log in to VM: %v\n", err)
		doneStatus = 1
	}

	if err := interactAptDepdencies(stdinWriter, stdoutReader, stderrReader); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to install apt dependencies: %v\n", err)
		doneStatus = 1
	}

	cmd.Process.Signal(os.Interrupt)

	go readForever(stdoutReader)
	go readForever(stderrReader)

	procFinishedChan := make(chan struct{})
	go func() {
		cmd.Wait()
		close(procFinishedChan)
	}()
	select {
	case <-procFinishedChan:
	case <-time.Tick(10 * time.Second):
		if !cmd.ProcessState.Exited() {
			fmt.Fprintf(os.Stderr, "QEMU subprocess %d has not exited yet after 10 seconds; killing it", cmd.Process.Pid)
			cmd.Process.Kill()
		}
	}

	<-time.Tick(1 * time.Second)
	mgr.doneChan <- doneStatus
}
