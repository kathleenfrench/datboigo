FROM golang:1.11 as base

COPY . /go/src/github.com/kathleenfrench/datboigo

WORKDIR /go/src/github.com/kathleenfrench/datboigo/cmd/datboigo

RUN CGO_ENABLED=0 go build -a -installsuffix cgo -o datboigo

FROM alpine:latest

RUN apk --no-cache add ca-certificates 

WORKDIR /app/

COPY --from=base /go/src/github.com/kathleenfrench/datboigo/cmd/datboigo .
RUN chmod 755 ./datboigo

ENTRYPOINT ["./datboigo"]