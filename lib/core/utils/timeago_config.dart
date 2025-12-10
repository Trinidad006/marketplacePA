import 'package:timeago/timeago.dart' as timeago;

/// Configurar mensajes de timeago en español
void configureTimeago() {
  timeago.setLocaleMessages('es', timeago.EsMessages());
  timeago.setDefaultLocale('es');
}

