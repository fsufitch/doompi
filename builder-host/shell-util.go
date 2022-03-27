package main

import (
	"bufio"
	"bytes"
	"fmt"
	"io"
)

func readUntilTrigger(stream io.Reader, trigger []byte) []byte {
	reader := bufio.NewReader(stream)
	buf := []byte{}
	for {
		b, err := reader.ReadByte()
		if err != nil {
			panic(err)
		}
		buf = append(buf, b)
		if bytes.HasSuffix(buf, trigger) {
			return buf
		}
	}
}

func writeOrPanic(w io.Writer, bytes []byte) {
	n, err := w.Write(bytes)
	if n != len(bytes) {
		panic(fmt.Sprintf("Only wrote %d/%d bytes", n, len(bytes)))
	}
	if err != nil {
		panic(err)
	}
}

func runWithRecover(cb func() error) (err error) {
	defer func() {
		if r := recover(); r != nil {
			err = fmt.Errorf("%v", r)
		}
	}()
	return cb()
}

func readForever(r io.Reader) {
	buf := bufio.NewReader(r)
	for {
		if _, err := buf.ReadByte(); err != nil {
			return
		}
	}
}
