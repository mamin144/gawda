import 'package:fpdart/fpdart.dart';

import 'app_failure.dart';

/// Every repository operation returns a [Result]; exceptions never escape.
typedef Result<T> = Either<AppFailure, T>;
