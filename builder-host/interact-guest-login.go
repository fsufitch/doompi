package main

import (
	"io"
)

func interactGuestLogin(stdin io.Writer, stdout io.Reader, stderr io.Reader) error {
	err := runWithRecover(func() error {
		readUntilTrigger(stdout, []byte("raspberrypi login: "))
		writeOrPanic(stdin, []byte("pi\n"))

		readUntilTrigger(stdout, []byte("Password: "))
		writeOrPanic(stdin, []byte("raspberry\n\n\r\n"))

		readUntilTrigger(stdout, []byte("pi@raspberrypi:~$ "))
		writeOrPanic(stdin, []byte("echo 'Logged in successfully!'\n\n"))

		readUntilTrigger(stdout, []byte("pi@raspberrypi:~$ "))
		return nil
	})
	return err
}
