package main

import (
	"io"
)

func interactAptDepdencies(stdin io.Writer, stdout io.Reader, stderr io.Reader) error {
	if err := interactSudoRevalidate(stdin, stdout, stderr); err != nil {
		return err
	}

	err := runWithRecover(func() error {
		writeOrPanic(stdin, []byte("\n"))

		readUntilTrigger(stdout, []byte("pi@raspberrypi:~$ "))
		writeOrPanic(stdin, []byte("sudo apt update\n"))

		readUntilTrigger(stdout, []byte("password for pi:"))
		writeOrPanic(stdin, []byte("sudo apt install -y build-essential\n"))
		return nil
	})
	return err
}
