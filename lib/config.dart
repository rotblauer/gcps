const postEndpoint = 'http://track.areteh.co:3001/populate/';
// const postEndpoint = 'http://localhost:8081/populate/';
// https://stackoverflow.com/questions/6760585/accessing-localhostport-from-android-emulator
// 10.0.2.2
// const postEndpoint = 'http://10.0.2.2:8081/populate';
const Map<String, String> postHeaders = {
  'AuthorizationOfCats': 'thecattokenthatunlockstheworldtrackyourcats'
};
const appVersion = "v.catInTheHandroid-VERSION";
// const deviceName = 'Papa G';

/*

I/flutter (18211): [location] - {"odometer":0.0,"activity":{"confidence":100,"type":"still"},"extras":{},"battery":{"level":1.0,"is_charging":true},"uuid":"7496efc1-652a-420e-adc9-d6007efd0ad8","coords":{"altitude":267.1,"heading":129.11,"latitude":46.8147988,"accuracy":19.
6,"heading_accuracy":-1.0,"altitude_accuracy":1.3,"speed_accuracy":-1.0,"speed":0.87,"longitude":-92.0717568},"is_moving":false,"timestamp":"2021-01-31T11:13:14.884Z"}


I/flutter (18211): [motionchange] - [Location {odometer: 0.0, activity: {confidence: 100, type: still}, extras: {}, battery: {level: 1.0, is_charging: true}, uuid: 7496efc1-652a-420e-adc9-d6007efd0ad8, coords: {altitude: 267.1, heading: 129.11, latitude: 46.8147988, accurac
y: 19.6, heading_accuracy: -1.0, altitude_accuracy: 1.3, speed_accuracy: -1.0, speed: 0.87, longitude: -92.0717568}, is_moving: false, timestamp: 2021-01-31T11:13:14.884Z}]

*/