BINARY_NAME = mediamtx

define DOCKERFILE_BINARIES
FROM $(BASE_IMAGE) AS build-base
RUN apk add --no-cache zip make git tar
WORKDIR /s
COPY go.mod go.sum ./
RUN go mod download
COPY . ./
ENV CGO_ENABLED=0
RUN rm -rf tmp binaries
RUN mkdir tmp binaries
RUN cp mediamtx.yml LICENSE tmp/
RUN go generate ./...

FROM build-base AS build-linux-armv5
ENV GOOS=linux GOARCH=arm GOARM=5
RUN go build -o "tmp/$(BINARY_NAME)"
RUN tar -C tmp -czf "binaries/$(BINARY_NAME)_$$(cat internal/core/VERSION)_linux_armv5.tar.gz" --owner=0 --group=0 "$(BINARY_NAME)" mediamtx.yml LICENSE

FROM build-base AS build-linux-armv6
ENV GOOS=linux GOARCH=arm GOARM=6
RUN go build -o "tmp/$(BINARY_NAME)"
RUN tar -C tmp -czf "binaries/$(BINARY_NAME)_$$(cat internal/core/VERSION)_linux_armv6.tar.gz" --owner=0 --group=0 "$(BINARY_NAME)" mediamtx.yml LICENSE

FROM build-base AS build-linux-armv7
ENV GOOS=linux GOARCH=arm GOARM=7
RUN go build -o "tmp/$(BINARY_NAME)"
RUN tar -C tmp -czf "binaries/$(BINARY_NAME)_$$(cat internal/core/VERSION)_linux_armv7.tar.gz" --owner=0 --group=0 "$(BINARY_NAME)" mediamtx.yml LICENSE

FROM $(BASE_IMAGE)
COPY --from=build-linux-armv5 /s/binaries /s/binaries
COPY --from=build-linux-armv6 /s/binaries /s/binaries
COPY --from=build-linux-armv7 /s/binaries /s/binaries
endef
export DOCKERFILE_BINARIES

binaries:
	echo "$$DOCKERFILE_BINARIES" | docker build . -f - \
	-t temp
	docker run --rm -v "$(shell pwd):/out" \
	temp sh -c "rm -rf /out/binaries && cp -r /s/binaries /out/"
	sudo chown -R $(shell id -u):$(shell id -g) binaries
