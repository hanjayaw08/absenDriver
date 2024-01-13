import 'package:nhost_dart/nhost_dart.dart';

final nhost = NhostClient(
  serviceUrls: ServiceUrls(
    authUrl: 'http://45.64.3.54:40380/absendriver-api/v1/auth',
    storageUrl: 'http://45.64.3.54:40380/absendriver-api/v1/storage',
    functionsUrl: 'http://45.64.3.54:40380/absendriver-api/v1/functions',
    graphqlUrl: 'http://45.64.3.54:40380/absendriver-api/v1/graphql',
  ),
);
