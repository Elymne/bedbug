import 'package:flutter/services.dart';

/// Canal des appels vers le service d'échange Android.
const MethodChannel exchangeMethodChannel = MethodChannel('bedbug/exchange');

/// Canal des événements du service d'échange Android.
const EventChannel exchangeEventChannel = EventChannel('bedbug/exchange/events');

/// Canal de la demande de permissions, tenu par l'activité Android.
const MethodChannel exchangePermissionsChannel = MethodChannel('bedbug/exchange/permissions');
