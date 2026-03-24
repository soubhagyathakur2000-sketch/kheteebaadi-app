import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kheteebaadi/core/theme/app_theme.dart';

class WeatherData {
  final double temperature;
  final String condition;
  final String iconCode;
  final List<DailyForecast> forecast;
  final String village;
  final DateTime cachedAt;

  WeatherData({
    required this.temperature,
    required this.condition,
    required this.iconCode,
    required this.forecast,
    required this.village,
    required this.cachedAt,
  });

  bool get isExpired {
    return DateTime.now().difference(cachedAt).inMinutes > 30;
  }
}

class DailyForecast {
  final String day;
  final double high;
  final double low;
  final String condition;

  DailyForecast({
    required this.day,
    required this.high,
    required this.low,
    required this.condition,
  });
}

// Weather provider
final weatherProvider = FutureProvider<WeatherData?>((ref) async {
  try {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requestPermission = await Geolocator.requestPermission();
      if (requestPermission != LocationPermission.whileInUse &&
          requestPermission != LocationPermission.always) {
        return null;
      }
    }

    final position = await Geolocator.getCurrentPosition(
      timeLimit: const Duration(seconds: 10),
    );

    // Mock weather data - replace with actual API call
    return WeatherData(
      temperature: 28.5,
      condition: 'Partly Cloudy',
      iconCode: '02d',
      village: 'Nashik',
      forecast: [
        DailyForecast(
          day: 'Tomorrow',
          high: 32,
          low: 22,
          condition: 'Sunny',
        ),
        DailyForecast(
          day: 'Mon',
          high: 30,
          low: 20,
          condition: 'Cloudy',
        ),
        DailyForecast(
          day: 'Tue',
          high: 28,
          low: 18,
          condition: 'Rainy',
        ),
      ],
      cachedAt: DateTime.now(),
    );
  } catch (e) {
    return null;
  }
});

class WeatherWidget extends ConsumerWidget {
  const WeatherWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider);

    return weatherAsync.when(
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(),
      data: (weather) {
        if (weather == null) {
          return _buildErrorState();
        }
        return _buildWeatherCard(weather);
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const SizedBox(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off,
            color: Colors.grey[400],
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Weather data unavailable',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(WeatherData weather) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreen,
            AppTheme.primaryGreen.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Current weather
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weather.village,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${weather.temperature.toStringAsFixed(1)}°C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      weather.condition,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.wb_cloudy,
                  color: Colors.white,
                  size: 48,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 3-day forecast
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: weather.forecast.length,
                itemBuilder: (context, index) {
                  final forecast = weather.forecast[index];
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            forecast.day,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${forecast.high.toInt()}°',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${forecast.low.toInt()}°',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            forecast.condition,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
