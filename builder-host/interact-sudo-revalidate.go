package main

import (
	"io"
)

func interactSudoRevalidate(stdin io.Writer, stdout io.Reader, stderr io.Reader) error {
	err := runWithRecover(func() error {
		writeOrPanic(stdin, []byte("\n"))

		readUntilTrigger(stdout, []byte("pi@raspberrypi:~$ "))
		writeOrPanic(stdin, []byte("sudo -kv\n"))

		readUntilTrigger(stdout, []byte("password for pi:"))
		writeOrPanic(stdin, []byte("raspberry\n"))
		return nil
	})
	return err
}
