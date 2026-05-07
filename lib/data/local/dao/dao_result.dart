class DaoResult<T> {
  final T? data;
  final String? error;
  final Object? exception;

  const DaoResult._({this.data, this.error, this.exception});

  bool get isSuccess => error == null;
  bool get isFailure => !isSuccess;

  static DaoResult<T> success<T>(T data) {
    return DaoResult<T>._(data: data);
  }

  static DaoResult<T> failure<T>(String error, {Object? exception}) {
    return DaoResult<T>._(error: error, exception: exception);
  }
}
