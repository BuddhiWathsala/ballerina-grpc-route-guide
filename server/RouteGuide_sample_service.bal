import ballerina/io;
import ballerina/lang.'int;
import ballerina/lang.'float;
import ballerina/grpc;
import ballerina/time;

type FeatureArray Feature[];
listener grpc:Listener ep = new (8980);
final Feature EMPTY_FEATURE = {location: {latitude: 0, longitude: 0}, name: ""};
configurable string featuresFilePath = "./resources/route_guide_db.json";

@grpc:ServiceDescriptor {descriptor: ROOT_DESCRIPTOR, descMap: getDescriptorMap()}
service "RouteGuide" on ep {

    remote function GetFeature(Point point) returns Feature|error {
        Feature?|error feature = featureFromPoint(point);
        if feature is Feature || feature is error {
            return feature;
        } else {
            return EMPTY_FEATURE;
        }
    }
    remote function RecordRoute(stream<Point, grpc:Error?> clientStream) returns RouteSummary|error {
        Point? lastPoint = ();
        int pointCount = 0;
        int featureCount = 0;
        int distance = 0;
        Feature[] features = check populateFeatures();
        decimal startTime = time:monotonicNow();
        error? e = clientStream.forEach(function(Point p) {
            pointCount += 1;
            if pointExistsInFeatures(features, p) {
                featureCount += 1;
            }

            if lastPoint is Point {
                distance = calculateDistance(<Point>lastPoint, p);
            }
            lastPoint = p;
        });
        decimal endTime = time:monotonicNow();
        int elapsedTime = <int>(endTime - startTime);
        return {point_count: pointCount, feature_count: featureCount, distance: distance, elapsed_time: elapsedTime};
    }

    remote function ListFeatures(Rectangle rectangle) returns stream<Feature, grpc:Error?>|error {
        // Feature[] allFeatures = check populateFeatures();
        // Feature[] selectedFeatures = [];
        // foreach Feature feature in allFeatures {
        //     if inRange(feature.location, rectangle) {
        //         // io:println("range");
        //         selectedFeatures.push(feature);
        //     }
        // }
        io:println("Select");
        Feature[] fs = [
            {location: {latitude: 1, longitude: 2}, name: "buddhi"},
            {location: {latitude: 1, longitude: 3}, name: "koth"},
            {location: {latitude: 4, longitude: 2}, name: "wath"}
        ];
        // io:println(selectedFeatures);
        return fs.toStream();
    }

    // remote function ListFeatures(RouteGuideFeatureCaller caller, Rectangle rectangle) returns error? {
    //     Feature[] allFeatures = check populateFeatures();
    //     Feature[] selectedFeatures = [];
    //     foreach Feature feature in allFeatures {
    //         if inRange(feature.location, rectangle) {
    //             // io:println("range");
    //             check caller->sendFeature(feature);
    //         }
    //     }
    //     io:println("Select");
    //     check caller->complete();
    //     // io:println(selectedFeatures);
    // }

    remote function RouteChat(stream<RouteNote, grpc:Error?> clientStream) returns stream<RouteNote, grpc:Error?>|error {
        RouteNote[] routeNotes = [
            {location: {latitude: 406109563, longitude: -742186778}, message: "m1"},
            {location: {latitude: 411733222, longitude: -744228360}, message: "m2"},
            {location: {latitude: 406109563, longitude: -742186778}, message: "m3"}
        ];
        return routeNotes.toStream();
    }
}

// public function main() returns error? {
//     io:println(calculateDistance({latitude: 400000000, longitude: -750000000}, {latitude: 420000000, longitude: -730000000}));
// }

function toRadians(float f) returns float {
    return f * 'float:PI / 180.0;
}

function calculateDistance(Point p1, Point p2) returns int {
    float cordFactor = 10000000; // 1x(10^7) OR 1e7
    float R = 6371000; // Earth radius in metres
    float lat1 = toRadians(<float>p1.latitude / cordFactor);
    float lat2 = toRadians(<float>p2.latitude / cordFactor);
    float lng1 = toRadians(<float>p1.longitude / cordFactor);
    float lng2 = toRadians(<float>p2.longitude / cordFactor);
    float dlat = lat2 - lat1;
    float dlng = lng2 - lng1;

    float a = 'float:sin(dlat / 2.0) * 'float:sin(dlat / 2.0) + 'float:cos(lat1) * 'float:cos(lat2) * 'float:sin(dlng / 2.0) * 'float:sin(dlng / 2.0);
    float c = 2.0 * 'float:atan2('float:sqrt(a), 'float:sqrt(1.0 - a));
    float distance = R * c;
    return <int>distance;
}

function inRange(Point point, Rectangle rectangle) returns boolean {
    int left = 'int:min(rectangle.lo.longitude, rectangle.hi.longitude);
    int right = 'int:max(rectangle.lo.longitude, rectangle.hi.longitude);
    int top = 'int:max(rectangle.lo.latitude, rectangle.hi.latitude);
    int bottom = 'int:min(rectangle.lo.latitude, rectangle.hi.latitude);

    if point.longitude >= left && point.longitude <= right && point.latitude >= bottom && point.latitude <= top {
        return true;
    }
    return false;
}

function pointExistsInFeatures(Feature[] features, Point point) returns boolean {
    foreach Feature feature in features {
        if feature.location == point {
            return true;
        }
    }
    return false;
}

function featureFromPoint(Point point) returns Feature?|error {
    Feature[] features = check populateFeatures();
    foreach Feature feature in features {
        if feature.location == point {
            return feature;
        }
    }
    return ();
}

function populateFeatures() returns Feature[]|error {
    json locationsJson = check io:fileReadJson(featuresFilePath);
    return check locationsJson.cloneWithType(FeatureArray);
}
