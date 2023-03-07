import 'package:clean_architecture/core/error/exceptions.dart';
import 'package:clean_architecture/core/error/failures.dart';
import 'package:clean_architecture/core/plataform/network_info.dart';
import 'package:clean_architecture/features/number_trivia/data/datasources/number_trivia_local_data_source.dart';
import 'package:clean_architecture/features/number_trivia/data/datasources/number_trivia_remote_data_source.dart';
import 'package:clean_architecture/features/number_trivia/data/models/number_trivia_model.dart';
import 'package:clean_architecture/features/number_trivia/data/repositories/number_trivia_repository_impl.dart';
import 'package:clean_architecture/features/number_trivia/domain/entities/number_trivia.dart';
import 'package:dartz/dartz.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_test/flutter_test.dart';

import 'number_trivia_repository_impl_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<NumberTriviaRemoteDataSource>(),
  MockSpec<NumberTriviaLocalDataSource>(),
  MockSpec<NetworkInfo>(),
  MockSpec<NumberTrivia>(),
])
void main() {
  late NumberTriviaRepositoryImpl repository;
  late MockNumberTriviaRemoteDataSource mockRemoteDataSource;
  late MockNumberTriviaLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockRemoteDataSource = MockNumberTriviaRemoteDataSource();
    mockLocalDataSource = MockNumberTriviaLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = NumberTriviaRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      netWorkInfo: mockNetworkInfo,
    );
  });

  void runTestOnline(Function body) {
    group('device is online', () {
      setUp(() {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      });
      body();
    });
  }

  void runTestOffline(Function body) {
    group('device is offline', () {
      setUp(() {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      });
      body();
    });
  }

  group('getConcreteNumberTrivia', () {
    const tNumber = 1;
    test('should check if the device is online', () async {
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

      await repository.getConcreteNumberTrivia(tNumber);

      verify(mockNetworkInfo.isConnected);
    });
  });

  runTestOnline(() {
    test(
        'should return remote data when the call  to remote data source is sucessful',
        () async {
      const tNumber = 1;
      const tNumberTriviaModel =
          NumberTriviaModel(text: 'test trivia', number: tNumber);
      const NumberTrivia tNumberTrivia = tNumberTriviaModel;
      when(mockRemoteDataSource.getConcreteNumberTrivia(any))
          .thenAnswer((_) async => tNumberTriviaModel);
      final result = await repository.getConcreteNumberTrivia(tNumber);
      verify(mockRemoteDataSource.getConcreteNumberTrivia(tNumber));
      expect(result, const Right(tNumberTrivia));
    });
    test(
      'should cache the data locally when the call  to remote data source is sucessful',
      () async {
        const tNumber = 2;
        const tNumberTriviaModel =
            NumberTriviaModel(text: 'test trivia', number: tNumber);
        const NumberTrivia tNumberTriviaEntity = tNumberTriviaModel;
        when(mockRemoteDataSource.getConcreteNumberTrivia(any)).thenAnswer((_) async => tNumberTriviaModel);
        var result = await repository.getConcreteNumberTrivia(tNumber);

        verifyNever(mockRemoteDataSource.getConcreteNumberTrivia(tNumber));
        verifyNever(mockLocalDataSource.cacheNumberTrivia(tNumberTriviaModel));

        expect(result, const Right(tNumberTriviaEntity));
      },
    );
    test(
        'should return server failure when the call  to remote data source is unsucessful',
        () async {
      const tNumber = 1;
      when(mockRemoteDataSource.getConcreteNumberTrivia(any))
          .thenThrow(ServerException());
      final result = await repository.getConcreteNumberTrivia(tNumber);
      verify(mockRemoteDataSource.getConcreteNumberTrivia(tNumber));
      verifyZeroInteractions(mockLocalDataSource);
      expect(result, Left(ServerFailure()));
    });
  });

  runTestOffline(() {
    test(
        'should return last locally cached data when the cached data is present',
        () async {
      const tNumber = 1;
      const tNumberTriviaModel =
          NumberTriviaModel(text: 'test trivia', number: tNumber);
      const NumberTrivia tNumberTrivia = tNumberTriviaModel;
      when(mockLocalDataSource.getLastNumberTrivia())
          .thenAnswer((_) async => tNumberTriviaModel);
      final result = await repository.getConcreteNumberTrivia(tNumber);
      verifyZeroInteractions(mockRemoteDataSource);
      verify(mockLocalDataSource.getLastNumberTrivia());
      expect(result, const Right(tNumberTrivia));
    });

    test('should return CacheFailure when is no cached data present', () async {
      const tNumber = 1;
      when(mockLocalDataSource.getLastNumberTrivia())
          .thenThrow(CacheException());
      final result = await repository.getConcreteNumberTrivia(tNumber);
      verifyZeroInteractions(mockRemoteDataSource);
      verify(mockLocalDataSource.getLastNumberTrivia());
      expect(result, Left(CacheFailure()));
    });
  });

  group('getRandomNumberTrivia', () {
    test('should check if the device is online', () async {
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

      await repository.getRandomNumberTrivia();

      verify(mockNetworkInfo.isConnected);
    });
  });

  runTestOnline(() {
    test(
        'should return remote data when the call  to remote data source is sucessful',
        () async {
      const tNumberTriviaModel =
          NumberTriviaModel(text: 'test trivia', number: 123);
      const NumberTrivia tNumberTrivia = tNumberTriviaModel;
      when(mockRemoteDataSource.getRandomNumberTrivia())
          .thenAnswer((_) async => tNumberTriviaModel);
      final result = await repository.getRandomNumberTrivia();
      verify(mockRemoteDataSource.getRandomNumberTrivia());
      expect(result, const Right(tNumberTrivia));
    });
    test(
        'should cache the data locally when the call  to remote data source is sucessful',
        () async {
      const tNumberTriviaModel =
          NumberTriviaModel(text: 'test trivia', number: 123);
      when(mockRemoteDataSource.getRandomNumberTrivia())
          .thenAnswer((_) async => tNumberTriviaModel);
      await repository.getRandomNumberTrivia();
      verify(mockRemoteDataSource.getRandomNumberTrivia());
      verify(mockLocalDataSource.cacheNumberTrivia(tNumberTriviaModel));
    });
    test(
        'should return server failure when the call  to remote data source is unsucessful',
        () async {
      when(mockRemoteDataSource.getRandomNumberTrivia())
          .thenThrow(ServerException());
      final result = await repository.getRandomNumberTrivia();
      verify(mockRemoteDataSource.getRandomNumberTrivia());
      verifyZeroInteractions(mockLocalDataSource);
      expect(result, Left(ServerFailure()));
    });
  });

  runTestOffline(() {
    test(
        'should return last locally cached data when the cached data is present',
        () async {
      const tNumberTriviaModel =
          NumberTriviaModel(text: 'test trivia', number: 123);
      const NumberTrivia tNumberTrivia = tNumberTriviaModel;
      when(mockLocalDataSource.getLastNumberTrivia())
          .thenAnswer((_) async => tNumberTriviaModel);
      final result = await repository.getRandomNumberTrivia();
      verifyZeroInteractions(mockRemoteDataSource);
      verify(mockLocalDataSource.getLastNumberTrivia());
      expect(result, const Right(tNumberTrivia));
    });

    test('should return CacheFailure when is no cached data present', () async {
      when(mockLocalDataSource.getLastNumberTrivia())
          .thenThrow(CacheException());
      final result = await repository.getRandomNumberTrivia();
      verifyZeroInteractions(mockRemoteDataSource);
      verify(mockLocalDataSource.getLastNumberTrivia());
      expect(result, Left(CacheFailure()));
    });
  });
}
