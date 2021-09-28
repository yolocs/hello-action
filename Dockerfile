FROM golang:1.17 as build-env

WORKDIR /go/src/app
COPY . /go/src/app

RUN go get -d -v ./...

RUN go build -o /go/bin/app

FROM gcr.io/distroless/static:nonroot
COPY --from=build-env /go/bin/app /
CMD ["/app"]