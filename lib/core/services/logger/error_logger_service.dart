import '../../utilities/console_logger.dart';

class ErrorLoggerService {
  void log({
    required Object error,
    StackTrace? stackTrace,
    String? title,
    String? message,
    String? state,
  }) {
    ce(error, title: title, message: message, state: state);
  }
}
