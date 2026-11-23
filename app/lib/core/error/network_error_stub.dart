/// Web-safe default: `dart:io` network errors do not exist on the web.
bool isPlatformNetworkError(Object error) => false;
