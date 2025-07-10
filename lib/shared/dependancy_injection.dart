enum Environment { development, production, test }

class DependancyInjection {
  static Environment _environment = Environment.development;

  static Environment get environment => _environment;

  static void setEnvironment(Environment env) {
    _environment = env;
  }

  static bool get isDevelopment => _environment == Environment.development;
  static bool get isProduction => _environment == Environment.production;
  static bool get isTest => _environment == Environment.test;
}
