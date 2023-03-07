import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final List properties = const<dynamic>[];

  @override
  List<Object> get props => [properties];

  const Failure([properties]) ;
}

  class ServerFailure extends Failure{
}

  class CacheFailure extends Failure{
}
