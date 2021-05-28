# Ballerina gRPC tooling commands that used to generate the boilerplate server and client codes.
bal grpc --input proto-files/route_guide.proto --output server --mode service
bal grpc --input proto-files/route_guide.proto --output client --mode client
