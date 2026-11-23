import 'dart:io';

/// Native platforms surface connectivity problems as [SocketException].
bool isPlatformNetworkError(Object error) => error is SocketException;
