import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weatherapps/secrets.dart';
import 'additinal_item.dart';
import 'hourly_forecast_item.dart';
import 'package:http/http.dart' as http;

class WeatherScreen extends StatefulWidget {
  final VoidCallback toggleTheme; // Define the callback function

  const WeatherScreen({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late Future<Map<String, dynamic>> weather;

  final TextEditingController _cityNameController = TextEditingController();

  @override
  void dispose() {
    _cityNameController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> getCurrentWeatherForCity(String cityName) async {
    try {
      final res = await http.get(
        Uri.parse(
            'https://api.openweathermap.org/data/2.5/forecast?q=$cityName&APPID=$openWeatherAPIKey'),
      );

      final data = jsonDecode(res.body);

      if (data['cod'] != '200') {
        throw 'An unexpected error occurred';
      }

      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<Map<String, dynamic>> getCurrentWeather() async {
    try {
      String cityName = 'Shirpur';
      final res = await http.get(
        Uri.parse(
            'https://api.openweathermap.org/data/2.5/forecast?q=$cityName&APPID=$openWeatherAPIKey'),
      );
      final data = jsonDecode(res.body);

      if (data['cod'] != '200') {
        throw 'An unexpected error occured';
      }

      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  @override
  void initState() {
    super.initState();
    weather = getCurrentWeather();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(
          'Weather App',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.light
                  ? Icons.light_mode // Day mode icon
                  : Icons.dark_mode, // Night mode icon
            ),

            onPressed: widget
                .toggleTheme, // Call the toggleTheme function when the button is pressed
          ),
          IconButton(
            onPressed: () {
              setState(() {
                weather = getCurrentWeather();
              });
            },
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _cityNameController,
                decoration: InputDecoration(
                  hintText: 'Enter city name',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      final cityName = _cityNameController.text;
                      if (cityName.isNotEmpty) {
                        setState(() {
                          weather = getCurrentWeatherForCity(cityName);
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
            FutureBuilder(
              future: weather,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                //final data['list'][0]['main']['temp'];
                if (snapshot.hasError) {
                  return Text(snapshot.error.toString());
                }

                final data = snapshot.data!;

                final currentWeather = data['list'][0]['main']['temp'];

                final double dcelcius = currentWeather - 273.15;
                double roundedDcelcius =
                    double.parse(dcelcius.toStringAsFixed(2));

                final currentSky = data['list'][0]['weather'][0]['main'];

                final currentHumidity = data['list'][0]['main']['humidity'];
                final currentPressure = data['list'][0]['main']['pressure'];
                final currentWind = data['list'][0]['wind']['speed'];

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //main card
                      SizedBox(
                        width: double.infinity,
                        child: Card(
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Text(
                                      '$roundedDcelcius °C',
                                      style: const TextStyle(
                                        fontSize: 32,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 8,
                                    ),
                                    Text(
                                      '$currentWeather K',
                                    ),
                                    const SizedBox(
                                      height: 8,
                                    ),
                                    Icon(
                                      currentSky == 'Clouds'
                                          ? Icons.cloud
                                          : currentSky == 'Rain'
                                              ? Icons.shower
                                              : Icons.sunny,
                                      size: 64,
                                    ),
                                    const SizedBox(
                                      height: 8,
                                    ),
                                    Text(
                                      currentSky,
                                      style: const TextStyle(
                                        fontSize: 20,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      const Text(
                        'Weather Forecast',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),

                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                            itemCount: 5,
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) {
                              final hourTemp =
                                  '${(data['list'][index + 1]['main']['temp'] - 273.15).toStringAsFixed(2)}°C';
                              final hourSky =
                                  data['list'][index + 1]['weather'][0]['main'];
                              final hourTime = DateTime.parse(
                                  data['list'][index + 1]['dt_txt']);

                              return HourlyForecastItem(
                                  time: DateFormat.j().format(hourTime),
                                  icon: hourSky == 'Clouds'
                                      ? Icons.cloud
                                      : currentSky == 'Rain'
                                          ? Icons.shower
                                          : Icons.sunny,
                                  temp: hourTemp);
                            }),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      const Text(
                        'Additional Information',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          AdditionaItem(
                              icon: Icons.water_drop,
                              label: 'Humidity',
                              value: currentHumidity.toString()),
                          AdditionaItem(
                              icon: Icons.air,
                              label: 'Wind Speed',
                              value: currentWind.toString()),
                          AdditionaItem(
                              icon: Icons.beach_access,
                              label: 'Pressure',
                              value: currentPressure.toString()),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
