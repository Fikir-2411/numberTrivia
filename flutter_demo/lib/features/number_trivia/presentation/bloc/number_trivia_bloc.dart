import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_demo/core/error/failures.dart';
import 'package:flutter_demo/core/usecases/usecase.dart';
import 'package:flutter_demo/core/util/input_converter.dart';
import 'package:flutter_demo/features/number_trivia/domain/entities/number_trivia.dart';
import 'package:flutter_demo/features/number_trivia/domain/usecases/get_concrete_number_trivia.dart';
import 'package:flutter_demo/features/number_trivia/domain/usecases/get_random_number_trivia.dart';

part 'number_trivia_event.dart';
part 'number_trivia_state.dart';

const String SERVER_FAILURE_MESSAGE = 'Server Failure';
const String CACHE_FAILURE_MESSAGE = 'Cache Failure';
const String INVALID_INPUT_FAILURE_MESSAGE =
    'Invalid Input - The Number must be positive integer or 0';

class NumberTriviaBloc extends Bloc<NumberTriviaEvent, NumberTriviaState> {
  final GetConcreteNumberTrivia getConcreteNumberTrivia;
  final GetRandomNumberTrivia getRandomNumberTrivia;
  final InputConverter inputConverter;

  NumberTriviaBloc(
      {@required GetConcreteNumberTrivia concrete,
      @required GetRandomNumberTrivia random,
      @required this.inputConverter})
      : assert(concrete != null),
        assert(random != null),
        assert(inputConverter != null),
        getConcreteNumberTrivia = concrete,
        getRandomNumberTrivia = random;
  @override
  NumberTriviaState get initialState => Empty();

  @override
  Stream<NumberTriviaState> mapEventToState(
    NumberTriviaEvent event,
  ) async* {
    if (event is GetTriviaForConcreteNumber) {
      final inputEither =
          inputConverter.stringToUnsignedInteger(event.numberString);

      yield* inputEither.fold(
        (failure) async* {
          yield Error(message: INVALID_INPUT_FAILURE_MESSAGE);
          // ignore: missing_return
        },
        (integer) async* {
          yield Loading();
          final failureOrSuccess =
              await getConcreteNumberTrivia(Params(number: integer));
          yield* _eitherLoadedOrErrorState(failureOrSuccess);
        },
      );
    } else if (event is GetTriviaForRandomNumber) {
      yield Loading();
      final failureOrSuccess = await getRandomNumberTrivia(NoParams());
      yield* _eitherLoadedOrErrorState(failureOrSuccess);
    }
  }

  Stream<NumberTriviaState> _eitherLoadedOrErrorState(
      Either<Failure, NumberTrivia> failureOrSuccess) async* {
    yield failureOrSuccess.fold(
        (failure) => Error(message: _mapFailureToMessage(failure)),
        (trivia) => Loaded(trivia: trivia));
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return SERVER_FAILURE_MESSAGE;
        break;
      case CacheFailure:
        return CACHE_FAILURE_MESSAGE;
        break;
      default:
        return 'Unexpected error';
    }
  }
}
